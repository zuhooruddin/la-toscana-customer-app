import 'package:flutter_test/flutter_test.dart';
import 'package:la_toscana_customer/core/links.dart';
import 'package:la_toscana_customer/core/review.dart';

void main() {
  group('App Links → app routes', () {
    DeepLink? map(String url) => appLocationFor(Uri.parse(url));

    test('dish, category, menu', () {
      expect(map('https://www.latoscanapizzeria.es/carta/lambordia')?.location, '/item/lambordia');
      expect(map('https://www.latoscanapizzeria.es/carta/categoria/pizzas-artesanales')?.location, '/menu?cat=pizzas-artesanales');
      expect(map('https://www.latoscanapizzeria.es/carta')?.location, '/menu');
    });
    test('language prefix sets the app language', () {
      final l = map('https://www.latoscanapizzeria.es/en/carta/lambordia');
      expect(l?.location, '/item/lambordia');
      expect(l?.lang, 'en');
      expect(map('https://www.latoscanapizzeria.es/carta')?.lang, 'es');
    });
    test('locations, delivery pages, offers, reservations', () {
      expect(map('https://www.latoscanapizzeria.es/restaurantes/huesca')?.location, '/restaurants');
      expect(map('https://www.latoscanapizzeria.es/pizza-a-domicilio/fraga')?.location, '/restaurants');
      expect(map('https://www.latoscanapizzeria.es/ofertas/pizza10')?.location, '/menu');
      expect(map('https://www.latoscanapizzeria.es/reservas?branch=fraga')?.location, '/reservations?branch=fraga');
    });
    test('order tracking keeps the e-mailed token', () {
      final l = map('https://www.latoscanapizzeria.es/pedido/abc123?t=tok');
      expect(l?.location, '/order/abc123');
      expect(l?.orderToken, 'tok');
    });
    test('unknown web pages fall back to home; in-app routes pass through', () {
      expect(map('https://www.latoscanapizzeria.es/aviso-legal')?.location, '/');
      expect(map('/menu?cat=x'), isNull);
      expect(map('/item/lambordia'), isNull);
    });
    test('share links are the canonical website URLs', () {
      expect(WebLinks.dish('es', 'lambordia'), endsWith('/carta/lambordia'));
      expect(WebLinks.dish('en', 'lambordia'), endsWith('/en/carta/lambordia'));
      expect(WebLinks.home('en'), endsWith('/en'));
    });
  });

  group('review prompt rule', () {
    final now = DateTime(2026, 10, 13);
    test('needs two completed orders', () {
      expect(ReviewPrompt.shouldAsk(completedOrders: 1, lastPrompt: null, prompts: 0, now: now), isFalse);
      expect(ReviewPrompt.shouldAsk(completedOrders: 2, lastPrompt: null, prompts: 0, now: now), isTrue);
    });
    test('rate-limited to every 120 days and 3 prompts', () {
      expect(ReviewPrompt.shouldAsk(completedOrders: 5, lastPrompt: now.subtract(const Duration(days: 30)), prompts: 1, now: now), isFalse);
      expect(ReviewPrompt.shouldAsk(completedOrders: 5, lastPrompt: now.subtract(const Duration(days: 121)), prompts: 1, now: now), isTrue);
      expect(ReviewPrompt.shouldAsk(completedOrders: 9, lastPrompt: null, prompts: 3, now: now), isFalse);
    });
  });
}
