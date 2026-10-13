import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key, this.branchSlug});
  final String? branchSlug;
  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  String? _branch;
  DateTime _date = DateTime.now();
  int _party = 2;
  String? _time;
  List<({String time, bool available})>? _slots;
  bool _loadingSlots = false;
  bool _terms = false;
  bool _busy = false;
  String? _done;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final bookable = app.branches.where((b) => b.reservationsEnabled).toList();
    _branch = bookable.any((b) => b.slug == widget.branchSlug) ? widget.branchSlug : (bookable.any((b) => b.slug == app.branchSlug) ? app.branchSlug : bookable.firstOrNull?.slug);
    _name.text = app.user?.name ?? '';
    _phone.text = app.user?.phone ?? '';
    _email.text = app.user?.email ?? '';
    _loadSlots();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _loadSlots() async {
    if (_branch == null) return;
    setState(() => (_loadingSlots = true, _time = null));
    try {
      final r = await context.read<Api>().get<Map<String, dynamic>>('/api/v1/reservations/availability', query: {'branch': _branch, 'date': _dateStr, 'party': _party});
      if (mounted) setState(() => _slots = (r['slots'] as List).map((x) => (time: '${(x as Map)['time']}', available: x['available'] == true)).toList());
    } catch (_) {
      if (mounted) setState(() => _slots = const []);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _book() async {
    final s = S.of(context);
    if (!_form.currentState!.validate() || _time == null) return;
    if (!_terms) return showSnack(context, s.t('terms'), error: true);
    setState(() => _busy = true);
    try {
      await context.read<Api>().post('/api/v1/reservations', body: {
        'branchId': _branch,
        'date': _dateStr,
        'time': _time,
        'partySize': _party,
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
        'lang': context.read<AppState>().lang,
        'acceptTerms': true,
      });
      if (mounted) setState(() => _done = '${DateFormat.yMMMEd(context.read<AppState>().lang).format(_date)} · $_time · $_party');
    } catch (e) {
      if (mounted) showSnack(context, apiErrorText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final bookable = app.branches.where((b) => b.reservationsEnabled).toList();
    final branch = bookable.where((b) => b.slug == _branch).firstOrNull;
    if (_done != null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.t('reservations'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle, color: Brand.basil, size: 64),
              const SizedBox(height: 12),
              Text(s.t('booked'), style: Brand.h2),
              const SizedBox(height: 6),
              Text('${branch?.name ?? ''}\n$_done', textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.t('bookTable'))),
      body: bookable.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(s.t('bookingsOff'), textAlign: TextAlign.center)))
          : Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                DropdownButtonFormField<String>(
                  initialValue: _branch,
                  decoration: InputDecoration(labelText: s.t('restaurants')),
                  items: [for (final b in bookable) DropdownMenuItem(value: b.slug, child: Text(b.name))],
                  onChanged: (v) {
                    setState(() => _branch = v);
                    _loadSlots();
                  },
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(DateFormat.yMMMEd(app.lang).format(_date)),
                      onPressed: () async {
                        final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)), initialDate: _date);
                        if (d != null) {
                          setState(() => _date = d);
                          _loadSlots();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<int>(
                      initialValue: _party,
                      decoration: InputDecoration(labelText: s.t('people')),
                      items: [for (var n = 1; n <= (branch?.maxPartySize ?? 8); n++) DropdownMenuItem(value: n, child: Text('$n'))],
                      onChanged: (v) {
                        setState(() => _party = v!);
                        _loadSlots();
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(s.t('time'), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (_loadingSlots)
                  const LinearProgressIndicator()
                else if ((_slots ?? const []).isEmpty)
                  Text(s.t('noTimes'), style: const TextStyle(color: Brand.muted))
                else
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final t in _slots!) ChoiceChip(label: Text(t.time), selected: _time == t.time, onSelected: t.available ? (_) => setState(() => _time = t.time) : null),
                  ]),
                const SizedBox(height: 16),
                TextFormField(controller: _name, decoration: InputDecoration(labelText: s.t('name')), validator: (v) => (v ?? '').trim().length < 2 ? s.t('name') : null),
                const SizedBox(height: 10),
                TextFormField(controller: _phone, decoration: InputDecoration(labelText: s.t('phone')), keyboardType: TextInputType.phone, validator: (v) => RegExp(r'^\+?[0-9 ]{9,16}$').hasMatch((v ?? '').trim()) ? null : s.t('phone')),
                const SizedBox(height: 10),
                TextFormField(controller: _email, decoration: InputDecoration(labelText: s.t('email')), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                TextFormField(controller: _notes, decoration: InputDecoration(labelText: s.t('notes')), maxLength: 500, maxLines: 2),
                CheckboxListTile(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false), title: Text(s.t('terms'), style: const TextStyle(fontSize: 13)), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
                const SizedBox(height: 8),
                FilledButton(onPressed: _busy || _time == null ? null : _book, child: Text(s.t('book'))),
              ]),
            ),
    );
  }
}
