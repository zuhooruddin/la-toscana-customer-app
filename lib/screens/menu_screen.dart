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

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.category});
  final String? category;
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _keys = <String, GlobalKey>{};
  String _q = '';

  @override
  void didUpdateWidget(MenuScreen old) {
    super.didUpdateWidget(old);
    if (widget.category != old.category) _jumpLater();
  }

  @override
  void initState() {
    super.initState();
    _jumpLater();
  }

  void _jumpLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final k = widget.category == null ? null : _keys[widget.category];
      if (k?.currentContext != null) Scrollable.ensureVisible(k!.currentContext!, duration: const Duration(milliseconds: 300));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final norm = _q.toLowerCase().trim();
    final cats = (app.menu?.categories ?? const <MenuCategory>[])
        .map((c) => (cat: c, items: norm.isEmpty ? c.items : c.items.where((i) => i.name.toLowerCase().contains(norm) || i.description.toLowerCase().contains(norm)).toList()))
        .where((x) => x.items.isNotEmpty)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('menu')), bottom: PreferredSize(preferredSize: const Size.fromHeight(56), child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Align(alignment: Alignment.centerLeft, child: const BranchChip())))),
      body: RefreshIndicator(
        onRefresh: app.refresh,
        child: LoadingOrError(
          loading: app.loading && app.menu == null,
          error: app.menu == null ? app.error : null,
          onRetry: app.refresh,
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar / Search', isDense: true),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
            ),
            if (app.branch == null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: Text(s.t('pricesBarbastro'), style: const TextStyle(color: Brand.muted)))),
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: Text(s.t('allergensPending'), style: const TextStyle(fontSize: 12, color: Brand.muted))),
            ),
            for (final x in cats) ...[
              SliverToBoxAdapter(
                child: Padding(
                  key: _keys.putIfAbsent(x.cat.key, GlobalKey.new),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(x.cat.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ),
              SliverList.separated(
                itemCount: x.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ItemTile(item: x.items[i])),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ]),
        ),
      ),
    );
  }
}

class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final hasOptions = item.optionGroups.isNotEmpty;
    final unavailable = item.soldOut || !item.orderable;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/item/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 92, height: 92, child: DishImage(url: item.hasPhoto ? item.imageUrl : null, radius: 12, showLabel: false)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                if (item.description.isNotEmpty) Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Brand.muted, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: Text(
                      item.hasRequiredOptions ? '${s.t('from')} ${eur(fromPrice(item), app.lang)}' : eur(item.priceCents, app.lang),
                      style: const TextStyle(color: Brand.tomato, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (unavailable)
                    Text(item.soldOut ? s.t('soldOut') : s.t('inStoreOnly'), style: const TextStyle(color: Brand.muted, fontWeight: FontWeight.w600))
                  else
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(minimumSize: const Size(40, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(hasOptions ? s.t('choose') : s.t('add')),
                      onPressed: () {
                        if (app.branch == null) {
                          context.push('/select');
                        } else if (hasOptions) {
                          context.push('/item/${item.id}');
                        } else {
                          context.read<CartStore>().add(app.branchSlug!, item, const {}, 1, null);
                          showSnack(context, '${item.name} · ${s.t('added')}');
                        }
                      },
                    ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
