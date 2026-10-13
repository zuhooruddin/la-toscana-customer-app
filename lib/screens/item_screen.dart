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
import '../widgets/common.dart';

class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key, required this.itemId});
  final String itemId;
  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  Selection _sel = {};
  int _qty = 1;
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
      backgroundColor: Colors.white,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          stretch: true,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: Padding(padding: const EdgeInsets.all(6), child: _CircleButton(icon: Icons.arrow_back, tooltip: MaterialLocalizations.of(context).backButtonTooltip, onTap: () => context.pop())),
          actions: [
            // Shares the public web page (Open Graph preview, works without the app; opens in the app via App Links).
            Padding(
              padding: const EdgeInsets.all(6),
              child: _CircleButton(
                icon: Icons.ios_share,
                tooltip: s.t('share'),
                onTap: () => SharePlus.instance.share(ShareParams(text: '${s.t('shareDish').replaceAll('{name}', item.name)}\n${WebLinks.dish(app.lang, item.slug)}')),
              ),
            ),
            const SizedBox(width: 6),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: DishImage(url: item.hasPhoto ? item.imageUrl : null, radius: 0),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Container(height: 20, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          sliver: SliverList.list(children: [
            Text(item.name, style: Brand.h1),
            const SizedBox(height: 6),
            Text(itemPriceLabel(s, item, app.lang), style: Brand.price.copyWith(fontSize: 20)),
            if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(item.description, style: const TextStyle(color: Brand.muted, fontSize: 15, height: 1.5))),
            const SizedBox(height: 6),
            if (!item.allergensVerified) _Note(text: s.t('allergensPending')),
            if (item.orderableNote != null) _Note(text: item.orderableNote!),
            if (item.soldOut) _Note(text: s.t('soldOut'), danger: true),
            if (app.branch == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(onPressed: () => context.push('/select'), icon: const Icon(Icons.place_outlined), label: Text(s.t('chooseRestaurant'))),
              ),
            for (final g in item.optionGroups) _Group(group: g, sel: _sel, error: _touched && missing.contains(g), onChanged: (sel) => setState(() => _sel = normaliseSelection(item, sel))),
            const SizedBox(height: 24),
            Text(s.t('instructions'), style: Brand.h3),
            const SizedBox(height: 10),
            TextField(controller: _notes, maxLength: 200, maxLines: 2, decoration: InputDecoration(hintText: s.t('instructionsHint'), fillColor: Brand.surfaceWarm)),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
      bottomNavigationBar: BottomActionBar(
        child: Row(children: [
          if (canOrder) ...[
            _Stepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
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
                child: Text(app.branch == null ? s.t('chooseRestaurant') : '${s.t('addToCart')} · ${eur(total, app.lang)}'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black26,
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: Brand.charcoal))),
        ),
      );
}

/// − qty + pill.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(color: Brand.cream, borderRadius: BorderRadius.circular(14), border: Border.all(color: Brand.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(tooltip: '-1', onPressed: value > 1 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove, size: 20)),
          SizedBox(width: 22, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          IconButton(tooltip: '+1', onPressed: value < 50 ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add, size: 20, color: Brand.tomato)),
        ]),
      );
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.danger = false});
  final String text;
  final bool danger;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: danger ? Brand.tomatoSoft : Brand.warningSoft, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(danger ? Icons.block : Icons.info_outline, size: 17, color: danger ? Brand.tomatoDark : Brand.warning),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: danger ? Brand.tomatoDark : Brand.warning, fontSize: 13, height: 1.4))),
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
          Expanded(child: Text(group.name, style: Brand.h3)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: req ? (error ? Brand.tomato : Brand.tomatoSoft) : Brand.cream2, borderRadius: BorderRadius.circular(999)),
            child: Text(
              req ? '${s.t('required')} · ${s.t('chooseN').replaceAll('{n}', '${group.min > 0 ? group.min : 1}')}' : '${s.t('upToN').replaceAll('{n}', '$max')} · ${s.t('optional')}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: req ? (error ? Colors.white : Brand.tomatoDark) : Brand.muted),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: checked ? Brand.tomato : Brand.border, width: checked ? 1.6 : 1)),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                enabled: !disabled,
                dense: true,
                onTap: () => onChanged(toggleChoice(group, sel, c.key)),
                leading: c.image != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: c.image!, width: 40, height: 40, fit: BoxFit.cover))
                    : Icon(single ? (checked ? Icons.radio_button_checked : Icons.radio_button_off) : (checked ? Icons.check_box : Icons.check_box_outline_blank), color: checked ? Brand.tomato : null),
                title: Text(c.name + (c.needsConfirmation ? ' (${s.t('pending')})' : '') + (!c.available ? ' — ${s.t('soldOut')}' : '')),
                trailing: Text(delta(c.priceDeltaCents, lang), style: TextStyle(fontWeight: FontWeight.w700, color: checked ? Brand.tomato : Brand.muted)),
              ),
            );
          }),
      ]),
    );
  }
}
