import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/review.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../state/orders.dart';
import '../widgets/common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<CustomerOrder>? _orders;
  Object? _error;
  String? _loadedFor;

  Future<void> _loadOrders() async {
    try {
      final r = await context.read<Api>().get<Map<String, dynamic>>('/api/v1/me/orders');
      if (mounted) setState(() => (_orders = (r['items'] as List).map((o) => CustomerOrder.fromJson((o as Map).cast<String, dynamic>())).toList(), _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final tracked = context.watch<TrackedOrders>();
    final user = app.user;
    if (user != null && _loadedFor != user.id) {
      _loadedFor = user.id;
      _loadOrders();
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.t('account'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        _ProfileHeader(user: user),
        if (user == null) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: FilledButton(onPressed: () => context.push('/login'), child: Text(s.t('login')))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(onPressed: () => context.push('/login?mode=register'), child: Text(s.t('register')))),
          ]),
        ],
        if (user != null || tracked.items.isNotEmpty) ...[
          SectionHeader(title: s.t('myOrders'), padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
          if (user == null)
            _Group(children: [
              for (final o in tracked.items)
                _OrderRow(title: o.number, subtitle: dateTime(o.at, app.lang), onTap: () => context.push('/order/${o.id}')),
            ])
          else if (_error != null)
            ErrorRetry(error: _error!, onRetry: _loadOrders)
          else if (_orders == null)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (_orders!.isEmpty)
            SoftCard(
              child: Row(children: [
                const Icon(Icons.receipt_long_rounded, color: Brand.hint),
                const SizedBox(width: 12),
                Expanded(child: Text(s.t('noOrders'), style: const TextStyle(color: Brand.muted))),
                TextButton(onPressed: () => context.go('/menu'), child: Text(s.t('orderNow'))),
              ]),
            )
          else
            _Group(children: [
              for (final o in _orders!)
                _OrderRow(
                  title: '${o.number} · ${eur(o.totalCents, app.lang)}',
                  subtitle: dateTime(o.createdAt, app.lang),
                  status: s.t('status.${o.status}'),
                  onTap: () => context.push('/order/${o.id}'),
                ),
            ]),
        ],
        SectionHeader(title: s.t('settings'), padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
        _Group(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const _TileIcon(Icons.language_rounded),
              const SizedBox(width: 14),
              Expanded(child: Text(s.t('language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              SegmentedButton<String>(
                // Only languages the owner enabled (admin → settings → languages) and the app has strings for.
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [for (final l in app.languages) ButtonSegment(value: l, label: Text(l.toUpperCase()))],
                selected: {app.lang},
                onSelectionChanged: (v) => app.setLang(v.first),
              ),
            ]),
          ),
          _Tile(icon: Icons.storefront_rounded, title: s.t('restaurants'), onTap: () => context.push('/restaurants')),
          _Tile(icon: Icons.event_available_rounded, title: s.t('reservations'), onTap: () => context.push('/reservations')),
          _Tile(icon: Icons.star_outline_rounded, title: s.t('rateApp'), onTap: () => ReviewPrompt.openStore(appStoreUrl: app.appStoreUrl)),
        ]),
        SectionHeader(title: s.t('info'), padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
        _Group(children: [
          _Tile(icon: Icons.privacy_tip_outlined, title: s.t('privacy'), external: true, onTap: () => launchUrl(Uri.parse('${AppConfig.websiteUrl}/privacidad'), mode: LaunchMode.externalApplication)),
          _Tile(icon: Icons.gavel_outlined, title: s.t('legal'), external: true, onTap: () => launchUrl(Uri.parse('${AppConfig.websiteUrl}/aviso-legal'), mode: LaunchMode.externalApplication)),
        ]),
        if (user != null) ...[
          const SizedBox(height: 16),
          _Group(children: [
            _Tile(icon: Icons.logout_rounded, title: s.t('logout'), onTap: () => app.logout()),
            _Tile(icon: Icons.delete_outline_rounded, title: s.t('deleteAccount'), danger: true, onTap: () => _delete(context)),
          ]),
        ],
        const SizedBox(height: 28),
        const Center(child: Opacity(opacity: 0.85, child: BrandLogo(height: 40))),
      ]),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final s = S.of(context);
    final pw = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.t('deleteAccount')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [Text(s.t('deleteConfirm')), const SizedBox(height: 12), TextField(controller: pw, obscureText: true, decoration: InputDecoration(labelText: s.t('password')))]),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('deleteAccount')))],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<AppState>().deleteAccount(pw.text);
    } catch (e) {
      if (context.mounted) showSnack(context, apiErrorText(context, e), error: true);
    } finally {
      pw.dispose();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final AppUser? user;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final u = user;
    final name = u?.name?.trim();
    final initial = (name != null && name.isNotEmpty ? name : u?.email ?? '').characters.firstOrNull?.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: Brand.heroGradient, borderRadius: BorderRadius.circular(22), boxShadow: Brand.shadow),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 3)),
          child: initial == null
              ? const Icon(Icons.person_rounded, color: Brand.tomato, size: 30)
              : Text(initial, style: Brand.h2.copyWith(color: Brand.tomato)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              u == null ? s.t('welcomeGuest') : s.t('hello').replaceAll('{name}', name?.isNotEmpty == true ? name!.split(' ').first : u.email),
              style: Brand.h3.copyWith(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              u == null ? s.t('guestInfo') : [u.email, u.phone].whereType<String>().join(' · '),
              style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13, height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// White rounded group of rows separated by dividers (settings style).
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Brand.border), boxShadow: Brand.shadow),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
              children[i],
            ],
          ]),
        ),
      );
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon, {this.danger = false});
  final IconData icon;
  final bool danger;
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: danger ? Brand.tomatoSoft : Brand.cream, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: danger ? Brand.tomatoDark : Brand.charcoal),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.onTap, this.danger = false, this.external = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
  final bool external;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: _TileIcon(icon, danger: danger),
        title: Text(title, style: TextStyle(color: danger ? Brand.tomatoDark : Brand.charcoal)),
        trailing: Icon(external ? Icons.open_in_new_rounded : Icons.chevron_right_rounded, size: external ? 18 : 22, color: Brand.hint),
        onTap: onTap,
      );
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.title, required this.subtitle, required this.onTap, this.status});
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const _TileIcon(Icons.receipt_long_rounded),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(subtitle, style: const TextStyle(color: Brand.muted, fontSize: 12.5)),
            if (status != null) Pill(text: status!, color: Brand.charcoal, background: Brand.cream2),
          ]),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Brand.hint),
        onTap: onTap,
      );
}
