import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/i18n.dart';
import '../core/models.dart' as m;
import '../core/theme.dart';
import '../state/app_state.dart';
import '../state/cart.dart';
import '../widgets/common.dart';
import 'select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Category chosen in the circle row; its shelf is scrolled into view.
  String? _category;
  final _shelfKeys = <String, GlobalKey>{};

  void _jumpTo(m.MenuCategory c) {
    setState(() => _category = c.key);
    final ctx = _shelfKeys[c.key]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final categories = (app.menu?.categories ?? const <m.MenuCategory>[])
        .where((c) => c.items.isNotEmpty)
        .toList();
    final selected = categories.any((c) => c.key == _category)
        ? _category
        : categories.firstOrNull?.key;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        drawer: const _HomeDrawer(),
        body: RefreshIndicator(
          onRefresh: app.refresh,
          edgeOffset: MediaQuery.paddingOf(context).top + 64,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const _Header(),
              SliverToBoxAdapter(child: _HeroCarousel(banners: app.banners)),
              if (app.branch != null && !app.branch!.canOrderOnline)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        Flexible(
                          child: BranchStatusPill(
                            branch: app.branch!,
                            label: orderingLabel(s, app.branch!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (app.loading && app.menu == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (app.menu == null && app.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorRetry(error: app.error!, onRetry: app.refresh),
                )
              else ...[
                if (categories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _Categories(
                      categories: categories,
                      selected: selected,
                      onSelect: _jumpTo,
                    ),
                  ),
                for (final c in categories)
                  SliverToBoxAdapter(
                    child: _Shelf(
                      key: _shelfKeys.putIfAbsent(c.key, GlobalKey.new),
                      category: c,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu button, centred logo, search and cart. Stays pinned while scrolling.
class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final count = context.watch<CartStore>().count;
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 68,
      backgroundColor: Brand.cream,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: s.t('openMenu'),
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded, size: 28),
        ),
      ),
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: const BrandLogo(height: 52),
      ),
      actions: [
        IconButton(
          tooltip: s.t('search'),
          onPressed: () => context.go('/menu?search=1'),
          icon: const Icon(Icons.search_rounded, size: 27),
        ),
        IconButton(
          tooltip: s.t('cart'),
          onPressed: () => context.go('/cart'),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.shopping_cart_outlined, size: 27),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    Widget link(IconData icon, String label, VoidCallback onTap) => ListTile(
      leading: Icon(icon, color: Brand.tomato),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
    return Drawer(
      backgroundColor: Brand.cream,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandLogo(height: 56),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: BranchChip(),
            ),
            link(
              Icons.restaurant_rounded,
              s.t('menu'),
              () => context.go('/menu'),
            ),
            link(
              Icons.event_available_rounded,
              s.t('bookTable'),
              () => context.push('/reservations'),
            ),
            link(
              Icons.storefront_rounded,
              s.t('restaurants'),
              () => context.push('/restaurants'),
            ),
            link(
              Icons.person_outline_rounded,
              s.t('account'),
              () => context.go('/account'),
            ),
            const Divider(indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                s.t('language'),
                style: const TextStyle(
                  color: Brand.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'es', label: Text('Español')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {app.lang},
                onSelectionChanged: (v) => app.setLang(v.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand slide first, then the restaurant's banners from the admin; swipes on its own every few seconds.
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({required this.banners});
  final List<m.Banner> banners;
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _page = PageController();
  Timer? _timer;
  int _i = 0;

  int get _count => 1 + widget.banners.length;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_count > 1 && _page.hasClients) {
        _page.animateToPage(
          (_i + 1) % _count,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 210 + (scale - 1) * 100,
          child: Stack(
            children: [
              PageView.builder(
                controller: _page,
                itemCount: _count,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (context, i) => i == 0
                    ? const _BrandSlide()
                    : _BannerSlide(banner: widget.banners[i - 1]),
              ),
              if (_count > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _count; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _i ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _i ? Brand.tomato : Colors.white,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandSlide extends StatelessWidget {
  const _BrandSlide();
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/pizza-hero.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xF2140B09), Color(0xB3241512), Color(0x00241512)],
              stops: [0, 0.5, 1],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
          // Very large text sizes shrink the block to fit the slide instead of clipping it.
          child: LayoutBuilder(
            builder: (context, box) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: box.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t('homeKicker').toUpperCase(),
                      style: const TextStyle(
                        color: Brand.gold,
                        fontSize: 11,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: box.maxWidth * 0.84,
                      ),
                      child: Text(
                        s.t('homeTitle'),
                        style: Brand.h1.copyWith(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: box.maxWidth * 0.74,
                      ),
                      child: Text(
                        s.t('homeBody'),
                        style: const TextStyle(
                          color: Color(0xFFF3E7DC),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: Brand.body,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () => context.go('/menu'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              s.t('orderNow'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner});
  final m.Banner banner;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final b = banner;
    return Material(
      child: InkWell(
        onTap: () => context.go(
          b.link != null && b.link!.contains('#cat-')
              ? '/menu?cat=${b.link!.split('#cat-').last}'
              : '/menu',
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DishImage(url: b.imageUrl, radius: 0, showLabel: false),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xE6241512), Color(0x00241512)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.h1.copyWith(color: Colors.white, fontSize: 25),
                  ),
                  if (b.body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        b.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF3E7DC),
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (b.imageAlt.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    b.imageAlt.length > 40 ? s.t('illustrative') : b.imageAlt,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Round category photos; the chosen one gets a red ring.
class _Categories extends StatelessWidget {
  const _Categories({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<m.MenuCategory> categories;
  final String? selected;
  final ValueChanged<m.MenuCategory> onSelect;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: s.t('categories'),
          action: s.t('viewAll'),
          onAction: () => context.go('/menu'),
          padding: const EdgeInsets.fromLTRB(20, 24, 8, 10),
        ),
        SizedBox(
          // Photo 72 + gaps 12 + two label lines.
          height: 88 + MediaQuery.textScalerOf(context).scale(13) * 1.2 * 2 + 6,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final c = categories[i];
              final on = c.key == selected;
              return Semantics(
                selected: on,
                button: true,
                child: InkWell(
                  onTap: () => onSelect(c),
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: on ? Brand.tomato : Brand.border,
                              width: on ? 2.4 : 1,
                            ),
                            boxShadow: Brand.shadow,
                          ),
                          child: DishImage(
                            url: c.image,
                            radius: 36,
                            showLabel: false,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                            color: on ? Brand.tomato : Brand.charcoal,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A category title with its first two dishes as a two-column grid.
class _Shelf extends StatelessWidget {
  const _Shelf({super.key, required this.category});
  final m.MenuCategory category;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = category.items.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: category.name,
          action: s.t('viewAll'),
          onAction: () => context.go('/menu?cat=${category.key}'),
          padding: const EdgeInsets.fromLTRB(20, 22, 8, 10),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // Cards share one layout (one-line name, two reserved description lines), so a row lines up without
          // IntrinsicHeight, which the card's LayoutBuilder could not answer.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ProductCard(item: items[0])),
              const SizedBox(width: 12),
              Expanded(
                child: items.length > 1
                    ? ProductCard(item: items[1])
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
