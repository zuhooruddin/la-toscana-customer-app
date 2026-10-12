import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
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
      appBar: AppBar(title: Text(s.t('restaurants'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: app.branches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _BranchCard(branch: app.branches[i]),
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(b.address, style: const TextStyle(color: Brand.muted)),
          const SizedBox(height: 6),
          Text(orderingLabel(s, b), style: TextStyle(color: b.canOrderOnline ? Brand.basil : Brand.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(s.t('hours'), style: const TextStyle(fontWeight: FontWeight.w700)),
          if (!b.hoursVerified)
            Text(s.t('hoursPending'), style: const TextStyle(color: Brand.muted))
          else
            for (var d = 1; d <= 7; d++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(children: [
                  SizedBox(width: 100, child: Text(days[d], style: const TextStyle(fontSize: 13))),
                  Text(
                    (b.hours[d] ?? const []).isEmpty ? (app.lang == 'en' ? 'Closed' : 'Cerrado') : b.hours[d]!.map((iv) => '${iv.open}–${iv.close}').join(' · '),
                    style: const TextStyle(fontSize: 13, color: Brand.muted),
                  ),
                ]),
              ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (b.canOrderOnline)
              FilledButton(
                onPressed: () async {
                  await app.selectBranch(b.slug, 'pickup');
                  if (context.mounted) context.go('/menu');
                },
                child: Text(s.t('orderNow')),
              ),
            if (b.phone != null) OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse('tel:${b.phone!.replaceAll(' ', '')}')), icon: const Icon(Icons.call_outlined), label: Text(s.t('call'))),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(b.lat != null ? '${b.lat},${b.lng}' : '${b.address}, España')}'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.directions_outlined),
              label: Text(s.t('directions')),
            ),
            if (b.reservationsEnabled) OutlinedButton.icon(onPressed: () => context.push('/reservations?branch=${b.slug}'), icon: const Icon(Icons.event_seat_outlined), label: Text(s.t('bookTable'))),
          ]),
        ]),
      ),
    );
  }
}
