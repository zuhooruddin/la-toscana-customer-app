import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/i18n.dart';
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
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(background: DishImage(url: item.hasPhoto ? item.imageUrl : null, radius: 0)),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(children: [
            Text(item.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(item.description, style: const TextStyle(color: Brand.muted, fontSize: 15))),
            const SizedBox(height: 10),
            if (!item.allergensVerified) _Note(text: s.t('allergensPending')),
            if (item.orderableNote != null) _Note(text: item.orderableNote!),
            if (item.soldOut) _Note(text: s.t('soldOut'), danger: true),
            if (app.branch == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(onPressed: () => context.push('/select'), icon: const Icon(Icons.place_outlined), label: Text(s.t('chooseRestaurant'))),
              ),
            for (final g in item.optionGroups) _Group(group: g, sel: _sel, error: _touched && missing.contains(g), onChanged: (sel) => setState(() => _sel = normaliseSelection(item, sel))),
            const SizedBox(height: 16),
            Text(s.t('instructions'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            TextField(controller: _notes, maxLength: 200, maxLines: 2, decoration: InputDecoration(hintText: s.t('instructionsHint'))),
            Row(children: [
              Text(s.t('quantity'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              IconButton.outlined(onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove), tooltip: '-1'),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              IconButton.outlined(onPressed: _qty < 50 ? () => setState(() => _qty++) : null, icon: const Icon(Icons.add), tooltip: '+1'),
            ]),
            const SizedBox(height: 80),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Brand.border))),
          child: Row(children: [
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.t('total'), style: const TextStyle(color: Brand.muted, fontSize: 12)),
              Text(eur(total, app.lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(width: 16),
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
                child: Text(app.branch == null ? s.t('chooseRestaurant') : s.t('addToCart')),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.danger = false});
  final String text;
  final bool danger;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: danger ? const Color(0xFFFDECEA) : const Color(0xFFFFF4DC), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(color: danger ? Brand.tomatoDark : const Color(0xFF7A4500), fontSize: 13)),
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
      padding: const EdgeInsets.only(top: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: req ? (error ? Brand.tomato : const Color(0xFFFDECEA)) : const Color(0xFFEFEDEA), borderRadius: BorderRadius.circular(999)),
            child: Text(
              req ? '${s.t('required')} · ${s.t('chooseN').replaceAll('{n}', '${group.min > 0 ? group.min : 1}')}' : '${s.t('upToN').replaceAll('{n}', '$max')} · ${s.t('optional')}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: req && error ? Colors.white : Brand.charcoal),
            ),
          ),
        ]),
        if (group.warning != null && chosen.contains('base-sin-gluten')) Padding(padding: const EdgeInsets.only(top: 6), child: _Note(text: group.warning!)),
        const SizedBox(height: 6),
        for (final c in group.choices)
          Builder(builder: (context) {
            final checked = chosen.contains(c.key);
            final disabled = !c.available || (!checked && !single && chosen.length >= max);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: checked ? Brand.tomato : Brand.border)),
              child: ListTile(
                enabled: !disabled,
                dense: true,
                onTap: () => onChanged(toggleChoice(group, sel, c.key)),
                leading: c.image != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: c.image!, width: 40, height: 40, fit: BoxFit.cover))
                    : Icon(single ? (checked ? Icons.radio_button_checked : Icons.radio_button_off) : (checked ? Icons.check_box : Icons.check_box_outline_blank), color: checked ? Brand.tomato : null),
                title: Text(c.name + (c.needsConfirmation ? ' (${s.t('pending')})' : '') + (!c.available ? ' — ${s.t('soldOut')}' : '')),
                trailing: Text(delta(c.priceDeltaCents, lang), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            );
          }),
      ]),
    );
  }
}
