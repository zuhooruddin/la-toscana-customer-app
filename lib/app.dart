import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/i18n.dart';
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

final _router = GoRouter(
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: s.t('home')),
          NavigationDestination(icon: const Icon(Icons.restaurant_menu_outlined), selectedIcon: const Icon(Icons.restaurant_menu), label: s.t('menu')),
          NavigationDestination(
            icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.shopping_bag_outlined)),
            selectedIcon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.shopping_bag)),
            label: s.t('cart'),
          ),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: s.t('account')),
        ],
      ),
    );
  }
}
