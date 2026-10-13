import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final mapBranch = selected ?? app.branches.firstOrNull;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 8,
          16,
          24,
        ),
        children: [
          ItalianHeaderBackdrop(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    s.t('chooseRestaurant'),
                    style: Brand.h1.copyWith(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    s.t('selectSubtitle'),
                    style: const TextStyle(color: Brand.muted, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ModeCard(
                    icon: Icons.storefront_rounded,
                    label: s.t('pickup'),
                    body: s.t('pickupBody'),
                    selected: _mode == 'pickup',
                    onTap: () => setState(() => _mode = 'pickup'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.delivery_dining_rounded,
                    label: s.t('delivery'),
                    body: s.t('deliveryBody'),
                    selected: _mode == 'delivery',
                    onTap: () => setState(() => _mode = 'delivery'),
                  ),
                ),
              ],
            ),
          ),
          if (_mode == 'delivery' && selected != null && !deliveryOk)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Brand.tomatoSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_rounded,
                    color: Brand.tomato,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t('deliveryUnavailable'),
                          style: const TextStyle(
                            color: Brand.tomatoDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.t('deliveryUnavailableBody'),
                          style: const TextStyle(
                            color: Brand.muted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 26),
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(child: Text(s.t('restaurants'), style: Brand.h1)),
              if (mapBranch != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    elevation: 1,
                    shadowColor: Colors.black26,
                  ),
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(mapBranch.lat != null ? '${mapBranch.lat},${mapBranch.lng}' : '${mapBranch.address}, España')}',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.location_on_rounded, size: 20),
                  label: Text(s.t('viewOnMap')),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final b in app.branches)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BranchCard(
                branch: b,
                delivery: _mode == 'delivery',
                selected: b.slug == _slug,
                onTap: () => setState(() => _slug = b.slug),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontFamily: Brand.body,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            onPressed: _slug == null || (_mode == 'delivery' && !deliveryOk)
                ? null
                : () async {
                    final cart = context.read<CartStore>();
                    if (cart.branchSlug != null &&
                        cart.branchSlug != _slug &&
                        !cart.isEmpty) {
                      cart.clear();
                    }
                    await context.read<AppState>().selectBranch(_slug!, _mode);
                    if (context.mounted) {
                      context.canPop() ? context.pop() : context.go('/menu');
                    }
                  },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    selected == null
                        ? s.t('select')
                        : s
                              .t('selectBranch')
                              .replaceAll('{name}', selected.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.body,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String body;
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? Brand.tomato : Brand.border),
        boxShadow: selected ? Brand.shadowPrimary : Brand.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 10, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.14)
                        : Brand.tomatoSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : Brand.tomato,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: selected ? Colors.white : Brand.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: selected ? Colors.white : Brand.muted,
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
  );
}

/// Restaurant row: photo, name, address, ordering state and which services it offers.
class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.delivery,
    required this.selected,
    required this.onTap,
  });
  final Branch branch;

  /// Delivery mode: restaurants that don't deliver say so instead of listing their services.
  final bool delivery;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final b = branch;
    Widget service(IconData icon, String label, bool on) => Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
      decoration: BoxDecoration(
        color: on ? Brand.tomatoSoft : Brand.cream2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: on ? Brand.charcoal : Brand.muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: on ? Brand.charcoal : Brand.muted,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            on ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: on ? Brand.tomato : Brand.hint,
          ),
        ],
      ),
    );
    return Semantics(
      selected: selected,
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        radius: 20,
        borderColor: selected ? Brand.tomato : null,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, c) {
            final photo = (c.maxWidth * 0.28).clamp(80.0, 120.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: photo,
                  height: photo * 1.05,
                  child: DishImage(
                    url: b.imageUrl,
                    radius: 14,
                    showLabel: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(b.name, style: Brand.h3)),
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected ? Brand.tomato : Brand.hint,
                            size: 26,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Brand.muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              b.address,
                              style: const TextStyle(
                                color: Brand.muted,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      BranchStatusPill(branch: b, label: orderingLabel(s, b)),
                      const SizedBox(height: 8),
                      if (delivery && !b.delivery)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          decoration: BoxDecoration(
                            color: Brand.tomatoSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delivery_dining_rounded,
                                color: Brand.tomato,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.t('deliveryNotAvailable'),
                                      style: const TextStyle(
                                        color: Brand.tomatoDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      s.t('deliveryNotAvailableBody'),
                                      style: const TextStyle(
                                        color: Brand.muted,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  service(
                                    Icons.restaurant_rounded,
                                    s.t('pickup'),
                                    b.pickup,
                                  ),
                                  service(
                                    Icons.delivery_dining_rounded,
                                    s.t('delivery'),
                                    b.delivery,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: s.t('restaurants'),
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(36, 40),
                              ),
                              onPressed: () => context.push('/restaurants'),
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                color: Brand.muted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
