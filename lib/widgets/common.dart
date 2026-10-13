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
import '../state/favorites.dart';

/// The restaurant's logo (same file as the website header, admin → identity → logo).
class ItalianHeaderBackdrop extends StatelessWidget {
  const ItalianHeaderBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ExcludeSemantics(
          child: Image.asset(
            'assets/images/italian-header.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
      ),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Brand.cream,
                Brand.cream.withValues(alpha: 0.88),
                Brand.cream.withValues(alpha: 0.08),
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Brand.cream.withValues(alpha: 0), Brand.cream],
              stops: const [0.72, 1],
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 44});
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'La Toscana Pizzeria',
    image: true,
    child: Image.asset(
      'assets/images/logo.webp',
      height: height,
      filterQuality: FilterQuality.medium,
    ),
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
      child: const Row(
        children: [
          Expanded(child: ColoredBox(color: Brand.basil)),
          Expanded(child: ColoredBox(color: Colors.white)),
          Expanded(child: ColoredBox(color: Brand.tomato)),
        ],
      ),
    ),
  );
}

/// Network image with a neutral placeholder. Dishes without a real photo show an icon and an "illustrative" label —
/// never a stock photo presented as the dish.
class DishImage extends StatelessWidget {
  const DishImage({
    super.key,
    required this.url,
    this.height,
    this.radius = 14,
    this.fit = BoxFit.cover,
    this.showLabel = true,
  });
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFBF3E8), Color(0xFFF4E6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 34,
            color: Brand.tomato.withValues(alpha: 0.55),
          ),
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                S.of(context).t('illustrative'),
                style: const TextStyle(fontSize: 11, color: Brand.muted),
              ),
            ),
        ],
      ),
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
              placeholder: (_, _) =>
                  Container(height: height, color: const Color(0xFFF3EEE7)),
              errorWidget: (_, _, _) => ph,
            ),
    );
  }
}

/// Loading / error-with-retry wrapper for screens that depend on [AppState] data.
class LoadingOrError extends StatelessWidget {
  const LoadingOrError({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.child,
  });
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
    final msg = error is ApiException
        ? s.error((error as ApiException).code)
        : s.t('offline');
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: msg,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(s.t('retry')),
      ),
    );
  }
}

/// Centered icon + message + optional action, for empty lists and errors.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Brand.tomatoSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Brand.tomato),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Brand.h3.copyWith(fontSize: 20),
            ),
            if (body != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Brand.muted),
                ),
              ),
            if (action != null)
              Padding(padding: const EdgeInsets.only(top: 18), child: action!),
          ],
        ),
      ),
    ),
  );
}

/// Display-font section title with an optional "see all" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 28, 12, 14),
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        Expanded(child: Text(title, style: Brand.h2)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action!),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Small rounded status label ("Abierto", "Agotado"…).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    this.color = Brand.basilDark,
    this.background = Brand.basilSoft,
    this.icon,
  });
  final String text;
  final Color color;
  final Color background;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Ordering state of a restaurant as a coloured pill.
class BranchStatusPill extends StatelessWidget {
  const BranchStatusPill({
    super.key,
    required this.branch,
    required this.label,
  });
  final Branch branch;
  final String label;
  @override
  Widget build(BuildContext context) => branch.canOrderOnline
      ? Pill(
          text: label,
          icon: Icons.circle,
          color: Brand.basilDark,
          background: Brand.basilSoft,
        )
      : Pill(
          text: label,
          icon: Icons.schedule_rounded,
          color: Brand.warning,
          background: Brand.warningSoft,
        );
}

/// White rounded container with the website's soft card shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 18,
    this.borderColor,
  });
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
      border: Border.all(
        color: borderColor ?? Brand.border,
        width: borderColor == null ? 1 : 1.6,
      ),
      boxShadow: Brand.shadow,
    ),
    child: Material(
      type: MaterialType.transparency,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dark ? Colors.white24 : Brand.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/select'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: dark ? Colors.white : Brand.tomatoSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  app.mode == 'delivery'
                      ? Icons.delivery_dining_rounded
                      : Icons.storefront_rounded,
                  size: 20,
                  color: Brand.tomato,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      b == null
                          ? s.t('orderFrom')
                          : s.t(
                              app.mode == 'delivery'
                                  ? 'deliveryFrom'
                                  : 'pickupAt',
                            ),
                      style: TextStyle(
                        fontSize: 12,
                        color: dark ? Colors.white70 : Brand.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      b?.name ?? s.t('chooseRestaurant'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                s.t('change'),
                style: TextStyle(
                  color: dark ? Colors.white : Brand.tomato,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: dark ? Colors.white : Brand.tomato,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adds an item straight to the cart, or opens it when it needs options / a restaurant first.
void quickAdd(BuildContext context, MenuItem item, {int qty = 1}) {
  final s = S.of(context);
  final app = context.read<AppState>();
  if (app.branch == null) {
    context.push('/select');
  } else if (item.optionGroups.isNotEmpty) {
    context.push('/item/${item.id}${qty > 1 ? '?qty=$qty' : ''}');
  } else {
    context.read<CartStore>().add(app.branchSlug!, item, const {}, qty, null);
    showSnack(
      context,
      '${qty > 1 ? '$qty × ' : ''}${item.name} · ${s.t('added')}',
    );
  }
}

/// Price shown on cards: "desde 9,50 €" for dishes with required options.
String itemPriceLabel(S s, MenuItem item, String lang) =>
    item.hasRequiredOptions
    ? '${s.t('from')} ${eur(fromPrice(item), lang)}'
    : eur(item.priceCents, lang);

/// Heart toggle for a dish. [onPhoto] draws it on a dark disc so it reads on top of a photo.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.itemId,
    this.onPhoto = false,
    this.size = 40,
  });
  final String itemId;
  final bool onPhoto;
  final double size;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final favorites = context.watch<FavoritesStore>();
    final on = favorites.contains(itemId);
    return IconButton(
      tooltip: s.t(on ? 'removeFavourite' : 'addFavourite'),
      onPressed: () => favorites.toggle(itemId),
      style: IconButton.styleFrom(
        minimumSize: Size(size, size),
        fixedSize: Size(size, size),
        padding: EdgeInsets.zero,
        backgroundColor: onPhoto ? Colors.black.withValues(alpha: 0.28) : null,
      ),
      icon: Icon(
        on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: size * 0.55,
        color: on ? Brand.tomato : (onPhoto ? Colors.white : Brand.charcoal),
      ),
    );
  }
}

/// "− 1 +" quantity pill. [compact] is the small white version used on dish cards.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.compact = true,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final h = compact ? 40.0 : 56.0;
    final w = compact ? 27.0 : 48.0;
    Widget btn(IconData icon, String tip, int next, bool allowed) => SizedBox(
      width: w,
      height: h,
      child: IconButton(
        tooltip: tip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(minimumSize: Size(w, h)),
        onPressed: enabled && allowed ? () => onChanged(next) : null,
        icon: Icon(icon, size: compact ? 18 : 22, color: Brand.charcoal),
      ),
    );
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: compact ? Colors.white : Brand.cream2,
        borderRadius: BorderRadius.circular(compact ? 999 : 16),
        border: compact ? Border.all(color: Brand.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded, s.t('decrease'), value - 1, value > 1),
          SizedBox(
            width: compact ? 16 : 30,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 14 : 18,
              ),
            ),
          ),
          btn(Icons.add_rounded, s.t('increase'), value + 1, value < 50),
        ],
      ),
    );
  }
}

/// Small rounded attribute chip ("Gluten-free option").
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Pill(
    text: text,
    icon: icon,
    color: Brand.warning,
    background: Brand.warningSoft,
  );
}

/// Grid dish card for the home screen: photo with heart, name, description, price, quantity + Add.
class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.item});
  final MenuItem item;
  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final item = widget.item;
    final lang = context.select<AppState, String>((a) => a.lang);
    final unavailable = item.soldOut || !item.orderable;
    final scaler = MediaQuery.textScalerOf(context);
    return SoftCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/item/${item.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.6,
                child: DishImage(
                  url: item.hasPhoto ? item.imageUrl : null,
                  radius: 0,
                  showLabel: false,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: FavoriteButton(itemId: item.id, onPhoto: true),
              ),
              if (unavailable)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Pill(
                    text: item.soldOut ? s.t('soldOut') : s.t('inStoreOnly'),
                    color: Colors.white,
                    background: Brand.charcoal.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                // Two lines reserved so cards in a row line up.
                SizedBox(
                  height: scaler.scale(12) * 1.35 * 2,
                  child: Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Brand.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  itemPriceLabel(s, item, lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.price.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, c) {
                    final label = TextPainter(
                      text: TextSpan(
                        text: s.t('add'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: Brand.body,
                        ),
                      ),
                      textScaler: scaler,
                      textDirection: TextDirection.ltr,
                    )..layout();
                    // Stepper 74 + gap 6, then the button: padding 20 + icon 16 + gap 4 + label.
                    final room = c.maxWidth - 80 - 20;
                    final showIcon = room >= 20 + label.width;
                    final showLabel = room >= label.width;
                    label.dispose();
                    return Row(
                      children: [
                        QtyStepper(
                          value: _qty,
                          enabled: !unavailable,
                          onChanged: (v) => setState(() => _qty = v),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AddButton(
                            label: showLabel ? Text(s.t('add')) : null,
                            icon: showIcon || !showLabel,
                            height: 40,
                            pill: true,
                            onPressed: unavailable
                                ? null
                                : () => quickAdd(context, item, qty: _qty),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Red add-to-cart button: a round "+" by default, or a pill with a cart icon and [label]
/// (plus a trailing "+" segment when [plus] is set, as on the menu list).
class AddButton extends StatelessWidget {
  const AddButton({
    super.key,
    required this.onPressed,
    this.size = 48,
    this.label,
    this.plus = false,
    this.height = 44,
    this.icon = true,
    this.pill = false,
  });
  final VoidCallback? onPressed;
  final double size;
  final Widget? label;
  final bool plus;
  final double height;

  /// Cart icon before the label.
  final bool icon;

  /// Pill shape even without a label (cart icon only), instead of the round "+".
  final bool pill;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = enabled ? Brand.tomato : const Color(0xFFE9E1D7);
    final fg = enabled ? Colors.white : Brand.hint;
    if (label == null && !pill) {
      return Semantics(
        button: true,
        label: S.of(context).t('add'),
        child: Material(
          color: bg,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(Icons.add_rounded, color: fg, size: 24),
            ),
          ),
        ),
      );
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height, minWidth: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: label == null ? 6 : 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon)
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 18,
                    color: fg,
                    semanticLabel: label == null
                        ? S.of(context).t('add')
                        : null,
                  ),
                if (icon && label != null) const SizedBox(width: 5),
                if (label != null)
                  Flexible(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: Brand.body,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: label!,
                    ),
                  ),
                if (plus) ...[
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: fg.withValues(alpha: 0.4),
                  ),
                  Icon(Icons.add_rounded, size: 20, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      boxShadow: [
        BoxShadow(
          color: Color(0x12663B10),
          blurRadius: 20,
          offset: Offset(0, -6),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: child,
      ),
    ),
  );
}

void showSnack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor: error ? Brand.tomatoDark : Brand.charcoal,
        duration: const Duration(seconds: 2),
      ),
    );
}

String apiErrorText(BuildContext context, Object e) =>
    e is ApiException ? S.of(context).error(e.code) : S.of(context).t('error');
