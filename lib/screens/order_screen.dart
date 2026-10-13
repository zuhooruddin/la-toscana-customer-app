import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

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

/// Live order tracking: Socket.IO room for this order (guest token or signed-in owner) + REST resync every 30 s.
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  CustomerOrder? _order;
  Object? _error;
  bool _live = false;
  io.Socket? _socket;
  Timer? _poll;
  bool _busy = false;

  String? get _token => context.read<TrackedOrders>().tokenFor(widget.orderId);

  @override
  void initState() {
    super.initState();
    _load();
    _connect();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await context.read<Api>().get<Map<String, dynamic>>('/api/v1/orders/${widget.orderId}', query: {'token': _token});
      if (!mounted) return;
      final o = CustomerOrder.fromJson((r['order'] as Map).cast<String, dynamic>());
      setState(() => (_order = o, _error = null));
      // Opened from an e-mailed link: store the order number next to its token for the "my orders" list.
      final tracked = context.read<TrackedOrders>();
      final token = _token;
      if (token != null && tracked.items.any((t) => t.id == o.id && t.number.isEmpty)) await tracked.add(o.id, token, o.number);
      if (o.status == 'delivered' || o.status == 'picked_up') await ReviewPrompt.onOrderCompleted(o.id);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _connect() {
    final tokens = context.read<Api>().tokens;
    final s = io.io(
      AppConfig.apiUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew() // one manager per screen; a disposed cached manager would never reconnect
          .enableReconnection()
          .setAuth({if (tokens.access != null) 'token': tokens.access})
          .build(),
    );
    // Tokens rotate: send the current one on every reconnection attempt (the room is re-joined in onConnect).
    s.onReconnectAttempt((_) => s.auth = {if (tokens.access != null) 'token': tokens.access});
    s.onConnect((_) {
      s.emitWithAck('join_order', {'orderId': widget.orderId, 'token': _token}, ack: (dynamic a) {
        if (mounted) setState(() => _live = a is Map && a['ok'] == true);
      });
    });
    s.onDisconnect((_) {
      if (mounted) setState(() => _live = false);
    });
    s.on('order.updated', (_) => _load());
    s.connect();
    _socket = s;
  }

  Future<void> _cancel() async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(s.t('cancelConfirm')),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('no'))), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('yes')))],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final tq = _token == null ? '' : '?token=${Uri.encodeQueryComponent(_token!)}';
      await context.read<Api>().post('/api/v1/orders/${widget.orderId}/cancel$tq', body: {});
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, apiErrorText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = context.select<AppState, String>((a) => a.lang);
    final o = _order;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), tooltip: s.t('close'), onPressed: () => context.canPop() ? context.pop() : context.go('/')),
        title: Text(o == null ? s.t('order') : '${s.t('order')} ${o.number}'),
      ),
      body: o == null
          ? (_error != null ? ErrorRetry(error: _error!, onRetry: _load) : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (o.status == 'confirmed' && DateTime.now().difference(o.createdAt).inMinutes < 2)
                  Text(s.t('orderPlaced'), style: Brand.h1.copyWith(color: Brand.basilDark)),
                Row(children: [
                  Expanded(child: Text(o.branchName, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Icon(Icons.circle, size: 10, color: _live ? Colors.green : Brand.muted),
                  const SizedBox(width: 6),
                  Text(_live ? s.t('live') : '—', style: const TextStyle(fontSize: 12, color: Brand.muted)),
                ]),
                const SizedBox(height: 12),
                _Steps(order: o),
                const SizedBox(height: 12),
                if (o.isActive && (o.scheduledFor ?? o.estimatedReadyAt) != null)
                  Text(
                    o.scheduledFor != null ? '${s.t('scheduledFor')}: ${dayLabel(o.scheduledFor!, lang)} ${hhmm(o.scheduledFor!)}' : '${s.t('eta')}: ${hhmm(o.estimatedReadyAt!)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      for (final l in o.lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${l.quantity} × ${l.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                if (l.options.isNotEmpty) Text(l.options.join(' · '), style: const TextStyle(color: Brand.muted, fontSize: 12)),
                              ]),
                            ),
                            Text(eur(l.lineTotalCents, lang)),
                          ]),
                        ),
                      const Divider(),
                      if (o.discountCents > 0) _kv(s.t('discount'), '−${eur(o.discountCents, lang)}'),
                      if (o.deliveryFeeCents > 0) _kv(s.t('deliveryFee'), eur(o.deliveryFeeCents, lang)),
                      _kv(s.t('total'), eur(o.totalCents, lang), bold: true),
                      _kv(s.t('vat'), eur(o.taxCents, lang)),
                      _kv(s.t('payment'), o.paymentMethod == 'cash' ? s.t('cash') : s.t('card')),
                    ]),
                  ),
                ),
                if (o.canCancel) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: _busy ? null : _cancel, child: Text(s.t('cancelOrder'))),
                ],
              ]),
            ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    final st = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [Expanded(child: Text(k, style: st)), Text(v, style: st)]));
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (order.status == 'cancelled' || order.status == 'refunded') {
      return Text(s.t('status.${order.status}'), style: Brand.h2.copyWith(color: Brand.tomatoDark));
    }
    final flow = order.type == 'delivery' ? ['confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered'] : ['confirmed', 'preparing', 'ready', 'picked_up'];
    final idx = flow.indexOf(order.status);
    return Column(children: [
      for (var i = 0; i < flow.length; i++)
        Row(children: [
          Icon(i <= idx ? Icons.check_circle : Icons.radio_button_unchecked, color: i <= idx ? Brand.basil : Brand.border),
          const SizedBox(width: 10),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(s.t('status.${flow[i]}'), style: TextStyle(fontWeight: i == idx ? FontWeight.w800 : FontWeight.w500)))),
          if (order.history[flow[i]] != null) Text(hhmm(order.history[flow[i]]!), style: const TextStyle(color: Brand.muted)),
        ]),
    ]);
  }
}
