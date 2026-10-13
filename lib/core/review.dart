import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Store rating prompt, shown only at a happy moment and rarely:
///  * after an order is completed (delivered / picked up), counted once per order;
///  * from the 2nd completed order on;
///  * at most once every 120 days and 3 times in total (Apple also caps it at 3 prompts / 365 days and may show
///    nothing at all — the API never tells us, so we never ask "did you rate us?").
class ReviewPrompt {
  static const _orders = 'lt_review_completed_orders';
  static const _last = 'lt_review_last_prompt';
  static const _count = 'lt_review_prompts';
  static const minOrders = 2;
  static const minDaysBetween = 120;
  static const maxPrompts = 3;

  /// Pure rule, unit-tested.
  static bool shouldAsk({required int completedOrders, required DateTime? lastPrompt, required int prompts, required DateTime now}) =>
      completedOrders >= minOrders && prompts < maxPrompts && (lastPrompt == null || now.difference(lastPrompt).inDays >= minDaysBetween);

  static Future<void> onOrderCompleted(String orderId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final seen = p.getStringList(_orders) ?? const [];
      if (seen.contains(orderId)) return;
      final orders = [...seen, orderId];
      await p.setStringList(_orders, orders.length > 50 ? orders.sublist(orders.length - 50) : orders);
      final last = p.getString(_last);
      final prompts = p.getInt(_count) ?? 0;
      final now = DateTime.now();
      if (!shouldAsk(completedOrders: orders.length, lastPrompt: last == null ? null : DateTime.tryParse(last), prompts: prompts, now: now)) return;
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await p.setString(_last, now.toIso8601String());
      await p.setInt(_count, prompts + 1);
      await review.requestReview();
    } catch (_) {
      // Never let a rating prompt break order tracking.
    }
  }

  /// "Rate the app" from the account screen: opens the store listing (App Store id from admin → settings → apps).
  static Future<void> openStore({String? appStoreUrl}) async {
    final id = RegExp(r'/id(\d{6,})').firstMatch(appStoreUrl ?? '')?.group(1);
    await InAppReview.instance.openStoreListing(appStoreId: id);
  }
}
