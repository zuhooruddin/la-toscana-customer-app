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
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.shopping_bag_outlined, size: 56, color: Brand.muted),
                const SizedBox(height: 12),
                Text(s.t('emptyCart'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => context.go('/menu'), child: Text(s.t('seeMenu'))),
              ]),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (branch != null) Text('${s.t(app.mode == 'delivery' ? 'deliveryFrom' : 'pickupAt')} ${branch.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (final l in cart.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(width: 64, height: 64, child: DishImage(url: l.imageUrl, radius: 10, showLabel: false)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(l.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (l.optionLabels.isNotEmpty) Text(l.optionLabels.join(' · '), style: const TextStyle(color: Brand.muted, fontSize: 12)),
                              if (l.notes != null) Text(l.notes!, style: const TextStyle(color: Color(0xFF7A4500), fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(eur(l.unitPriceCents * l.quantity, app.lang), style: const TextStyle(color: Brand.tomato, fontWeight: FontWeight.w800)),
                            ]),
                          ),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(tooltip: '-1', icon: Icon(l.quantity == 1 ? Icons.delete_outline : Icons.remove), onPressed: () => cart.setQuantity(l.key, l.quantity - 1)),
                            Text('${l.quantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            IconButton(tooltip: '+1', icon: const Icon(Icons.add), onPressed: () => cart.setQuantity(l.key, l.quantity + 1)),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  Text(s.t('subtotal'), style: const TextStyle(fontSize: 16)),
                  const Spacer(),
                  Text(eur(cart.subtotalCents, app.lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 4),
                Text(app.lang == 'en' ? 'Final total is calculated at checkout.' : 'El total final se calcula al confirmar.', style: const TextStyle(color: Brand.muted, fontSize: 12)),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(onPressed: () => context.push('/checkout'), child: Text('${s.t('checkout')} · ${eur(cart.subtotalCents, app.lang)}')),
              ),
            ),
    );
  }
}
