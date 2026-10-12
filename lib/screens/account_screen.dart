import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
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
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (user == null) ...[
          Text(s.t('guestInfo'), style: const TextStyle(color: Brand.muted)),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => context.push('/login'), child: Text(s.t('login'))),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => context.push('/login?mode=register'), child: Text(s.t('register'))),
          if (tracked.items.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(s.t('myOrders'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            for (final o in tracked.items)
              ListTile(contentPadding: EdgeInsets.zero, title: Text(o.number), subtitle: Text(dateTime(o.at, app.lang)), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/order/${o.id}')),
          ],
        ] else ...[
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Brand.tomato, foregroundColor: Colors.white, child: Icon(Icons.person)),
              title: Text(user.name ?? user.email, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text([user.email, user.phone].whereType<String>().join(' · ')),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.t('myOrders'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (_error != null)
            ErrorRetry(error: _error!, onRetry: _loadOrders)
          else if (_orders == null)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (_orders!.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.t('noOrders'), style: const TextStyle(color: Brand.muted)))
          else
            for (final o in _orders!)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${o.number} · ${eur(o.totalCents, app.lang)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${dateTime(o.createdAt, app.lang)} · ${s.t('status.${o.status}')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/order/${o.id}'),
              ),
        ],
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.language),
          title: Text(s.t('language')),
          trailing: SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'es', label: Text('ES')), ButtonSegment(value: 'en', label: Text('EN'))],
            selected: {app.lang},
            onSelectionChanged: (v) => app.setLang(v.first),
          ),
        ),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.storefront_outlined), title: Text(s.t('restaurants')), onTap: () => context.push('/restaurants')),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.event_seat_outlined), title: Text(s.t('reservations')), onTap: () => context.push('/reservations')),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.privacy_tip_outlined), title: Text(s.t('privacy')), onTap: () => launchUrl(Uri.parse('${AppConfig.websiteUrl}/privacidad'), mode: LaunchMode.externalApplication)),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.gavel_outlined), title: Text(s.t('legal')), onTap: () => launchUrl(Uri.parse('${AppConfig.websiteUrl}/aviso-legal'), mode: LaunchMode.externalApplication)),
        if (user != null) ...[
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.logout), title: Text(s.t('logout')), onTap: () => app.logout()),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.delete_outline, color: Brand.tomatoDark), title: Text(s.t('deleteAccount'), style: const TextStyle(color: Brand.tomatoDark)), onTap: () => _delete(context)),
        ],
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
