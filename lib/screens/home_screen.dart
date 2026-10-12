import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('La Toscana', style: TextStyle(fontWeight: FontWeight.w800, color: Brand.tomatoDark)),
        actions: [
          IconButton(tooltip: s.t('restaurants'), icon: const Icon(Icons.storefront_outlined), onPressed: () => context.push('/restaurants')),
          IconButton(tooltip: s.t('reservations'), icon: const Icon(Icons.event_seat_outlined), onPressed: () => context.push('/reservations')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: app.refresh,
        child: LoadingOrError(
          loading: app.loading && app.menu == null,
          error: app.menu == null ? app.error : null,
          onRetry: app.refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Align(alignment: Alignment.centerLeft, child: const BranchChip())),
              if (app.branch != null && !app.branch!.canOrderOnline)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(orderingLabel(s, app.branch!), style: const TextStyle(color: Brand.tomatoDark, fontWeight: FontWeight.w600)),
                ),
              if (app.banners.isNotEmpty) _Slider(banners: app.banners),
              _Categories(categories: app.menu?.categories ?? const []),
              for (final c in (app.menu?.categories ?? const <m.MenuCategory>[]).take(3)) _Row(category: c),
            ],
          ),
        ),
      ),
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
  final _page = PageController(viewportFraction: 0.92);
  int _i = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(children: [
      SizedBox(
        height: 190,
        child: PageView.builder(
          controller: _page,
          itemCount: widget.banners.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (context, i) {
            final b = widget.banners[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.go(b.link != null && b.link!.contains('#cat-') ? '/menu?cat=${b.link!.split('#cat-').last}' : '/menu'),
                child: Stack(fit: StackFit.expand, children: [
                  DishImage(url: b.imageUrl, radius: 18, showLabel: false),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(colors: [Color(0xE6120C0A), Color(0x00120C0A)], begin: Alignment.bottomLeft, end: Alignment.topRight),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      if (b.body.isNotEmpty) Text(b.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF3E7DC))),
                    ]),
                  ),
                  if (b.imageAlt.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                        child: Text(b.imageAlt.length > 40 ? s.t('illustrative') : b.imageAlt, style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ]),
              ),
            );
          },
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.banners.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(3),
              width: i == _i ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(color: i == _i ? Brand.tomato : Brand.border, borderRadius: BorderRadius.circular(9)),
            ),
        ],
      ),
    ]);
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.categories});
  final List<m.MenuCategory> categories;
  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(S.of(context).t('categories'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
      SizedBox(
        height: 108,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final c = categories[i];
            return InkWell(
              onTap: () => context.go('/menu?cat=${c.key}'),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                child: Column(children: [
                  SizedBox(width: 68, height: 68, child: DishImage(url: c.image, radius: 34, showLabel: false)),
                  const SizedBox(height: 6),
                  Text(c.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.category});
  final m.MenuCategory category;
  @override
  Widget build(BuildContext context) {
    final lang = context.select<AppState, String>((a) => a.lang);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Row(children: [
          Expanded(child: Text(category.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          TextButton(onPressed: () => context.go('/menu?cat=${category.key}'), child: Text(S.of(context).t('seeMenu'))),
        ]),
      ),
      SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: category.items.length.clamp(0, 10),
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final it = category.items[i];
            return SizedBox(
              width: 160,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push('/item/${it.id}'),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    DishImage(url: it.hasPhoto ? it.imageUrl : null, height: 118, radius: 0),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(eur(it.priceCents, lang), style: const TextStyle(color: Brand.tomato, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
