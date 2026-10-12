import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models.dart';
import 'cart_logic.dart';

class CartLine {
  CartLine({required this.key, required this.itemId, required this.name, required this.imageUrl, required this.unitPriceCents, required this.quantity, required this.options, required this.optionLabels, this.notes});
  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        key: j['key'] as String,
        itemId: j['itemId'] as String,
        name: j['name'] as String,
        imageUrl: j['imageUrl'] as String?,
        unitPriceCents: j['unitPriceCents'] as int,
        quantity: j['quantity'] as int,
        options: (j['options'] as List).map((o) => (o as Map).cast<String, String>()).toList(),
        optionLabels: (j['optionLabels'] as List).cast<String>(),
        notes: j['notes'] as String?,
      );
  final String key;
  final String itemId;
  final String name;
  final String? imageUrl;

  /// Shown only as a guide: the server recomputes every price on quote and order.
  final int unitPriceCents;
  int quantity;
  final List<Map<String, String>> options; // {groupKey, choiceKey}
  final List<String> optionLabels;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'key': key,
        'itemId': itemId,
        'name': name,
        'imageUrl': imageUrl,
        'unitPriceCents': unitPriceCents,
        'quantity': quantity,
        'options': options,
        'optionLabels': optionLabels,
        'notes': notes,
      };
  Map<String, dynamic> toApi() => {'itemId': itemId, 'quantity': quantity, 'options': options, if (notes != null && notes!.isNotEmpty) 'notes': notes};
}

/// Cart for ONE restaurant (prices and availability are per restaurant). Persisted on the device.
class CartStore extends ChangeNotifier {
  static const _key = 'lt_cart_v1';
  String? branchSlug;
  final List<CartLine> lines = [];

  int get count => lines.fold(0, (n, l) => n + l.quantity);
  int get subtotalCents => lines.fold(0, (n, l) => n + l.unitPriceCents * l.quantity);
  bool get isEmpty => lines.isEmpty;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      branchSlug = j['branchSlug'] as String?;
      lines
        ..clear()
        ..addAll((j['lines'] as List).map((l) => CartLine.fromJson((l as Map).cast<String, dynamic>())));
      notifyListeners();
    } catch (_) {
      // Corrupt or old format: start with an empty cart.
    }
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode({'branchSlug': branchSlug, 'lines': lines.map((l) => l.toJson()).toList()}));
  }

  /// Adds a dish; switching restaurant empties the cart first. Returns the line key (same options = same line).
  String add(String branch, MenuItem item, Selection sel, int qty, String? notes) {
    if (branchSlug != branch) {
      lines.clear();
      branchSlug = branch;
    }
    final options = <Map<String, String>>[];
    final labels = <String>[];
    for (final g in item.optionGroups) {
      for (final key in sel[g.key] ?? const <String>[]) {
        options.add({'groupKey': g.key, 'choiceKey': key});
        final c = g.choices.where((c) => c.key == key);
        if (c.isNotEmpty) labels.add(c.first.name);
      }
    }
    final key = '${item.id}|${jsonEncode(options)}|${notes ?? ''}';
    final existing = lines.where((l) => l.key == key);
    if (existing.isNotEmpty) {
      existing.first.quantity = (existing.first.quantity + qty).clamp(1, 50);
    } else {
      lines.add(CartLine(
        key: key,
        itemId: item.id,
        name: item.name,
        imageUrl: item.hasPhoto ? item.imageUrl : null,
        unitPriceCents: unitPrice(item, sel),
        quantity: qty,
        options: options,
        optionLabels: labels,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      ));
    }
    notifyListeners();
    _persist();
    return key;
  }

  void setQuantity(String key, int qty) {
    if (qty <= 0) {
      lines.removeWhere((l) => l.key == key);
    } else {
      for (final l in lines) {
        if (l.key == key) l.quantity = qty.clamp(1, 50);
      }
    }
    notifyListeners();
    _persist();
  }

  void clear() {
    lines.clear();
    notifyListeners();
    _persist();
  }

  List<Map<String, dynamic>> toApiLines() => lines.map((l) => l.toApi()).toList();
}
