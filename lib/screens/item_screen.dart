import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/format.dart';
import '../core/i18n.dart';
import '../core/links.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../state/cart.dart';
import '../state/cart_logic.dart';
import '../state/favorites.dart';
import '../widgets/common.dart';

class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key, required this.itemId, this.initialQty = 1});
  final String itemId;

  /// Quantity carried over from a dish card's stepper.
  final int initialQty;
  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  Selection _sel = {};
  late int _qty = widget.initialQty.clamp(1, 50);
  bool _touched = false;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final item = app.menu?.item(widget.itemId);
    if (item == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final missing = missingGroups(item, _sel);
    final total = unitPrice(item, _sel) * _qty;
    final canOrder = app.branch != null && item.orderable && !item.soldOut;

    return Scaffold(
      backgroundColor: Brand.cream,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          stretch: true,
          backgroundColor: Brand.cream,
          automaticallyImplyLeading: false,
          leadingWidth: 64,
          leading: Padding(padding: const EdgeInsets.only(left: 14), child: Center(child: _CircleButton(icon: Icons.arrow_back_rounded, tooltip: MaterialLocalizations.of(context).backButtonTooltip, onTap: () => context.pop()))),
          actions: [
            _CircleButton(
              icon: context.watch<FavoritesStore>().contains(item.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: context.watch<FavoritesStore>().contains(item.id) ? Brand.tomato : Brand.charcoal,
              tooltip: s.t(context.watch<FavoritesStore>().contains(item.id) ? 'removeFavourite' : 'addFavourite'),
              onTap: () => context.read<FavoritesStore>().toggle(item.id),
            ),
            const SizedBox(width: 10),
            // Shares the public web page (Open Graph preview, works without the app; opens in the app via App Links).
            _CircleButton(
              icon: Icons.ios_share,
              tooltip: s.t('share'),
              onTap: () => SharePlus.instance.share(ShareParams(text: '${s.t('shareDish').replaceAll('{name}', item.name)}\n${WebLinks.dish(app.lang, item.slug)}')),
            ),
            const SizedBox(width: 14),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: DishImage(url: item.hasPhoto ? item.imageUrl : null, radius: 0),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Container(height: 24, decoration: const BoxDecoration(color: Brand.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          sliver: SliverList.list(children: [
            Text(item.name, style: Brand.h1.copyWith(fontSize: 32)),
            const SizedBox(height: 8),
            Text(itemPriceLabel(s, item, app.lang), style: Brand.price.copyWith(fontSize: 26)),
            if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(item.description, style: const TextStyle(color: Brand.muted, fontSize: 16, height: 1.45))),
            if (item.glutenFreeOption)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(spacing: 8, runSpacing: 8, children: [InfoChip(icon: Icons.grass_rounded, text: s.t('glutenFreeOption'))]),
              ),
            const SizedBox(height: 6),
            if (!item.allergensVerified) _Note(text: s.t('allergensPending')),
            if (item.orderableNote != null) _Note(text: item.orderableNote!),
            if (item.soldOut) _Note(text: s.t('soldOut'), danger: true),
            if (app.branch == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(onPressed: () => context.push('/select'), icon: const Icon(Icons.location_on_rounded), label: Text(s.t('chooseRestaurant'))),
              ),
            for (final g in item.optionGroups) _Group(group: g, sel: _sel, error: _touched && missing.contains(g), onChanged: (sel) => setState(() => _sel = normaliseSelection(item, sel))),
            const SizedBox(height: 26),
            Text(s.t('instructions'), style: Brand.h2),
            const SizedBox(height: 10),
            TextField(controller: _notes, maxLength: 200, maxLines: 2, decoration: InputDecoration(hintText: s.t('instructionsHint'))),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
      bottomNavigationBar: BottomActionBar(
        child: Row(children: [
          if (canOrder) ...[
            QtyStepper(value: _qty, compact: false, onChanged: (v) => setState(() => _qty = v)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: app.branch == null
                  ? () => context.push('/select')
                  : !canOrder
                      ? null
                      : () {
                          setState(() => _touched = true);
                          if (missing.isNotEmpty) return showSnack(context, '${missing.first.name}: ${s.t('required')}', error: true);
                          context.read<CartStore>().add(app.branchSlug!, item, _sel, _qty, _notes.text);
                          showSnack(context, '${item.name} · ${s.t('added')}');
                          context.pop();
                        },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (app.branch != null) ...[const Icon(Icons.shopping_cart_outlined, size: 22), const SizedBox(width: 10)],
                  Text(app.branch == null ? s.t('chooseRestaurant') : '${s.t('addToCart')} · ${eur(total, app.lang)}'),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.tooltip, required this.onTap, this.color = Brand.charcoal});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black26,
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 46, height: 46, child: Icon(icon, size: 22, color: color))),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.danger = false});
  final String text;
  final bool danger;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: danger ? Brand.tomatoSoft : Brand.warningSoft, borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(danger ? Icons.block : Icons.error_outline_rounded, size: 20, color: danger ? Brand.tomatoDark : Brand.warning),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: danger ? Brand.tomatoDark : Brand.warning, fontSize: 14, height: 1.4))),
        ]),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.group, required this.sel, required this.error, required this.onChanged});
  final OptionGroup group;
  final Selection sel;
  final bool error;
  final ValueChanged<Selection> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = context.select<AppState, String>((a) => a.lang);
    final max = effectiveMax(group, sel);
    final chosen = sel[group.key] ?? const <String>[];
    final single = group.max == 1 && group.maxByChoice == null;
    final req = group.required || group.min > 0;
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(group.name, style: Brand.h2)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: req ? (error ? Brand.tomato : Brand.tomatoSoft) : Brand.cream2, borderRadius: BorderRadius.circular(999)),
            child: Text(
              req ? '${s.t('required')} · ${s.t('chooseN').replaceAll('{n}', '${group.min > 0 ? group.min : 1}')}' : '${s.t('upToN').replaceAll('{n}', '$max')} · ${s.t('optional')}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: req ? (error ? Colors.white : Brand.tomatoDark) : Brand.muted),
            ),
          ),
        ]),
        if (group.warning != null && chosen.contains('base-sin-gluten')) Padding(padding: const EdgeInsets.only(top: 6), child: _Note(text: group.warning!)),
        const SizedBox(height: 10),
        for (final c in group.choices)
          Builder(builder: (context) {
            final checked = chosen.contains(c.key);
            final disabled = !c.available || (!checked && !single && chosen.length >= max);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: checked ? const Color(0xFFFFF8F7) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: checked ? Brand.tomato : Brand.border, width: checked ? 1.6 : 1)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: disabled ? null : () => onChanged(toggleChoice(group, sel, c.key)),
                child: Opacity(
                  opacity: disabled ? 0.5 : 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
                    child: Row(children: [
                      Icon(
                        single ? (checked ? Icons.radio_button_checked : Icons.radio_button_off) : (checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded),
                        color: checked ? Brand.tomato : Brand.muted,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: Brand.cream2, shape: BoxShape.circle),
                        clipBehavior: Clip.antiAlias,
                        child: c.image != null
                            ? CachedNetworkImage(imageUrl: c.image!, fit: BoxFit.cover, errorWidget: (_, _, _) => const Icon(Icons.restaurant_rounded, size: 18, color: Brand.tomato))
                            : const Icon(Icons.restaurant_rounded, size: 18, color: Brand.tomato),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.name + (c.needsConfirmation ? ' (${s.t('pending')})' : '') + (!c.available ? ' — ${s.t('soldOut')}' : ''),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(delta(c.priceDeltaCents, lang), style: TextStyle(fontWeight: FontWeight.w700, color: checked ? Brand.tomato : Brand.charcoal)),
                    ]),
                  ),
                ),
              ),
            );
          }),
      ]),
    );
  }
}
