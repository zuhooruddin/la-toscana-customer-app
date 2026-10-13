import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.category});
  final String? category;
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _keys = <String, GlobalKey>{};
  final _chipKeys = <String, GlobalKey>{};
  final _scroll = ScrollController();
  final _search = TextEditingController();
  String _q = '';
  String? _active;
  bool _jumping = false;

  @override
  void initState() {
    super.initState();
    _active = widget.category;
    _scroll.addListener(_trackActive);
    _jumpLater();
  }

  @override
  void didUpdateWidget(MenuScreen old) {
    super.didUpdateWidget(old);
    if (widget.category != old.category) {
      _active = widget.category;
      _jumpLater();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _jumpLater() => WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(widget.category));

  Future<void> _jumpTo(String? key) async {
    final ctx = key == null ? null : _keys[key]?.currentContext;
    if (ctx == null) return;
    setState(() => _active = key);
    _revealChip(key!);
    _jumping = true;
    await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    _jumping = false;
  }

  /// Highlights the category whose heading is under the pinned chip bar.
  void _trackActive() {
    if (_jumping) return;
    String? current;
    for (final e in _keys.entries) {
      final box = e.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= 240) current = e.key;
    }
    if (current != null && current != _active) {
      setState(() => _active = current);
      _revealChip(current);
    }
  }

  void _revealChip(String key) {
    final ctx = _chipKeys[key]?.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 250));
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
      appBar: AppBar(
        title: Text(s.t('menu')),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 10), child: BranchChip()),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: app.refresh,
        child: LoadingOrError(
          loading: app.loading && app.menu == null,
          error: app.menu == null ? app.error : null,
          onRetry: app.refresh,
          child: CustomScrollView(controller: _scroll, slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: s.t('searchMenu'),
                    suffixIcon: _q.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _q = '');
                            },
                          ),
                  ),
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
            ),
            if (norm.isEmpty && cats.length > 1)
              SliverPersistentHeader(
                pinned: true,
                delegate: _ChipBar(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: cats.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = cats[i].cat;
                      final sel = c.key == _active;
                      return ChoiceChip(
                        key: _chipKeys.putIfAbsent(c.key, GlobalKey.new),
                        label: Text(c.name),
                        selected: sel,
                        showCheckmark: false,
                        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: sel ? Colors.white : Brand.charcoal),
                        side: BorderSide(color: sel ? Brand.tomato : Brand.border),
                        onSelected: (_) => _jumpTo(c.key),
                      );
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Brand.warningSoft, borderRadius: BorderRadius.circular(14)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline, size: 18, color: Brand.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [if (app.branch == null) s.t('pricesBarbastro'), s.t('allergensPending')].join('\n'),
                          style: const TextStyle(fontSize: 12.5, color: Brand.warning, height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            if (cats.isEmpty) SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.search_off, title: s.t('noResults'))),
            for (final x in cats) ...[
              SliverToBoxAdapter(
                child: Padding(
                  key: _keys.putIfAbsent(x.cat.key, GlobalKey.new),
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(child: Text(x.cat.name, style: Brand.h2)),
                    Text(s.t('nItems').replaceAll('{n}', '${x.items.length}'), style: const TextStyle(color: Brand.hint, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              SliverList.separated(
                itemCount: x.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ItemTile(item: x.items[i])),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ]),
        ),
      ),
    );
  }
}

class _ChipBar extends SliverPersistentHeaderDelegate {
  _ChipBar({required this.child});
  final Widget child;
  @override
  double get minExtent => 58;
  @override
  double get maxExtent => 58;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(
        decoration: BoxDecoration(
          color: Brand.cream,
          border: overlapsContent || shrinkOffset > 0 ? const Border(bottom: BorderSide(color: Brand.border)) : null,
        ),
        child: child,
      );
  @override
  bool shouldRebuild(_ChipBar old) => true;
}

/// Menu row: text on the left, photo with an add button on the right.
class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = context.select<AppState, String>((a) => a.lang);
    final unavailable = item.soldOut || !item.orderable;
    return SoftCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/item/${item.id}'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, height: 1.25)),
            if (item.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Brand.muted, fontSize: 13, height: 1.4)),
              ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(itemPriceLabel(s, item, lang), style: Brand.price.copyWith(fontSize: 16)),
              if (unavailable)
                Pill(
                  text: item.soldOut ? s.t('soldOut') : s.t('inStoreOnly'),
                  color: Brand.muted,
                  background: Brand.cream2,
                ),
            ]),
          ]),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: DishImage(url: item.hasPhoto ? item.imageUrl : null, radius: 14, showLabel: false)),
            if (!unavailable) Positioned(right: -4, bottom: -4, child: DecoratedBox(decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: Brand.shadowPrimary), child: AddButton(onPressed: () => quickAdd(context, item)))),
          ]),
        ),
      ]),
    );
  }
}
