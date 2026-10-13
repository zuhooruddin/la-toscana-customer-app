import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../state/cart.dart';
import '../state/cart_logic.dart';

/// The restaurant's logo (same file as the website header, admin → identity → logo).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 44});
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'La Toscana Pizzeria',
        image: true,
        child: Image.asset('assets/images/logo.webp', height: height, filterQuality: FilterQuality.medium),
      );
}

/// Green-white-red stripe from the website's brand mark.
class ItalianFlag extends StatelessWidget {
  const ItalianFlag({super.key, this.width = 24});
  final double width;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: width,
          height: 4,
          child: const Row(children: [
            Expanded(child: ColoredBox(color: Brand.basil)),
            Expanded(child: ColoredBox(color: Colors.white)),
            Expanded(child: ColoredBox(color: Brand.tomato)),
          ]),
        ),
      );
}

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
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFBF3E8), Color(0xFFF4E6D4)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_pizza_outlined, size: 34, color: Brand.tomato.withValues(alpha: 0.55)),
        if (showLabel) Padding(padding: const EdgeInsets.only(top: 4), child: Text(S.of(context).t('illustrative'), style: const TextStyle(fontSize: 11, color: Brand.muted))),
      ]),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? ph
          : CachedNetworkImage(
              imageUrl: url!,
              height: height,
              width: double.infinity,
              fit: fit,
              fadeInDuration: const Duration(milliseconds: 220),
              placeholder: (_, _) => Container(height: height, color: const Color(0xFFF3EEE7)),
              errorWidget: (_, _, _) => ph,
            ),
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
    return EmptyState(icon: Icons.wifi_off_rounded, title: msg, action: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(s.t('retry'))));
  }
}

/// Centered icon + message + optional action, for empty lists and errors.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action});
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: Brand.tomatoSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: Brand.tomato),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: Brand.h3.copyWith(fontSize: 20)),
            if (body != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(body!, textAlign: TextAlign.center, style: const TextStyle(color: Brand.muted))),
            if (action != null) Padding(padding: const EdgeInsets.only(top: 18), child: action!),
          ]),
        ),
      );
}

/// Display-font section title with an optional "see all" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction, this.padding = const EdgeInsets.fromLTRB(16, 24, 8, 10)});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(children: [
          Expanded(child: Text(title, style: Brand.h2)),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Row(mainAxisSize: MainAxisSize.min, children: [Text(action!), const SizedBox(width: 2), const Icon(Icons.arrow_forward, size: 16)]),
            ),
        ]),
      );
}

/// Small rounded status label ("Abierto", "Agotado"…).
class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, this.color = Brand.basilDark, this.background = Brand.basilSoft, this.icon});
  final String text;
  final Color color;
  final Color background;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      );
}

/// Ordering state of a restaurant as a coloured pill.
class BranchStatusPill extends StatelessWidget {
  const BranchStatusPill({super.key, required this.branch, required this.label});
  final Branch branch;
  final String label;
  @override
  Widget build(BuildContext context) => branch.canOrderOnline
      ? Pill(text: label, icon: Icons.circle, color: Brand.basilDark, background: Brand.basilSoft)
      : Pill(text: label, icon: Icons.schedule, color: Brand.warning, background: Brand.warningSoft);
}

/// White rounded container with the website's soft card shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.radius = 18, this.borderColor});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? borderColor;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor ?? Brand.border, width: borderColor == null ? 1 : 1.6),
          boxShadow: Brand.shadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

/// Where the order goes: restaurant + pickup/delivery. Tapping opens the restaurant selector.
class BranchChip extends StatelessWidget {
  const BranchChip({super.key, this.dark = false});

  /// Light text for use on top of a photo / gradient.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final b = app.branch;
    final fg = dark ? Colors.white : Brand.charcoal;
    return Material(
      color: dark ? Colors.white.withValues(alpha: 0.14) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: dark ? Colors.white24 : Brand.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/select'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: dark ? Colors.white : Brand.tomatoSoft, borderRadius: BorderRadius.circular(10)),
              child: Icon(app.mode == 'delivery' ? Icons.delivery_dining_outlined : Icons.storefront_outlined, size: 20, color: Brand.tomato),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(
                  b == null ? s.t('orderFrom') : s.t(app.mode == 'delivery' ? 'deliveryFrom' : 'pickupAt'),
                  style: TextStyle(fontSize: 12, color: dark ? Colors.white70 : Brand.muted, fontWeight: FontWeight.w600),
                ),
                Text(b?.name ?? s.t('chooseRestaurant'), overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: fg)),
              ]),
            ),
            Text(s.t('change'), style: TextStyle(color: dark ? Colors.white : Brand.tomato, fontWeight: FontWeight.w700, fontSize: 13)),
            Icon(Icons.expand_more, size: 18, color: dark ? Colors.white : Brand.tomato),
          ]),
        ),
      ),
    );
  }
}

/// Adds an item straight to the cart, or opens it when it needs options / a restaurant first.
void quickAdd(BuildContext context, MenuItem item) {
  final s = S.of(context);
  final app = context.read<AppState>();
  if (app.branch == null) {
    context.push('/select');
  } else if (item.optionGroups.isNotEmpty) {
    context.push('/item/${item.id}');
  } else {
    context.read<CartStore>().add(app.branchSlug!, item, const {}, 1, null);
    showSnack(context, '${item.name} · ${s.t('added')}');
  }
}

/// Price shown on cards: "desde 9,50 €" for dishes with required options.
String itemPriceLabel(S s, MenuItem item, String lang) => item.hasRequiredOptions ? '${s.t('from')} ${eur(fromPrice(item), lang)}' : eur(item.priceCents, lang);

/// Vertical product card (photo on top) used in horizontal shelves.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.item, this.width = 172});
  final MenuItem item;
  final double width;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = context.select<AppState, String>((a) => a.lang);
    final unavailable = item.soldOut || !item.orderable;
    return SizedBox(
      width: width,
      child: SoftCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/item/${item.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: DishImage(url: item.hasPhoto ? item.imageUrl : null, radius: 0, showLabel: false),
            ),
            if (item.soldOut) Positioned(top: 8, left: 8, child: Pill(text: s.t('soldOut'), color: Colors.white, background: Brand.charcoal.withValues(alpha: 0.8))),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                height: 38,
                child: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.25)),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text(itemPriceLabel(s, item, lang), style: Brand.price, overflow: TextOverflow.ellipsis)),
                if (!unavailable) AddButton(onPressed: () => quickAdd(context, item)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Round red "+" button.
class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.onPressed, this.size = 34});
  final VoidCallback onPressed;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: S.of(context).t('add'),
        child: Material(
          color: Brand.tomato,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(width: size, height: size, child: Icon(Icons.add, color: Colors.white, size: size * 0.6)),
          ),
        ),
      );
}

/// Sticky bottom bar holding the main call to action of a screen.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Brand.border)),
          boxShadow: [BoxShadow(color: Color(0x12663B10), blurRadius: 20, offset: Offset(0, -6))],
        ),
        child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child)),
      );
}

void showSnack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ]),
      backgroundColor: error ? Brand.tomatoDark : Brand.charcoal,
      duration: const Duration(seconds: 2),
    ));
}

String apiErrorText(BuildContext context, Object e) => e is ApiException ? S.of(context).error(e.code) : S.of(context).t('error');
