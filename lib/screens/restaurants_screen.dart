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
  'es': [
    '',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ],
  'en': [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ],
};

class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ItalianHeaderBackdrop(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: Colors.black26,
                        child: IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/'),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.t('restaurants'),
                              style: Brand.h1.copyWith(fontSize: 34),
                            ),
                            Text(s.t('restaurantsIntro'), style: Brand.h1),
                            const SizedBox(height: 8),
                            Text(
                              s.t('restaurantsBody'),
                              style: const TextStyle(
                                color: Brand.muted,
                                fontSize: 15,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Semantics(
                    selected: true,
                    child: Chip(
                      avatar: const Icon(
                        Icons.storefront_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text(
                        s.t('allCategories'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: Brand.tomato,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.https('www.google.com', '/maps/search/', {
                        'api': '1',
                        'query': 'La Toscana Pizzeria near me',
                      }),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.location_on_outlined, size: 20),
                    label: Text(s.t('nearby')),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.https('www.google.com', '/maps/search/', {
                        'api': '1',
                        'query': 'La Toscana Pizzeria Huesca Barbastro Fraga',
                      }),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.map_outlined, size: 20),
                    label: Text(s.t('viewOnMap')),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            sliver: SliverList.separated(
              itemCount: app.branches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemBuilder: (context, i) => _BranchCard(branch: app.branches[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatefulWidget {
  const _BranchCard({required this.branch});
  final Branch branch;
  @override
  State<_BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<_BranchCard> {
  bool _hoursOpen = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final b = widget.branch;
    final selected = app.branchSlug == b.slug;
    final days = _days[app.lang] ?? _days['es']!;
    final today = DateTime.now().weekday;
    String dayHours(int d) => (b.hours[d] ?? const [])
        .map((iv) => '${iv.open}–${iv.close}')
        .join(' · ');
    final todaySummary = !b.hoursVerified
        ? s.t('hoursPending')
        : (b.hours[today] ?? const []).isEmpty
        ? s.t('closedToday')
        : dayHours(today);

    final hoursTile = _InfoTile(
      icon: Icons.schedule_rounded,
      title: s.t('hours'),
      subtitle: todaySummary,
      trailing: _hoursOpen
          ? Icons.expand_less_rounded
          : Icons.expand_more_rounded,
      onTap: () => setState(() => _hoursOpen = !_hoursOpen),
    );
    final bookTile = b.reservationsEnabled
        ? _InfoTile(
            icon: Icons.event_available_rounded,
            title: s.t('bookTable'),
            subtitle: s.t('checkAvailability'),
            trailing: Icons.chevron_right_rounded,
            onTap: () => context.push('/reservations?branch=${b.slug}'),
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? Brand.tomato : Brand.border,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: Brand.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: AspectRatio(
              aspectRatio: 2.4,
              child: DishImage(url: b.imageUrl, radius: 18, showLabel: false),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        b.name,
                        style: Brand.h2.copyWith(fontSize: 24),
                      ),
                    ),
                    IconButton(
                      tooltip: s.t('share'),
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Brand.border),
                      ),
                      icon: const Icon(Icons.ios_share, size: 20),
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${b.name} — ${b.address}\n${WebLinks.restaurant(app.lang, b.slug)}',
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 17,
                        color: Brand.muted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        b.address,
                        style: const TextStyle(
                          color: Brand.muted,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                BranchStatusPill(branch: b, label: orderingLabel(s, b)),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, c) {
                    // Two tiles side by side when there is room; stacked on narrow screens / large text.
                    final wide =
                        c.maxWidth /
                            MediaQuery.textScalerOf(context).scale(1) >=
                        300;
                    if (bookTile == null) return hoursTile;
                    return wide
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: hoursTile),
                                const SizedBox(width: 10),
                                Expanded(child: bookTile),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              hoursTile,
                              const SizedBox(height: 10),
                              bookTile,
                            ],
                          );
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: !_hoursOpen
                      ? const SizedBox(width: double.infinity)
                      : Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Brand.cream,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: !b.hoursVerified
                              ? Text(
                                  s.t('hoursPending'),
                                  style: const TextStyle(
                                    color: Brand.muted,
                                    fontSize: 13,
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (var d = 1; d <= 7; d++)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 3,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 96,
                                              child: Text(
                                                days[d],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: d == today
                                                      ? FontWeight.w800
                                                      : FontWeight.w500,
                                                  color: d == today
                                                      ? Brand.tomatoDark
                                                      : Brand.charcoal,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                (b.hours[d] ?? const []).isEmpty
                                                    ? s.t('closedDay')
                                                    : dayHours(d),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: d == today
                                                      ? Brand.tomatoDark
                                                      : Brand.muted,
                                                  fontWeight: d == today
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                ),
                if (b.canOrderOnline)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () async {
                        await app.selectBranch(b.slug, 'pickup');
                        if (context.mounted) context.go('/menu');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restaurant_rounded, size: 20),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              s.t('orderNow'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (b.phone != null) ...[
                      Expanded(
                        child: _SoftAction(
                          icon: Icons.call_rounded,
                          label: s.t('call'),
                          onTap: () => launchUrl(
                            Uri.parse('tel:${b.phone!.replaceAll(' ', '')}'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _SoftAction(
                        icon: Icons.directions_rounded,
                        label: s.t('directions'),
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(b.lat != null ? '${b.lat},${b.lng}' : '${b.address}, España')}',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered tile with an icon, a title, a one-line detail and a trailing chevron.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Brand.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
        child: Row(
          children: [
            Icon(icon, color: Brand.tomato, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Brand.muted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(trailing, color: Brand.charcoal, size: 20),
          ],
        ),
      ),
    ),
  );
}

/// Soft red secondary action ("Call", "Directions").
class _SoftAction extends StatelessWidget {
  const _SoftAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(
      backgroundColor: Brand.tomatoSoft,
      foregroundColor: Brand.tomatoDark,
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    onPressed: onTap,
    icon: Icon(icon, size: 20),
    label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
  );
}
