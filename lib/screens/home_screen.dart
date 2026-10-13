import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/i18n.dart';
import '../core/models.dart' as m;
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'select_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final categories = app.menu?.categories ?? const <m.MenuCategory>[];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: app.refresh,
          edgeOffset: MediaQuery.paddingOf(context).top,
          child: CustomScrollView(slivers: [
            const SliverToBoxAdapter(child: _Hero()),
            if (app.branch != null && !app.branch!.canOrderOnline)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(children: [BranchStatusPill(branch: app.branch!, label: orderingLabel(s, app.branch!))]),
                ),
              ),
            const SliverToBoxAdapter(child: _QuickActions()),
            if (app.loading && app.menu == null)
              const SliverFillRemaining(hasScrollBody: false, child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
            else if (app.menu == null && app.error != null)
              SliverFillRemaining(hasScrollBody: false, child: ErrorRetry(error: app.error!, onRetry: app.refresh))
            else ...[
              if (app.banners.isNotEmpty) SliverToBoxAdapter(child: _Slider(banners: app.banners)),
              if (categories.isNotEmpty) SliverToBoxAdapter(child: _Categories(categories: categories)),
              for (final c in categories.where((c) => c.items.isNotEmpty).take(4)) SliverToBoxAdapter(child: _Shelf(category: c)),
              const SliverToBoxAdapter(child: _SignOff()),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Photo hero like the website's home: logo, tagline and where the order goes.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/hero.jpg', fit: BoxFit.cover)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB3241512), Color(0xCC3B1A15), Color(0xF25E1C17)],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 10, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: Brand.shadow),
                child: const BrandLogo(height: 40),
              ),
              const Spacer(),
              _RoundIcon(icon: Icons.storefront_outlined, tooltip: s.t('restaurants'), onTap: () => context.push('/restaurants')),
              const SizedBox(width: 8),
              _RoundIcon(icon: Icons.event_seat_outlined, tooltip: s.t('reservations'), onTap: () => context.push('/reservations')),
            ]),
            const SizedBox(height: 26),
            Row(children: [
              const ItalianFlag(),
              const SizedBox(width: 8),
              Text(s.t('heroKicker').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2.2, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            Text(s.t('heroTitle'), style: Brand.h1.copyWith(color: Colors.white, fontSize: 32)),
            const SizedBox(height: 8),
            Text(s.t('heroBody'), style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 15, height: 1.45)),
            const SizedBox(height: 18),
            const BranchChip(dark: true),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Brand.tomato),
                onPressed: () => context.go('/menu'),
                icon: const Icon(Icons.local_pizza_outlined),
                label: Text(s.t('orderNow')),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 22))),
        ),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget tile(IconData icon, String label, Color color, Color bg, VoidCallback onTap) => Expanded(
          child: SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            onTap: onTap,
            child: Column(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
              const SizedBox(height: 8),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(children: [
        tile(Icons.restaurant_menu, s.t('quickOrder'), Brand.tomato, Brand.tomatoSoft, () => context.go('/menu')),
        const SizedBox(width: 10),
        tile(Icons.event_seat_outlined, s.t('quickBook'), Brand.basilDark, Brand.basilSoft, () => context.push('/reservations')),
        const SizedBox(width: 10),
        tile(Icons.place_outlined, s.t('quickFind'), Brand.warning, Brand.warningSoft, () => context.push('/restaurants')),
      ]),
    );
  }
}

class _Slider extends StatefulWidget {
  const _Slider({required this.banners});
  final List<m.Banner> banners;
  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  final _page = PageController(viewportFraction: 0.9);
  int _i = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _page,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (context, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: Brand.shadow),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Material(
                      child: InkWell(
                        onTap: () => context.go(b.link != null && b.link!.contains('#cat-') ? '/menu?cat=${b.link!.split('#cat-').last}' : '/menu'),
                        child: Stack(fit: StackFit.expand, children: [
                          DishImage(url: b.imageUrl, radius: 0, showLabel: false),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xE6241512), Color(0x00241512)], begin: Alignment.bottomLeft, end: Alignment.topRight),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 16,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Brand.h2.copyWith(color: Colors.white)),
                              if (b.body.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(b.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF3E7DC), fontSize: 13)),
                                ),
                            ]),
                          ),
                          if (b.imageAlt.isNotEmpty)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                                child: Text(b.imageAlt.length > 40 ? s.t('illustrative') : b.imageAlt, style: const TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ),
                        ]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.banners.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _i ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(color: i == _i ? Brand.tomato : const Color(0xFFE2D6C6), borderRadius: BorderRadius.circular(9)),
                  ),
              ],
            ),
          ),
      ]),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.categories});
  final List<m.MenuCategory> categories;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: s.t('categories'), action: s.t('viewAll'), onAction: () => context.go('/menu')),
      SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final c = categories[i];
            return InkWell(
              onTap: () => context.go('/menu?cat=${c.key}'),
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 80,
                child: Column(children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Brand.border), boxShadow: Brand.shadow),
                    child: DishImage(url: c.image, radius: 36, showLabel: false),
                  ),
                  const SizedBox(height: 8),
                  Text(c.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.category});
  final m.MenuCategory category;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: category.name, action: s.t('viewAll'), onAction: () => context.go('/menu?cat=${category.key}')),
      SizedBox(
        height: 250,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          clipBehavior: Clip.none,
          itemCount: category.items.length.clamp(0, 10),
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) => ProductCard(item: category.items[i]),
        ),
      ),
    ]);
  }
}

class _SignOff extends StatelessWidget {
  const _SignOff();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
        child: Column(children: [
          Opacity(opacity: 0.9, child: const BrandLogo(height: 52)),
          const SizedBox(height: 8),
          const ItalianFlag(width: 36),
          const SizedBox(height: 8),
          Text(S.of(context).t('heroTitle'), style: const TextStyle(color: Brand.muted, fontFamily: Brand.display, fontWeight: FontWeight.w600)),
        ]),
      );
}
