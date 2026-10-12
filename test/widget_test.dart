import 'package:flutter_test/flutter_test.dart';
import 'package:la_toscana_customer/core/models.dart';
import 'package:la_toscana_customer/state/cart_logic.dart';

MenuItem _pasta() => MenuItem.fromJson({
      'id': 'p1',
      'slug': 'pasta-salmon-noci-crema',
      'kind': 'pasta',
      'name': 'Salmón Noci Crema',
      'priceCents': 1390,
      'optionGroups': [
        {
          'key': 'tipo-pasta',
          'name': 'Tipo de pasta',
          'min': 1,
          'max': 1,
          'required': true,
          'choices': [
            {'key': 'spaguetti', 'name': 'Spaguetti', 'priceDeltaCents': 0},
            {'key': 'capeli-fungi-porcini', 'name': 'Capeli', 'priceDeltaCents': 60},
          ],
        },
      ],
    });

MenuItem _helado() => MenuItem.fromJson({
      'id': 'h1',
      'name': 'Helado',
      'priceCents': 300,
      'optionGroups': [
        {
          'key': 'bolas',
          'name': 'Bolas',
          'min': 1,
          'max': 1,
          'required': true,
          'choices': [
            {'key': '1-bola', 'name': '1 bola', 'priceDeltaCents': 0},
            {'key': '2-bolas', 'name': '2 bolas', 'priceDeltaCents': 200},
          ],
        },
        {
          'key': 'sabor',
          'name': 'Sabor',
          'min': 1,
          'max': 2,
          'required': true,
          'maxByChoice': {'groupKey': 'bolas', 'map': {'1-bola': 1, '2-bolas': 2}},
          'choices': [
            {'key': 'v', 'name': 'Vainilla', 'priceDeltaCents': 0},
            {'key': 'f', 'name': 'Fresa', 'priceDeltaCents': 0},
            {'key': 'c', 'name': 'Chocolate', 'priceDeltaCents': 0},
          ],
        },
      ],
    });

void main() {
  test('pasta: filled pasta adds its delta; the type is required (Salmón Noci 13,90 / 14,50)', () {
    final item = _pasta();
    final g = item.optionGroups.first;
    expect(missingGroups(item, {}), [g]);
    final sel = toggleChoice(g, {}, 'capeli-fungi-porcini');
    expect(unitPrice(item, sel), 1450);
    expect(missingGroups(item, sel), isEmpty);
    expect(fromPrice(item), 1390);
    // radio behaviour: picking another type replaces the first one
    expect(toggleChoice(g, sel, 'spaguetti')['tipo-pasta'], ['spaguetti']);
  });

  test('helado: flavours limited by the number of scoops, trimmed when scoops go down', () {
    final item = _helado();
    final bolas = item.optionGroups[0];
    final sabor = item.optionGroups[1];
    var sel = toggleChoice(bolas, {}, '1-bola');
    sel = toggleChoice(sabor, sel, 'v');
    sel = toggleChoice(sabor, sel, 'f'); // ignored: 1 scoop = 1 flavour
    expect(sel['sabor'], ['v']);
    sel = toggleChoice(bolas, sel, '2-bolas');
    sel = toggleChoice(sabor, sel, 'f');
    expect(sel['sabor'], ['v', 'f']);
    expect(unitPrice(item, sel), 500);
    sel = normaliseSelection(item, toggleChoice(bolas, sel, '1-bola'));
    expect(sel['sabor'], ['v']);
  });
}
