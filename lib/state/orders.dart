import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Orders placed from this device (id + tracking token), so guests can reopen their tracking screen.
/// Tokens only grant read/cancel access to that one order.
class TrackedOrders extends ChangeNotifier {
  static const _key = 'lt_tracked_orders_v1';
  final List<({String id, String token, String number, DateTime at})> items = [];

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) return;
      items
        ..clear()
        ..addAll((jsonDecode(raw) as List).map((e) {
          final m = (e as Map).cast<String, dynamic>();
          return (id: m['id'] as String, token: m['token'] as String, number: m['number'] as String, at: DateTime.parse(m['at'] as String));
        }));
      notifyListeners();
    } catch (_) {}
  }

  String? tokenFor(String id) => items.where((o) => o.id == id).firstOrNull?.token;

  Future<void> add(String id, String token, String number) async {
    items.removeWhere((o) => o.id == id);
    items.insert(0, (id: id, token: token, number: number, at: DateTime.now()));
    if (items.length > 20) items.removeRange(20, items.length);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(items.map((o) => {'id': o.id, 'token': o.token, 'number': o.number, 'at': o.at.toIso8601String()}).toList()));
  }
}
