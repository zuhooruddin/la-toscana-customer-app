import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dishes the customer hearted. Stored on the device only (no account needed).
class FavoritesStore extends ChangeNotifier {
  static const _key = 'lt_favorites_v1';
  final Set<String> ids = {};

  bool contains(String itemId) => ids.contains(itemId);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      ids
        ..clear()
        ..addAll(p.getStringList(_key) ?? const []);
      notifyListeners();
    } catch (_) {
      // Unreadable storage: start with no favourites.
    }
  }

  Future<void> toggle(String itemId) async {
    if (!ids.remove(itemId)) ids.add(itemId);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, ids.toList());
  }
}
