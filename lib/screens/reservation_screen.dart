import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/models.dart';
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
  final _days = ScrollController();
  String? _branch;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  int _party = 2;
  String? _time;
  List<({String time, bool available})>? _slots;
  bool _loadingSlots = false;
  Object? _slotsError;
  int _slotRequest = 0;
  bool _terms = false;
  bool _busy = false;
  String? _done;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final bookable = app.branches.where((b) => b.reservationsEnabled).toList();
    _branch = bookable.any((b) => b.slug == widget.branchSlug)
        ? widget.branchSlug
        : (bookable.any((b) => b.slug == app.branchSlug)
              ? app.branchSlug
              : bookable.firstOrNull?.slug);
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
    _days.dispose();
    super.dispose();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _loadSlots() async {
    if (_branch == null) return;
    final request = ++_slotRequest;
    setState(() => (_loadingSlots = true, _time = null, _slotsError = null));
    try {
      final r = await context.read<Api>().get<Map<String, dynamic>>(
        '/api/v1/reservations/availability',
        query: {'branch': _branch, 'date': _dateStr, 'party': _party},
      );
      if (mounted && request == _slotRequest) {
        setState(
          () => _slots = (r['slots'] as List)
              .map(
                (x) => (
                  time: '${(x as Map)['time']}',
                  available: x['available'] == true,
                ),
              )
              .toList(),
        );
      }
    } catch (error) {
      if (mounted && request == _slotRequest) {
        setState(() => _slotsError = error);
      }
    } finally {
      if (mounted && request == _slotRequest) {
        setState(() => _loadingSlots = false);
      }
    }
  }

  Future<void> _book() async {
    final s = S.of(context);
    if (!_form.currentState!.validate() || _time == null) return;
    if (!_terms) return showSnack(context, s.t('terms'), error: true);
    setState(() => _busy = true);
    try {
      await context.read<Api>().post(
        '/api/v1/reservations',
        body: {
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
        },
      );
      if (mounted) {
        setState(
          () => _done =
              '${DateFormat.yMMMEd(context.read<AppState>().lang).format(_date)} · $_time · $_party',
        );
      }
    } catch (e) {
      if (mounted) showSnack(context, apiErrorText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _bookingDays = 60;
  static const _dayWidth = 54.0;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  void _pickDate(DateTime d) {
    setState(() => _date = d);
    _loadSlots();
  }

  /// Scrolls the day strip so [d] is visible (after choosing it in the calendar).
  void _revealDate(DateTime d) {
    if (!_days.hasClients) return;
    final index = DateUtils.dateOnly(d).difference(_today).inDays;
    _days.animateTo(
      (index *
                  (_dayWidth *
                          MediaQuery.textScalerOf(
                            context,
                          ).scale(1).clamp(1.0, 1.3) +
                      8) -
              16)
          .clamp(0.0, _days.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _chooseBranch(List<Branch> bookable) async {
    final s = S.of(context);
    final slug = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(s.t('selectRestaurant'), style: Brand.h2),
            ),
            for (final b in bookable)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BranchSummary(
                  branch: b,
                  selected: b.slug == _branch,
                  onTap: () => Navigator.pop(context, b.slug),
                ),
              ),
          ],
        ),
      ),
    );
    if (slug == null || slug == _branch) return;
    setState(() {
      _branch = slug;
      _party = _party.clamp(
        1,
        bookable.firstWhere((b) => b.slug == slug).maxPartySize,
      );
    });
    _loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final bookable = app.branches.where((b) => b.reservationsEnabled).toList();
    final branch = bookable.where((b) => b.slug == _branch).firstOrNull;
    final back = Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    );
    if (_done != null) {
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(left: 16, top: 8, child: back),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Brand.basilSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Brand.basil,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.t('booked'),
                        style: Brand.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${branch?.name ?? ''}\n$_done',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Brand.muted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final maxParty = branch?.maxPartySize ?? 8;
    return Scaffold(
      bottomNavigationBar: bookable.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_time != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${DateFormat.MMMEd(app.lang).format(_date)} · $_time · ${_partyLabel(s, _party)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: Brand.body,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        onPressed: _busy || _time == null ? null : _book,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.event_available_rounded,
                                size: 22,
                              ),
                        label: Text(
                          _time == null ? s.t('chooseTime') : s.t('bookTable'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: Brand.muted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.t('confirmedInstantly'),
                            style: const TextStyle(
                              color: Brand.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 8,
            16,
            24,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            ItalianHeaderBackdrop(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(alignment: Alignment.centerLeft, child: back),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t('bookTable').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 2.4,
                            color: Brand.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.t('bookingIntro'),
                          style: Brand.h1.copyWith(fontSize: 34),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.t('bookingBody'),
                          style: const TextStyle(
                            color: Brand.muted,
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (bookable.isEmpty)
              SoftCard(
                child: Text(s.t('bookingsOff'), textAlign: TextAlign.center),
              )
            else ...[
              _BookingSection(
                number: '1',
                title: s.t('selectRestaurant'),
                children: [
                  if (branch != null)
                    _BranchSummary(
                      branch: branch,
                      trailing: bookable.length > 1
                          ? Icons.expand_more_rounded
                          : null,
                      onTap: bookable.length > 1
                          ? () => _chooseBranch(bookable)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _BookingSection(
                number: '2',
                title: s.t('selectDate'),
                action: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Brand.charcoal,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: _today,
                      lastDate: _today.add(
                        const Duration(days: _bookingDays - 1),
                      ),
                      initialDate: _date,
                    );
                    if (d != null) {
                      _pickDate(d);
                      _revealDate(d);
                    }
                  },
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: Brand.tomato,
                    size: 20,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat.yMMMM(app.lang).format(_date),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Brand.tomato,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                children: [
                  SizedBox(
                    // Padding + weekday and month lines + day number.
                    height:
                        18 +
                        MediaQuery.textScalerOf(context).scale(13) * 1.35 * 2 +
                        MediaQuery.textScalerOf(context).scale(18) * 1.3,
                    child: ListView.separated(
                      controller: _days,
                      scrollDirection: Axis.horizontal,
                      itemCount: _bookingDays,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final d = _today.add(Duration(days: i));
                        final on = DateUtils.isSameDay(d, _date);
                        final fg = on ? Colors.white : Brand.charcoal;
                        return Material(
                          color: on ? Brand.tomato : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: on ? Brand.tomato : Brand.border,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _pickDate(d),
                            child: SizedBox(
                              width:
                                  _dayWidth *
                                  MediaQuery.textScalerOf(
                                    context,
                                  ).scale(1).clamp(1.0, 1.3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final (text, style) in [
                                    (
                                      DateFormat.E(app.lang).format(d),
                                      TextStyle(
                                        fontSize: 13,
                                        color: on ? Colors.white : Brand.muted,
                                      ),
                                    ),
                                    (
                                      '${d.day}',
                                      TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: fg,
                                        height: 1.25,
                                      ),
                                    ),
                                    (
                                      DateFormat.MMM(app.lang).format(d),
                                      TextStyle(
                                        fontSize: 13,
                                        color: on ? Colors.white : Brand.muted,
                                      ),
                                    ),
                                  ])
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          text,
                                          maxLines: 1,
                                          style: style,
                                        ),
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
              ),
              const SizedBox(height: 14),
              _BookingSection(
                number: '3',
                title: s.t('selectTime'),
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Brand.tomato,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.t('availableTimes'),
                      style: const TextStyle(color: Brand.muted, fontSize: 13),
                    ),
                  ],
                ),
                children: [
                  if (_loadingSlots)
                    const LinearProgressIndicator()
                  else if (_slotsError != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apiErrorText(context, _slotsError!),
                          style: const TextStyle(color: Brand.tomatoDark),
                        ),
                        TextButton.icon(
                          onPressed: _loadSlots,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(s.t('retry')),
                        ),
                      ],
                    )
                  else if ((_slots ?? const []).isEmpty)
                    Text(
                      s.t('noTimes'),
                      style: const TextStyle(color: Brand.muted),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, c) {
                        // Four per row, three when the text is large.
                        final columns =
                            c.maxWidth /
                                    MediaQuery.textScalerOf(context).scale(1) <
                                250
                            ? 3
                            : 4;
                        final w = (c.maxWidth - 8 * (columns - 1)) / columns;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in _slots!)
                              SizedBox(
                                width: w,
                                child: ChoiceChip(
                                  label: SizedBox(
                                    width: double.infinity,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(t.time),
                                    ),
                                  ),
                                  selected: _time == t.time,
                                  showCheckmark: false,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.white,
                                  disabledColor: Brand.cream2,
                                  labelStyle: TextStyle(
                                    color: _time == t.time
                                        ? Colors.white
                                        : (t.available
                                              ? Brand.charcoal
                                              : Brand.hint),
                                    fontWeight: FontWeight.w700,
                                    decoration: t.available
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                  onSelected: t.available
                                      ? (_) => setState(() => _time = t.time)
                                      : null,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _BookingSection(
                number: '4',
                title: s.t('partySize'),
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey('$_branch-$_party'),
                    initialValue: _party,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.people_outline_rounded),
                    ),
                    items: [
                      for (var n = 1; n <= maxParty; n++)
                        DropdownMenuItem(
                          value: n,
                          child: Text(_partyLabel(s, n)),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() => _party = v!);
                      _loadSlots();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _BookingSection(
                number: '5',
                title: s.t('contactDetails'),
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final name = TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: s.t('fullName'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) =>
                            (v ?? '').trim().length < 2 ? s.t('name') : null,
                      );
                      final phone = TextFormField(
                        controller: _phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: s.t('phone'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            RegExp(
                              r'^\+?[0-9 ]{9,16}$',
                            ).hasMatch((v ?? '').trim())
                            ? null
                            : s.t('phone'),
                      );
                      // Name and phone side by side when there is room.
                      return c.maxWidth /
                                  MediaQuery.textScalerOf(context).scale(1) >=
                              330
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: name),
                                const SizedBox(width: 10),
                                Expanded(child: phone),
                              ],
                            )
                          : Column(
                              children: [
                                name,
                                const SizedBox(height: 10),
                                phone,
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _email,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: s.t('email'),
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notes,
                    decoration: InputDecoration(
                      hintText: s.t('specialRequests'),
                      prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                    ),
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 3,
                  ),
                  CheckboxListTile(
                    value: _terms,
                    onChanged: (v) => setState(() => _terms = v ?? false),
                    title: Text(
                      s.t('terms'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _partyLabel(S s, int n) =>
      n == 1 ? s.t('onePerson') : s.t('peopleN').replaceAll('{n}', '$n');
}

/// Restaurant photo, name and address; optionally tappable (choose another restaurant).
class _BranchSummary extends StatelessWidget {
  const _BranchSummary({
    required this.branch,
    this.onTap,
    this.trailing,
    this.selected = false,
  });
  final Branch branch;
  final VoidCallback? onTap;
  final IconData? trailing;
  final bool selected;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? Brand.tomato : Brand.border,
        width: selected ? 1.6 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 84,
            child: DishImage(url: branch.imageUrl, radius: 0, showLabel: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(branch.name, style: Brand.h3),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Brand.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          branch.address,
                          style: const TextStyle(
                            color: Brand.muted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(trailing, color: Brand.charcoal),
            ),
          if (trailing == null) const SizedBox(width: 12),
        ],
      ),
    ),
  );
}

class _BookingSection extends StatelessWidget {
  const _BookingSection({
    required this.number,
    required this.title,
    required this.children,
    this.action,
  });
  final String number;
  final String title;
  final List<Widget> children;
  final Widget? action;
  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
    radius: 22,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Brand.tomato,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: Brand.h2)),
            if (action != null)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: action,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}
