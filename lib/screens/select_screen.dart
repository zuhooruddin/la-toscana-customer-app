import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/i18n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../state/cart.dart';
import '../widgets/common.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(children: [
            Expanded(child: _ModeCard(icon: Icons.storefront_outlined, label: s.t('pickup'), selected: _mode == 'pickup', onTap: () => setState(() => _mode = 'pickup'))),
            const SizedBox(width: 10),
            Expanded(child: _ModeCard(icon: Icons.delivery_dining_outlined, label: s.t('delivery'), selected: _mode == 'delivery', onTap: () => setState(() => _mode = 'delivery'))),
          ]),
          if (_mode == 'delivery' && selected != null && !deliveryOk)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Pill(text: s.t('deliveryUnavailable'), icon: Icons.info_outline, color: Brand.tomatoDark, background: Brand.tomatoSoft),
            ),
          const SizedBox(height: 22),
          Text(s.t('restaurants'), style: Brand.h2),
          const SizedBox(height: 10),
          for (final b in app.branches)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                padding: const EdgeInsets.all(14),
                borderColor: b.slug == _slug ? Brand.tomato : null,
                onTap: () => setState(() => _slug = b.slug),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: b.slug == _slug ? Brand.tomato : Brand.tomatoSoft, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.local_pizza_outlined, color: b.slug == _slug ? Colors.white : Brand.tomato),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(b.address, style: const TextStyle(color: Brand.muted, fontSize: 13, height: 1.35)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        BranchStatusPill(branch: b, label: orderingLabel(s, b)),
                        if (b.delivery) Pill(text: s.t('delivery'), icon: Icons.delivery_dining_outlined, color: Brand.charcoal, background: Brand.cream2),
                      ]),
                    ]),
                  ),
                  Icon(b.slug == _slug ? Icons.radio_button_checked : Icons.radio_button_off, color: b.slug == _slug ? Brand.tomato : Brand.hint),
                ]),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
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
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? Brand.tomato : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? Brand.tomato : Brand.border),
            boxShadow: selected ? Brand.shadowPrimary : Brand.shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  Icon(icon, color: selected ? Colors.white : Brand.tomato, size: 26),
                  const SizedBox(height: 6),
                  Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: selected ? Colors.white : Brand.charcoal)),
                ]),
              ),
            ),
          ),
        ),
      );
}
