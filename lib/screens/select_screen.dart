import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../state/cart.dart';

String orderingLabel(S s, Branch b) => switch (b.orderingState) {
      'open' => s.t('open'),
      'closed' => b.scheduledOrders ? s.t('scheduleOnly') : s.t('closed'),
      'paused' => s.t('paused'),
      _ => s.t('disabled'),
    };

/// Restaurant + pickup/delivery choice (prices and availability depend on the restaurant).
class SelectScreen extends StatefulWidget {
  const SelectScreen({super.key});
  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  String? _slug;
  String _mode = 'pickup';

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _slug = app.branchSlug;
    _mode = app.mode;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppState>();
    final selected = app.branches.where((b) => b.slug == _slug).firstOrNull;
    final deliveryOk = selected?.delivery ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('chooseRestaurant'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'pickup', label: Text(s.t('pickup')), icon: const Icon(Icons.shopping_bag_outlined)),
              ButtonSegment(value: 'delivery', label: Text(s.t('delivery')), icon: const Icon(Icons.delivery_dining_outlined)),
            ],
            selected: {_mode},
            onSelectionChanged: (v) => setState(() => _mode = v.first),
          ),
          if (_mode == 'delivery' && selected != null && !deliveryOk)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.t('deliveryUnavailable'), style: const TextStyle(color: Brand.tomatoDark))),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: _slug,
            onChanged: (v) => setState(() => _slug = v),
            child: Column(children: [
              for (final b in app.branches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: b.slug == _slug ? Brand.tomato : Brand.border, width: b.slug == _slug ? 2 : 1),
                    ),
                    child: RadioListTile<String>(
                      value: b.slug,
                      title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.address),
                        const SizedBox(height: 4),
                        Text(orderingLabel(s, b), style: TextStyle(color: b.canOrderOnline ? Brand.basil : Brand.muted, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _slug == null || (_mode == 'delivery' && !deliveryOk)
                ? null
                : () async {
                    final cart = context.read<CartStore>();
                    if (cart.branchSlug != null && cart.branchSlug != _slug && !cart.isEmpty) cart.clear();
                    await context.read<AppState>().selectBranch(_slug!, _mode);
                    if (context.mounted) context.canPop() ? context.pop() : context.go('/menu');
                  },
            child: Text(s.t('select')),
          ),
        ),
      ),
    );
  }
}
