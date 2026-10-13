import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api.dart';
import 'state/app_state.dart';
import 'state/cart.dart';
import 'state/favorites.dart';
import 'state/orders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStore();
  final api = Api(tokens);
  final app = AppState(api, tokens);
  final cart = CartStore();
  final tracked = TrackedOrders();
  final favorites = FavoritesStore();
  await Future.wait([cart.load(), tracked.load(), favorites.load()]);
  // Data loads in the background; screens show progress and a retry on failure.
  app.init();
  runApp(MultiProvider(
    providers: [
      Provider.value(value: api),
      ChangeNotifierProvider.value(value: app),
      ChangeNotifierProvider.value(value: cart),
      ChangeNotifierProvider.value(value: tracked),
      ChangeNotifierProvider.value(value: favorites),
    ],
    child: const LaToscanaApp(),
  ));
}
