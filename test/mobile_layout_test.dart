import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:la_toscana_customer/core/api.dart';
import 'package:la_toscana_customer/core/i18n.dart';
import 'package:la_toscana_customer/core/models.dart';
import 'package:la_toscana_customer/core/theme.dart';
import 'package:la_toscana_customer/screens/home_screen.dart';
import 'package:la_toscana_customer/screens/menu_screen.dart';
import 'package:la_toscana_customer/screens/reservation_screen.dart';
import 'package:la_toscana_customer/screens/restaurants_screen.dart';
import 'package:la_toscana_customer/state/app_state.dart';
import 'package:la_toscana_customer/state/cart.dart';
import 'package:la_toscana_customer/state/favorites.dart';
import 'package:la_toscana_customer/widgets/common.dart';

class _BookingApi extends Api {
  _BookingApi(super.tokens);
  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async =>
      <String, dynamic>{
            'slots': [
              {'time': '19:30', 'available': true},
              {'time': '20:00', 'available': false},
            ],
          }
          as T;
}

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('Mobile layout at $width with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final tokens = TokenStore();
        final api = _BookingApi(tokens);
        final app = AppState(api, tokens)..loading = false;
        app.branches = [
          Branch.fromJson({
            'id': 'branch',
            'slug': 'barbastro',
            'name': 'La Toscana Barbastro',
            'address': {'line1': 'Avenida del Cinca 40', 'city': 'Barbastro'},
            'contact': {'phone': '+34 974 09 22 86'},
            'reservations': {'enabled': true, 'maxPartySize': 8},
            'hoursVerified': true,
            'hours': [
              {
                'day': 1,
                'intervals': [
                  {'open': '13:00', 'close': '23:00'},
                ],
              },
            ],
          }),
        ];
        final item = MenuItem.fromJson({
          'id': 'pizza',
          'name': 'Pizza Toscana con mozzarella',
          'description': 'Tomato, fresh mozzarella and basil.',
          'priceCents': 1290,
        });
        app.menu = Menu(null, null, [
          MenuCategory('pizza', 'Our handmade pizzas', null, null, [item]),
        ]);
        Widget wrap(Widget child) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: app),
            ChangeNotifierProvider(create: (_) => CartStore()),
            ChangeNotifierProvider(create: (_) => FavoritesStore()),
            Provider<Api>.value(value: api),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            locale: const Locale('en'),
            localizationsDelegates: const [
              SDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: child,
          ),
        );
        await tester.pumpWidget(wrap(const HomeScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(wrap(Scaffold(body: ItemTile(item: item))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(AddButton)).width,
          greaterThanOrEqualTo(48),
        );
        await tester.pumpWidget(
          wrap(
            Scaffold(
              // One column of the home screen's two-column dish grid.
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: (width - 44) / 2, child: ProductCard(item: item)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(wrap(const MenuScreen()));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'not-a-dish');
        await tester.pumpAndSettle();
        expect(find.byType(ItemTile), findsNothing);
        await tester.tap(find.byTooltip('Clear search'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(ItemTile),
          200,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.byType(ItemTile), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(wrap(const RestaurantsScreen()));
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(
          tester.element(find.text('Opening hours')),
          alignment: 0.2,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Opening hours'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(wrap(const ReservationScreen()));
        await tester.pumpAndSettle();
        // Sections below the header are built lazily; scroll the form until the time slot exists.
        await tester.scrollUntilVisible(
          find.text('19:30'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Select time'), findsOneWidget);
        await Scrollable.ensureVisible(
          tester.element(find.text('19:30')),
          alignment: 0.2,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('19:30'));
        await tester.pumpAndSettle();
        expect(find.textContaining('19:30'), findsWidgets);
        expect(
          tester
              .widget<ChoiceChip>(
                find.ancestor(
                  of: find.text('19:30'),
                  matching: find.byType(ChoiceChip),
                ),
              )
              .selected,
          isTrue,
        );
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });
    }
  }
}
