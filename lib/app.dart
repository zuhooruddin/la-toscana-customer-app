import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/i18n.dart';
import 'core/links.dart';
import 'core/theme.dart';
import 'screens/account_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/item_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/order_screen.dart';
import 'screens/reservation_screen.dart';
import 'screens/restaurants_screen.dart';
import 'screens/select_screen.dart';
import 'state/app_state.dart';
import 'state/cart.dart';
import 'state/orders.dart';

final _router = GoRouter(
  // App Links / Universal Links deliver website URLs (/carta/…, /en/restaurantes/…, /pedido/{id}?t=…): map them to
  // app routes, adopting the URL's language and remembering e-mailed tracking tokens. In-app routes pass through.
  redirect: (context, state) {
    final link = appLocationFor(state.uri);
    if (link == null) return null;
    final app = context.read<AppState>();
    if (link.lang != null && link.lang != app.lang) Future.microtask(() => app.setLang(link.lang!));
    if (link.orderId != null && link.orderToken != null) {
      final orders = context.read<TrackedOrders>();
      if (orders.tokenFor(link.orderId!) == null) Future.microtask(() => orders.add(link.orderId!, link.orderToken!, ''));
    }
    return link.location;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => _Shell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/menu', builder: (_, s) => MenuScreen(category: s.uri.queryParameters['cat'])),
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      ],
    ),
    GoRoute(path: '/select', builder: (_, _) => const SelectScreen()),
    GoRoute(path: '/item/:id', builder: (_, s) => ItemScreen(itemId: s.pathParameters['id']!)),
    GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
    GoRoute(path: '/order/:id', builder: (_, s) => OrderScreen(orderId: s.pathParameters['id']!)),
    GoRoute(path: '/restaurants', builder: (_, _) => const RestaurantsScreen()),
    GoRoute(path: '/reservations', builder: (_, s) => ReservationScreen(branchSlug: s.uri.queryParameters['branch'])),
    GoRoute(path: '/login', builder: (_, s) => AuthScreen(register: s.uri.queryParameters['mode'] == 'register')),
  ],
);

class LaToscanaApp extends StatelessWidget {
  const LaToscanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.select<AppState, String>((a) => a.lang);
    return MaterialApp.router(
      title: 'La Toscana',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
      locale: Locale(lang),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [SDelegate(), GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.location, required this.child});
  final String location;
  final Widget child;

  static const _tabs = ['/', '/menu', '/cart', '/account'];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final count = context.watch<CartStore>().count;
    final index = _tabs.indexOf(location).clamp(0, 3);
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Brand.border)),
          boxShadow: [BoxShadow(color: Color(0x10663B10), blurRadius: 18, offset: Offset(0, -4))],
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(_tabs[i]),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: s.t('home')),
            NavigationDestination(icon: const Icon(Icons.local_pizza_outlined), selectedIcon: const Icon(Icons.local_pizza), label: s.t('menu')),
            NavigationDestination(
              icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.shopping_bag_outlined)),
              selectedIcon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.shopping_bag)),
              label: s.t('cart'),
            ),
            NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: s.t('account')),
          ],
        ),
      ),
    );
  }
}
