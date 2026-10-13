import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/i18n.dart';
import '../core/links.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'select_screen.dart';

const _days = {
  'es': ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'],
  'en': ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
};

class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 190,
          foregroundColor: Colors.white,
          backgroundColor: Brand.tomatoDeep,
          title: Text(s.t('restaurants'), style: const TextStyle(color: Colors.white)),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/hero.jpg', fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99241512), Color(0xE65E1C17)])),
              ),
              Positioned(
                left: 16,
                bottom: 18,
                right: 16,
                child: Row(children: [
                  const ItalianFlag(),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.t('heroTitle'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                ]),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          sliver: SliverList.separated(
            itemCount: app.branches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _BranchCard(branch: app.branches[i]),
          ),
        ),
      ]),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch});
  final Branch branch;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.read<AppState>();
    final b = branch;
    final days = _days[app.lang] ?? _days['es']!;
    final today = DateTime.now().weekday;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Brand.tomatoSoft, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.local_pizza_outlined, color: Brand.tomato),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.name, style: Brand.h3),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.place_outlined, size: 15, color: Brand.muted)),
                const SizedBox(width: 4),
                Expanded(child: Text(b.address, style: const TextStyle(color: Brand.muted, fontSize: 13, height: 1.35))),
              ]),
              const SizedBox(height: 8),
              BranchStatusPill(branch: b, label: orderingLabel(s, b)),
            ]),
          ),
          IconButton(
            tooltip: s.t('share'),
            icon: const Icon(Icons.ios_share, size: 20, color: Brand.muted),
            onPressed: () => SharePlus.instance.share(ShareParams(text: '${b.name} — ${b.address}\n${WebLinks.restaurant(app.lang, b.slug)}')),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Brand.surfaceWarm, borderRadius: BorderRadius.circular(14), border: Border.all(color: Brand.divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.schedule, size: 16, color: Brand.tomato),
              const SizedBox(width: 6),
              Text(s.t('hours'), style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            if (!b.hoursVerified)
              Text(s.t('hoursPending'), style: const TextStyle(color: Brand.muted, fontSize: 13))
            else
              for (var d = 1; d <= 7; d++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    SizedBox(
                      width: 96,
                      child: Text(days[d], style: TextStyle(fontSize: 13, fontWeight: d == today ? FontWeight.w800 : FontWeight.w500, color: d == today ? Brand.tomatoDark : Brand.charcoal)),
                    ),
                    Expanded(
                      child: Text(
                        (b.hours[d] ?? const []).isEmpty ? (app.lang == 'en' ? 'Closed' : 'Cerrado') : b.hours[d]!.map((iv) => '${iv.open}–${iv.close}').join(' · '),
                        style: TextStyle(fontSize: 13, color: d == today ? Brand.tomatoDark : Brand.muted, fontWeight: d == today ? FontWeight.w700 : FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
          ]),
        ),
        const SizedBox(height: 14),
        if (b.canOrderOnline)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await app.selectBranch(b.slug, 'pickup');
                  if (context.mounted) context.go('/menu');
                },
                icon: const Icon(Icons.local_pizza_outlined),
                label: Text(s.t('orderNow')),
              ),
            ),
          ),
        Row(children: [
          if (b.phone != null) ...[
            Expanded(child: OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse('tel:${b.phone!.replaceAll(' ', '')}')), icon: const Icon(Icons.call_outlined, size: 18), label: Text(s.t('call')))),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(b.lat != null ? '${b.lat},${b.lng}' : '${b.address}, España')}'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.directions_outlined, size: 18),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(s.t('directions'))),
            ),
          ),
        ]),
        if (b.reservationsEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(onPressed: () => context.push('/reservations?branch=${b.slug}'), icon: const Icon(Icons.event_seat_outlined, size: 18), label: Text(s.t('bookTable'))),
            ),
          ),
      ]),
    );
  }
}
