import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.category, this.focusSearch = false});
  final String? category;

  /// Opened from a search button: put the cursor in the search field.
  final bool focusSearch;
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  /// Dishes shown per category in the "All" view before "See all".
  static const _preview = 4;

  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _scroll = ScrollController();
  final _categoriesKey = GlobalKey();
  String? _category;
  String _query = '';
  @override
  void initState() {
    super.initState();
    _category = widget.category;
    if (widget.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _searchFocus.requestFocus(),
      );
    }
  }

  @override
  void didUpdateWidget(MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) _category = widget.category;
    if (widget.focusSearch && !oldWidget.focusSearch) {
      _searchFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _selectCategory(String? category) {
    setState(() => _category = category);
    // Keep the category row in view when the list below it changes.
    final ctx = _categoriesKey.currentContext;
    if (ctx != null && _scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final categories = app.menu?.categories ?? const <MenuCategory>[];
    final query = _query.trim().toLowerCase();
    final selected = categories.any((c) => c.key == _category)
        ? _category
        : null;
    final visible = categories
        .where((c) => selected == null || c.key == selected)
        .map(
          (c) => (
            category: c,
            items: c.items
                .where(
                  (i) =>
                      query.isEmpty ||
                      '${i.name} ${i.description}'.toLowerCase().contains(
                        query,
                      ),
                )
                .toList(),
          ),
        )
        .where((c) => c.items.isNotEmpty)
        .toList();
    // "All" without a search shows a preview of each category; a chosen category or a search shows everything.
    final preview = selected == null && query.isEmpty;
    return Scaffold(
      body: LoadingOrError(
        loading: app.loading && app.menu == null,
        error: app.menu == null ? app.error : null,
        onRetry: app.refresh,
        child: RefreshIndicator(
          onRefresh: app.refresh,
          edgeOffset: MediaQuery.paddingOf(context).top,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: ItalianHeaderBackdrop(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.t('menu'),
                                  style: Brand.h1.copyWith(
                                    fontSize: 44,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.t('menuKicker').toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    letterSpacing: 1.6,
                                    color: Brand.charcoal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Material(
                            color: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              tooltip: s.t('search'),
                              style: IconButton.styleFrom(
                                fixedSize: const Size(56, 56),
                              ),
                              onPressed: () => _searchFocus.requestFocus(),
                              icon: const Icon(
                                Icons.search_rounded,
                                color: Brand.tomato,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: Brand.shadow,
                    ),
                    child: TextField(
                      controller: _search,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => setState(() => _query = value),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      decoration: InputDecoration(
                        hintText: s.t('searchDishes'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(
                            Icons.search_rounded,
                            color: Brand.charcoal,
                            size: 26,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: Brand.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: Brand.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                            color: Brand.tomato,
                            width: 1.6,
                          ),
                        ),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: s.t('clearSearch'),
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              if (categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    key: _categoriesKey,
                    height: _CategoryTile.height(context),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _CategoryTile(
                          name: s.t('allCategories'),
                          image: categories.first.image,
                          selected: selected == null,
                          onTap: () => _selectCategory(null),
                        ),
                        for (final c in categories)
                          _CategoryTile(
                            name: c.name,
                            image: c.image,
                            selected: selected == c.key,
                            onTap: () => _selectCategory(c.key),
                          ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: BranchChip(),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Brand.tomatoSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        size: 20,
                        color: Brand.tomato,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          [
                            if (app.branch == null) s.t('pricesBarbastro'),
                            s.t('allergensPending'),
                          ].join(' '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Brand.muted,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: s.t('noResults'),
                  ),
                ),
              for (final group in visible) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(group.category.name, style: Brand.h1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s
                              .t('itemsCount')
                              .replaceAll('{n}', '${group.items.length}'),
                          style: const TextStyle(
                            color: Brand.muted,
                            fontSize: 13,
                          ),
                        ),
                        if (preview && group.items.length > _preview) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 40),
                              padding: const EdgeInsets.only(
                                left: 14,
                                right: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: Brand.body,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () =>
                                _selectCategory(group.category.key),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(s.t('viewAll')),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: preview
                      ? math.min(group.items.length, _preview)
                      : group.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ItemTile(item: group.items[i]),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo + name tile in the category row; all tiles share one size and the selected one is outlined in red.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.image,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final String? image;
  final bool selected;
  final VoidCallback onTap;

  static const width = 70.0;
  static const photo = 52.0;

  /// Row height: padding, photo, gap and one label line at the current text size.
  static double height(BuildContext context) =>
      8 + photo + 6 + MediaQuery.textScalerOf(context).scale(13) * 1.3 + 8 + 2;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? Brand.tomatoSoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? Brand.tomato : Brand.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Column(
                children: [
                  SizedBox(
                    width: photo,
                    height: photo,
                    child: DishImage(
                      url: image,
                      radius: photo / 2,
                      showLabel: false,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Brand.tomato : Brand.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Compact horizontal dish card. The photo carries the heart and the gluten-free badge; the text side has the
/// name, a short description, the price and the add button. Every card has the same height.
class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item});
  final MenuItem item;

  static const _nameStyle = TextStyle(
    fontFamily: Brand.display,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: Brand.charcoal,
  );
  static const _descStyle = TextStyle(
    fontSize: 12.5,
    color: Brand.muted,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = context.select<AppState, String>((a) => a.lang);
    final unavailable = item.soldOut || !item.orderable;
    final scaler = MediaQuery.textScalerOf(context);
    final nameLine = scaler.scale(17) * 1.2;
    final descLine = scaler.scale(12.5) * 1.4;
    // Name and description share three lines (one name line + two description lines, or the other way round).
    final text = math.max(nameLine + 2 * descLine, 2 * nameLine + descLine);
    final height = 10 + text + 8 + 38 + 10;
    final photo = (MediaQuery.sizeOf(context).width * 0.31).clamp(104.0, 136.0);
    return SoftCard(
      padding: EdgeInsets.zero,
      radius: 18,
      onTap: () => context.push('/item/${item.id}'),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: SizedBox(
                width: photo,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DishImage(
                      url: item.hasPhoto ? item.imageUrl : null,
                      showLabel: false,
                      radius: 14,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: FavoriteButton(
                        itemId: item.id,
                        onPhoto: true,
                        size: 32,
                      ),
                    ),
                    if (item.glutenFreeOption)
                      Positioned(
                        left: 5,
                        right: 5,
                        bottom: 5,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(5, 3, 7, 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.grass_rounded,
                                  size: 12,
                                  color: Brand.warning,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    s.t('glutenFreeShort'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Brand.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 10, 10, 10),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final name = TextPainter(
                      text: TextSpan(text: item.name, style: _nameStyle),
                      textScaler: scaler,
                      textDirection: Directionality.of(context),
                      maxLines: 2,
                    )..layout(maxWidth: c.maxWidth);
                    final nameLines = name.computeLineMetrics().length.clamp(
                      1,
                      2,
                    );
                    name.dispose();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _nameStyle,
                        ),
                        if (item.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              item.description,
                              maxLines: 3 - nameLines,
                              overflow: TextOverflow.ellipsis,
                              style: _descStyle,
                            ),
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  itemPriceLabel(s, item, lang),
                                  style: Brand.price.copyWith(fontSize: 17),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (unavailable)
                              Flexible(
                                child: Pill(
                                  text: item.soldOut
                                      ? s.t('soldOut')
                                      : s.t('inStoreOnly'),
                                  color: Brand.muted,
                                  background: Brand.cream2,
                                ),
                              )
                            else
                              // Natural width; the "+" segment is dropped on narrow columns so it always fits.
                              AddButton(
                                label: Text(s.t('add')),
                                plus: c.maxWidth / scaler.scale(1) >= 160,
                                height: 38,
                                onPressed: () => quickAdd(context, item),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
