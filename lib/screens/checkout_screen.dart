import 'dart:async';

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
import '../state/cart.dart';
import '../state/orders.dart';
import '../widgets/common.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  final _line1 = TextEditingController();
  final _postcode = TextEditingController();
  final _city = TextEditingController();
  final _coupon = TextEditingController();
  String? _appliedCoupon;
  String _ifSoldOut = 'contact';
  bool _terms = false;
  String _when = 'asap';
  DateTime? _slot;
  Slots? _slots;
  Quote? _quote;
  Object? _quoteError;
  bool _submitting = false;
  String? _idemKey;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    _name.text = u?.name ?? '';
    _phone.text = u?.phone ?? '';
    _email.text = u?.email ?? '';
    _loadSlots();
    _requote();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_name, _phone, _email, _notes, _line1, _postcode, _city, _coupon]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _type => context.read<AppState>().mode == 'delivery' && (context.read<AppState>().branch?.delivery ?? false) ? 'delivery' : 'pickup';

  Map<String, dynamic> _fulfilment() => {
        'type': _type,
        if (_type == 'delivery' && RegExp(r'^\d{5}$').hasMatch(_postcode.text.trim()) && _line1.text.trim().length >= 3)
          'address': {'line1': _line1.text.trim(), 'postcode': _postcode.text.trim(), 'city': _city.text.trim()},
        if (_when == 'later' && _slot != null) 'scheduledFor': _slot!.toUtc().toIso8601String(),
      };

  Future<void> _loadSlots() async {
    final cart = context.read<CartStore>();
    if (cart.branchSlug == null) return;
    try {
      final r = await context.read<Api>().get<Map<String, dynamic>>('/api/v1/orders/slots', query: {'branchId': cart.branchSlug, 'days': 3});
      final sl = Slots.fromJson(r);
      if (!mounted) return;
      setState(() {
        _slots = sl;
        if (!sl.asap && sl.scheduling && sl.days.isNotEmpty) {
          _when = 'later';
          _slot = sl.days.first.slots.first;
        }
      });
      _requote();
    } catch (_) {/* quote still reports closed/disabled */}
  }

  void _requote() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final cart = context.read<CartStore>();
      if (cart.isEmpty || cart.branchSlug == null) return;
      try {
        final r = await context.read<Api>().post<Map<String, dynamic>>('/api/v1/orders/quote', body: {
          'branchId': cart.branchSlug,
          'fulfilment': _fulfilment(),
          'lines': cart.toApiLines(),
          if (_appliedCoupon != null) 'couponCode': _appliedCoupon,
          'lang': context.read<AppState>().lang,
        });
        if (mounted) {
          setState(() {
            _quote = Quote.fromJson((r['quote'] as Map).cast<String, dynamic>());
            _quoteError = null;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _quoteError = e);
      }
    });
  }

  Future<void> _place() async {
    final s = S.of(context);
    if (!_form.currentState!.validate()) return;
    if (!_terms) return showSnack(context, s.t('terms'), error: true);
    if (_quote?.ok != true) return showSnack(context, _quote?.errors.map((e) => s.error(e.code)).toSet().join(' ') ?? s.t('error'), error: true);
    setState(() => _submitting = true);
    _idemKey ??= newIdempotencyKey(); // same key on retry → never a second order
    final cart = context.read<CartStore>();
    try {
      final r = await context.read<Api>().post<Map<String, dynamic>>('/api/v1/orders', idempotencyKey: _idemKey, body: {
        'branchId': cart.branchSlug,
        'fulfilment': _fulfilment(),
        'lines': cart.toApiLines(),
        if (_appliedCoupon != null) 'couponCode': _appliedCoupon,
        'lang': context.read<AppState>().lang,
        'customer': {'name': _name.text.trim(), 'phone': _phone.text.trim(), if (_email.text.trim().isNotEmpty) 'email': _email.text.trim()},
        'paymentMethod': 'cash',
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
        'ifSoldOut': _ifSoldOut,
        'acceptTerms': true,
      });
      final order = (r['order'] as Map).cast<String, dynamic>();
      if (!mounted) return;
      await context.read<TrackedOrders>().add('${order['id']}', '${r['trackingToken']}', '${order['number']}');
      cart.clear();
      if (mounted) context.go('/order/${order['id']}');
    } catch (e) {
      _idemKey = null;
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e is ApiException && e.code == 'ORDER_INVALID') {
        final errs = ((e.details as Map?)?['errors'] as List? ?? const []).map((x) => s.error('${(x as Map)['code']}')).toSet();
        showSnack(context, errs.join(' '), error: true);
      } else {
        showSnack(context, apiErrorText(context, e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final cart = context.watch<CartStore>();
    final branch = app.branches.where((b) => b.slug == cart.branchSlug).firstOrNull;
    final q = _quote;
    final blocking = q?.errors.where((e) => const ['BRANCH_CLOSED', 'ORDERING_DISABLED', 'ORDERING_PAUSED'].contains(e.code)).toList() ?? const [];
    final daySlots = _slots?.days.where((d) => _slot != null && d.slots.contains(_slot)).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('checkout'))),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (branch != null) Text('${s.t(_type == 'delivery' ? 'deliveryFrom' : 'pickupAt')} ${branch.name}\n${branch.address}', style: const TextStyle(fontWeight: FontWeight.w600)),
          if (blocking.isNotEmpty) _Box(text: blocking.map((e) => s.error(e.code)).toSet().join(' '), danger: true),
          if (_quoteError != null) _Box(text: apiErrorText(context, _quoteError!), danger: true),
          _Section(s.t('when')),
          RadioGroup<String>(
            groupValue: _when,
            onChanged: (v) => setState(() {
              _when = v!;
              if (_when == 'later' && _slot == null && (_slots?.days.isNotEmpty ?? false)) _slot = _slots!.days.first.slots.first;
              _requote();
            }),
            child: Column(children: [
              RadioListTile<String>(value: 'asap', enabled: _slots?.asap ?? true, title: Text(s.t('asap')), subtitle: _slots != null && !_slots!.asap ? Text(s.t('asapClosed')) : null),
              if (_slots?.scheduling ?? false) RadioListTile<String>(value: 'later', enabled: _slots!.days.isNotEmpty, title: Text(s.t('later'))),
            ]),
          ),
          if (_when == 'later' && _slots != null)
            _slots!.days.isEmpty
                ? Text(s.t('noSlots'))
                : Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: daySlots?.date,
                        decoration: InputDecoration(labelText: s.t('day')),
                        items: [for (final d in _slots!.days) DropdownMenuItem(value: d.date, child: Text(dayLabel(d.slots.first, app.lang)))],
                        onChanged: (v) {
                          setState(() => _slot = _slots!.days.firstWhere((d) => d.date == v).slots.first);
                          _requote();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<DateTime>(
                        key: ValueKey(daySlots?.date),
                        initialValue: _slot,
                        decoration: InputDecoration(labelText: s.t('time')),
                        items: [for (final t in daySlots?.slots ?? const <DateTime>[]) DropdownMenuItem(value: t, child: Text(hhmm(t)))],
                        onChanged: (v) {
                          setState(() => _slot = v);
                          _requote();
                        },
                      ),
                    ),
                  ]),
          if (_when == 'asap' && q?.estimatedReadyAt != null) Padding(padding: const EdgeInsets.only(left: 16), child: Text('${s.t('eta')}: ${hhmm(q!.estimatedReadyAt!)}', style: const TextStyle(color: Brand.muted))),
          _Section(s.t('yourDetails')),
          TextFormField(controller: _name, decoration: InputDecoration(labelText: s.t('name')), textCapitalization: TextCapitalization.words, validator: (v) => (v ?? '').trim().length < 2 ? s.t('name') : null),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phone,
            decoration: InputDecoration(labelText: s.t('phone')),
            keyboardType: TextInputType.phone,
            validator: (v) => RegExp(r'^\+?[0-9 ]{9,16}$').hasMatch((v ?? '').trim()) ? null : s.t('phone'),
          ),
          const SizedBox(height: 10),
          TextFormField(controller: _email, decoration: InputDecoration(labelText: s.t('email')), keyboardType: TextInputType.emailAddress, validator: (v) => (v ?? '').isEmpty || RegExp(r'^\S+@\S+\.\S+$').hasMatch(v!.trim()) ? null : s.t('email')),
          if (_type == 'delivery') ...[
            const SizedBox(height: 10),
            TextFormField(controller: _line1, decoration: InputDecoration(labelText: s.t('address')), onChanged: (_) => _requote(), validator: (v) => (v ?? '').trim().length < 3 ? s.t('address') : null),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(controller: _postcode, decoration: InputDecoration(labelText: s.t('postcode')), keyboardType: TextInputType.number, maxLength: 5, onChanged: (_) => _requote(), validator: (v) => RegExp(r'^\d{5}$').hasMatch((v ?? '').trim()) ? null : s.t('postcode'))),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _city, decoration: InputDecoration(labelText: s.t('city')), validator: (v) => (v ?? '').trim().length < 2 ? s.t('city') : null)),
            ]),
          ],
          const SizedBox(height: 10),
          TextFormField(controller: _notes, decoration: InputDecoration(labelText: s.t('notes')), maxLength: 500, maxLines: 2),
          DropdownButtonFormField<String>(
            initialValue: _ifSoldOut,
            decoration: InputDecoration(labelText: s.t('ifSoldOut')),
            items: [for (final k in ['contact', 'substitute', 'refund_item', 'cancel_order']) DropdownMenuItem(value: k, child: Text(s.t('ifSoldOut.$k')))],
            onChanged: (v) => setState(() => _ifSoldOut = v!),
          ),
          _Section(s.t('coupon')),
          Row(children: [
            Expanded(child: TextField(controller: _coupon, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: s.t('coupon'), isDense: true))),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final code = _coupon.text.trim().toUpperCase();
                setState(() => _appliedCoupon = code.isEmpty ? null : code);
                _requote();
              },
              child: Text(s.t('apply')),
            ),
          ]),
          if (q != null && q.errors.any((e) => e.code.startsWith('COUPON'))) _Box(text: s.error('COUPON_INVALID'), danger: true),
          _Section(s.t('payment')),
          Card(child: ListTile(leading: const Icon(Icons.payments_outlined, color: Brand.tomato), title: Text(s.t('cash')), subtitle: Text(s.t('cashHint')), trailing: const Icon(Icons.check_circle, color: Brand.basil))),
          if (q?.card ?? false) Padding(padding: const EdgeInsets.only(top: 6), child: Text(s.t('cardUnavailable'), style: const TextStyle(color: Brand.muted, fontSize: 12))),
          Text(s.t('bizum'), style: const TextStyle(color: Brand.muted, fontSize: 12)),
          _Section(s.t('total')),
          if (q != null) ...[
            _Row(s.t('subtotal'), eur(q.subtotalCents, app.lang)),
            if (q.discountCents > 0) _Row('${s.t('discount')}${q.couponCode != null ? ' (${q.couponCode})' : ''}', '−${eur(q.discountCents, app.lang)}'),
            if (q.deliveryFeeCents > 0) _Row(s.t('deliveryFee'), eur(q.deliveryFeeCents, app.lang)),
            _Row(s.t('total'), eur(q.totalCents, app.lang), bold: true),
            _Row(s.t('vat'), eur(q.taxCents, app.lang)),
          ] else
            const LinearProgressIndicator(),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(s.t('terms'), style: const TextStyle(fontSize: 13)),
            subtitle: GestureDetector(
              onTap: () => launchUrl(Uri.parse('${AppConfig.websiteUrl}/condiciones'), mode: LaunchMode.externalApplication),
              child: Text(s.t('readTerms'), style: const TextStyle(color: Brand.tomatoDark, decoration: TextDecoration.underline, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 80),
        ]),
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _submitting || q == null || !q.ok ? null : _place,
          child: _submitting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text('${s.t('placeOrder')}${q != null ? ' · ${eur(q.totalCents, app.lang)}' : ''}'),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 22, bottom: 8), child: Text(title, style: Brand.h3));
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;
  @override
  Widget build(BuildContext context) {
    final st = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400, fontSize: bold ? 17 : 14);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text(label, style: st)), Text(value, style: st)]));
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.text, this.danger = false});
  final String text;
  final bool danger;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: danger ? Brand.tomatoSoft : Brand.warningSoft, borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(danger ? Icons.error_outline : Icons.info_outline, size: 18, color: danger ? Brand.tomatoDark : Brand.warning),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: danger ? Brand.tomatoDark : Brand.warning, height: 1.4))),
        ]),
      );
}
