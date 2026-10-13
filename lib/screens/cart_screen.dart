import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../state/cart.dart';
import '../widgets/common.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cart = context.watch<CartStore>();
    final app = context.watch<AppState>();
    final branch = app.branches.where((b) => b.slug == cart.branchSlug).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('cart'))),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: s.t('emptyCart'),
              body: s.t('cartHint'),
              action: FilledButton.icon(onPressed: () => context.go('/menu'), icon: const Icon(Icons.local_pizza_outlined), label: Text(s.t('seeMenu'))),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (branch != null) ...[
                  SoftCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => context.push('/select'),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: Brand.tomatoSoft, borderRadius: BorderRadius.circular(12)),
                        child: Icon(app.mode == 'delivery' ? Icons.delivery_dining_outlined : Icons.storefront_outlined, color: Brand.tomato, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.t(app.mode == 'delivery' ? 'deliveryFrom' : 'pickupAt'), style: const TextStyle(color: Brand.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(branch.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: Brand.muted),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final l in cart.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftCard(
                      padding: const EdgeInsets.all(10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(width: 72, height: 72, child: DishImage(url: l.imageUrl, radius: 12, showLabel: false)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            if (l.optionLabels.isNotEmpty)
                              Padding(padding: const EdgeInsets.only(top: 2), child: Text(l.optionLabels.join(' · '), style: const TextStyle(color: Brand.muted, fontSize: 12.5, height: 1.35))),
                            if (l.notes != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(children: [
                                  const Icon(Icons.edit_note, size: 15, color: Brand.warning),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(l.notes!, style: const TextStyle(color: Brand.warning, fontSize: 12))),
                                ]),
                              ),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: Text(eur(l.unitPriceCents * l.quantity, app.lang), style: Brand.price)),
                              _QtyControl(
                                quantity: l.quantity,
                                onMinus: () => cart.setQuantity(l.key, l.quantity - 1),
                                onPlus: () => cart.setQuantity(l.key, l.quantity + 1),
                              ),
                            ]),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                const SizedBox(height: 6),
                TextButton.icon(onPressed: () => context.go('/menu'), icon: const Icon(Icons.add), label: Text(s.t('seeMenu'))),
                const SizedBox(height: 6),
                SoftCard(
                  child: Column(children: [
                    Row(children: [
                      Text(s.t('subtotal'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(eur(cart.subtotalCents, app.lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.info_outline, size: 14, color: Brand.hint),
                      const SizedBox(width: 6),
                      Expanded(child: Text(s.t('finalTotalNote'), style: const TextStyle(color: Brand.muted, fontSize: 12))),
                    ]),
                  ]),
                ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : BottomActionBar(
              child: FilledButton(
                onPressed: () => context.push('/checkout'),
                child: Row(children: [
                  Text(s.t('checkout')),
                  const Spacer(),
                  Text(eur(cart.subtotalCents, app.lang)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 18),
                ]),
              ),
            ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({required this.quantity, required this.onMinus, required this.onPlus});
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Brand.cream, borderRadius: BorderRadius.circular(999), border: Border.all(color: Brand.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _btn(quantity == 1 ? Icons.delete_outline : Icons.remove, '-1', onMinus, quantity == 1 ? Brand.tomatoDark : Brand.charcoal),
          SizedBox(width: 24, child: Text('$quantity', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))),
          _btn(Icons.add, '+1', onPlus, Brand.tomato),
        ]),
      );

  Widget _btn(IconData icon, String tip, VoidCallback onTap, Color color) => Tooltip(
        message: tip,
        child: InkResponse(onTap: onTap, radius: 20, child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, size: 18, color: color))),
      );
}
