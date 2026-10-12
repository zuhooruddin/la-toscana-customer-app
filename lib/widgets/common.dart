import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../state/app_state.dart';

/// Network image with a neutral placeholder. Dishes without a real photo show an icon and an "illustrative" label —
/// never a stock photo presented as the dish.
class DishImage extends StatelessWidget {
  const DishImage({super.key, required this.url, this.height, this.radius = 14, this.fit = BoxFit.cover, this.showLabel = true});
  final String? url;
  final double? height;
  final double radius;
  final BoxFit fit;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      height: height,
      color: const Color(0xFFF6EDE0),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_pizza_outlined, size: 36, color: Brand.tomato),
        if (showLabel) Padding(padding: const EdgeInsets.only(top: 4), child: Text(S.of(context).t('illustrative'), style: const TextStyle(fontSize: 11, color: Brand.muted))),
      ]),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? ph
          : CachedNetworkImage(imageUrl: url!, height: height, width: double.infinity, fit: fit, placeholder: (_, _) => Container(height: height, color: const Color(0xFFF3EEE7)), errorWidget: (_, _, _) => ph),
    );
  }
}

/// Loading / error-with-retry wrapper for screens that depend on [AppState] data.
class LoadingOrError extends StatelessWidget {
  const LoadingOrError({super.key, required this.loading, required this.error, required this.onRetry, required this.child});
  final bool loading;
  final Object? error;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return ErrorRetry(error: error!, onRetry: onRetry);
    return child;
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final msg = error is ApiException ? s.error((error as ApiException).code) : s.t('offline');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: Brand.muted),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(s.t('retry'))),
        ]),
      ),
    );
  }
}

/// "Pickup at La Toscana Barbastro ▾" — opens the restaurant selector.
class BranchChip extends StatelessWidget {
  const BranchChip({super.key});
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final b = app.branch;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => context.push('/select'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: Brand.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.place_outlined, size: 18, color: Brand.tomato),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              b == null ? s.t('chooseRestaurant') : '${s.t(app.mode == 'delivery' ? 'deliveryFrom' : 'pickupAt')} ${b.name}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.expand_more, size: 18),
        ]),
      ),
    );
  }
}

void showSnack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Brand.tomatoDark : null, behavior: SnackBarBehavior.floating));
}

String apiErrorText(BuildContext context, Object e) => e is ApiException ? S.of(context).error(e.code) : S.of(context).t('error');
