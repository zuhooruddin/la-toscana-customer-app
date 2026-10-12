// Shapes of the public / customer API (contract 1.3.0). Parsing is tolerant: missing fields get safe defaults.

typedef Json = Map<String, dynamic>;

int _i(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String _s(Object? v) => v == null ? '' : '$v';
String? _sn(Object? v) => v == null || '$v'.isEmpty ? null : '$v';
bool _b(Object? v) => v == true;
List<Json> _l(Object? v) => v is List ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : const [];

class Choice {
  Choice(this.key, this.name, this.priceDeltaCents, this.available, this.needsConfirmation, this.image);
  factory Choice.fromJson(Json j) => Choice(_s(j['key']), _s(j['name']), _i(j['priceDeltaCents']), j['available'] != false, _b(j['needsConfirmation']), _sn(j['image']));
  final String key;
  final String name;
  final int priceDeltaCents;
  final bool available;
  final bool needsConfirmation;
  final String? image;
}

class OptionGroup {
  OptionGroup(this.key, this.name, this.min, this.max, this.required, this.maxByChoice, this.warning, this.choices);
  factory OptionGroup.fromJson(Json j) {
    final m = j['maxByChoice'];
    return OptionGroup(
      _s(j['key']),
      _s(j['name']),
      _i(j['min']),
      _i(j['max']) == 0 ? 1 : _i(j['max']),
      _b(j['required']),
      m is Map ? MaxByChoice(_s(m['groupKey']), (m['map'] as Map? ?? {}).map((k, v) => MapEntry('$k', _i(v)))) : null,
      _sn(j['warning']),
      _l(j['choices']).map(Choice.fromJson).toList(),
    );
  }
  final String key;
  final String name;
  final int min;
  final int max;
  final bool required;
  final MaxByChoice? maxByChoice;
  final String? warning;
  final List<Choice> choices;
}

class MaxByChoice {
  MaxByChoice(this.groupKey, this.map);
  final String groupKey;
  final Map<String, int> map;
}

class MenuItem {
  MenuItem({
    required this.id,
    required this.slug,
    required this.kind,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.imageUrl,
    required this.imageIsPlaceholder,
    required this.allergens,
    required this.allergensVerified,
    required this.soldOut,
    required this.orderable,
    required this.orderableNote,
    required this.optionGroups,
  });
  factory MenuItem.fromJson(Json j) {
    final img = j['image'] is Map ? (j['image'] as Map).cast<String, dynamic>() : null;
    return MenuItem(
      id: _s(j['id']),
      slug: _s(j['slug']),
      kind: _s(j['kind']),
      name: _s(j['name']),
      description: _s(j['description']),
      priceCents: _i(j['priceCents']),
      imageUrl: _sn(img?['url']),
      imageIsPlaceholder: img == null || _b(img['placeholder']),
      allergens: (j['allergens'] as List? ?? const []).map((e) => '$e').toList(),
      allergensVerified: _b(j['allergensVerified']),
      soldOut: _b(j['soldOut']),
      orderable: j['orderable'] != false,
      orderableNote: _sn(j['orderableNote']),
      optionGroups: _l(j['optionGroups']).map(OptionGroup.fromJson).toList(),
    );
  }
  final String id;
  final String slug;
  final String kind;
  final String name;
  final String description;
  final int priceCents;
  final String? imageUrl;
  final bool imageIsPlaceholder;
  final List<String> allergens;
  final bool allergensVerified;
  final bool soldOut;
  final bool orderable;
  final String? orderableNote;
  final List<OptionGroup> optionGroups;

  bool get hasPhoto => imageUrl != null && !imageIsPlaceholder;
  bool get hasRequiredOptions => optionGroups.any((g) => g.required || g.min > 0);
}

class MenuCategory {
  MenuCategory(this.key, this.name, this.description, this.image, this.items);
  factory MenuCategory.fromJson(Json j) =>
      MenuCategory(_s(j['key']), _s(j['displayName']).isNotEmpty ? _s(j['displayName']) : _s(j['name']), _sn(j['description']), _sn(j['image']), _l(j['items']).map(MenuItem.fromJson).toList());
  final String key;
  final String name;
  final String? description;
  final String? image;
  final List<MenuItem> items;
}

class Menu {
  Menu(this.branchSlug, this.orderingState, this.categories);
  factory Menu.fromJson(Json j) {
    final b = j['branch'] is Map ? (j['branch'] as Map).cast<String, dynamic>() : null;
    return Menu(_sn(b?['slug']), _sn(b?['orderingState']), _l(j['categories']).map(MenuCategory.fromJson).where((c) => c.items.isNotEmpty).toList());
  }
  final String? branchSlug;
  final String? orderingState;
  final List<MenuCategory> categories;

  MenuItem? item(String id) {
    for (final c in categories) {
      for (final i in c.items) {
        if (i.id == id || i.slug == id) return i;
      }
    }
    return null;
  }

  String? categoryOf(String itemId) {
    for (final c in categories) {
      if (c.items.any((i) => i.id == itemId)) return c.key;
    }
    return null;
  }
}

class Interval {
  Interval(this.open, this.close);
  final String open;
  final String close;
}

class Branch {
  Branch({
    required this.id,
    required this.slug,
    required this.name,
    required this.imageUrl,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.whatsapp,
    required this.hours,
    required this.hoursVerified,
    required this.pickup,
    required this.delivery,
    required this.orderingState,
    required this.prepTimeMinutes,
    required this.scheduledOrders,
    required this.cash,
    required this.card,
    required this.reservationsEnabled,
    required this.maxPartySize,
  });
  factory Branch.fromJson(Json j) {
    final a = (j['address'] as Map? ?? {}).cast<String, dynamic>();
    final geo = j['geo'] is Map ? (j['geo'] as Map) : null;
    final c = j['contact'] is Map ? (j['contact'] as Map) : null;
    final s = (j['services'] as Map? ?? {});
    final o = (j['ordering'] as Map? ?? {});
    final p = (j['payments'] as Map? ?? {});
    final r = (j['reservations'] as Map? ?? {});
    final img = j['image'] is Map ? (j['image'] as Map) : null;
    return Branch(
      id: _s(j['id']),
      slug: _s(j['slug']),
      name: _s(j['name']),
      imageUrl: _sn(img?['url']),
      address: [a['line1'], [a['postcode'], a['city']].where((x) => x != null && '$x'.isNotEmpty).join(' ')].where((x) => x != null && '$x'.isNotEmpty).join(', '),
      lat: (geo?['lat'] as num?)?.toDouble(),
      lng: (geo?['lng'] as num?)?.toDouble(),
      phone: _sn(c?['phone']),
      whatsapp: _sn(c?['whatsapp']),
      hours: {
        for (final h in _l(j['hours'])) _i(h['day']): _l(h['intervals']).map((iv) => Interval(_s(iv['open']), _s(iv['close']))).toList(),
      },
      hoursVerified: _b(j['hoursVerified']),
      pickup: _b(s['pickup']),
      delivery: _b(s['delivery']),
      orderingState: _s(o['state']),
      prepTimeMinutes: _i(o['prepTimeMinutes']),
      scheduledOrders: _b(o['scheduledOrders']),
      cash: _b(p['cash']),
      card: _b(p['card']),
      reservationsEnabled: _b(r['enabled']),
      maxPartySize: _i(r['maxPartySize']) == 0 ? 8 : _i(r['maxPartySize']),
    );
  }
  final String id;
  final String slug;
  final String name;
  final String? imageUrl;
  final String address;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? whatsapp;
  final Map<int, List<Interval>> hours;
  final bool hoursVerified;
  final bool pickup;
  final bool delivery;
  final String orderingState; // open | closed | paused | disabled
  final int prepTimeMinutes;
  final bool scheduledOrders;
  final bool cash;
  final bool card;
  final bool reservationsEnabled;
  final int maxPartySize;

  bool get canOrderOnline => orderingState == 'open' || (orderingState == 'closed' && scheduledOrders);
}

class Banner {
  Banner(this.id, this.title, this.body, this.imageUrl, this.imageAlt, this.link);
  factory Banner.fromJson(Json j) => Banner(_s(j['id']), _s(j['title']), _s(j['body']), _sn(j['imageUrl']), _s(j['imageAlt']), _sn(j['link']));
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String imageAlt;
  final String? link;
}

class SlotDay {
  SlotDay(this.date, this.slots);
  final String date;
  final List<DateTime> slots;
}

class Slots {
  Slots(this.asap, this.scheduling, this.days);
  factory Slots.fromJson(Json j) => Slots(
        _b(j['asap']),
        _b(j['scheduling']),
        _l(j['days']).map((d) => SlotDay(_s(d['date']), (d['slots'] as List? ?? const []).map((s) => DateTime.parse('$s')).toList())).toList(),
      );
  final bool asap;
  final bool scheduling;
  final List<SlotDay> days;
}

class QuoteIssue {
  QuoteIssue(this.code, this.message, this.line);
  final String code;
  final String message;
  final int? line;
}

class Quote {
  Quote(this.ok, this.errors, this.subtotalCents, this.discountCents, this.deliveryFeeCents, this.totalCents, this.taxCents, this.estimatedReadyAt, this.cash, this.card, this.couponCode);
  factory Quote.fromJson(Json j) {
    final t = (j['totals'] as Map? ?? {});
    final f = (j['fulfilment'] as Map? ?? {});
    final p = (j['paymentMethods'] as Map? ?? {});
    final c = j['coupon'] is Map ? j['coupon'] as Map : null;
    return Quote(
      _b(j['ok']),
      _l(j['errors']).map((e) => QuoteIssue(_s(e['code']), _s(e['message']), e['line'] == null ? null : _i(e['line']))).toList(),
      _i(t['subtotalCents']),
      _i(t['discountCents']),
      _i(t['deliveryFeeCents']),
      _i(t['totalCents']),
      _i(t['taxCents']),
      f['estimatedReadyAt'] == null ? null : DateTime.tryParse('${f['estimatedReadyAt']}'),
      _b(p['cash']),
      _b(p['card']),
      _sn(c?['code']),
    );
  }
  final bool ok;
  final List<QuoteIssue> errors;
  final int subtotalCents;
  final int discountCents;
  final int deliveryFeeCents;
  final int totalCents;
  final int taxCents;
  final DateTime? estimatedReadyAt;
  final bool cash;
  final bool card;
  final String? couponCode;
}

class OrderLine {
  OrderLine(this.name, this.quantity, this.options, this.lineTotalCents);
  final String name;
  final int quantity;
  final List<String> options;
  final int lineTotalCents;
}

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.number,
    required this.branchName,
    required this.status,
    required this.history,
    required this.type,
    required this.scheduledFor,
    required this.estimatedReadyAt,
    required this.lines,
    required this.totalCents,
    required this.subtotalCents,
    required this.discountCents,
    required this.deliveryFeeCents,
    required this.taxCents,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentSimulated,
    required this.canCancel,
    required this.createdAt,
  });
  factory CustomerOrder.fromJson(Json j) {
    final f = (j['fulfilment'] as Map? ?? {});
    final t = (j['totals'] as Map? ?? {});
    final p = (j['payment'] as Map? ?? {});
    return CustomerOrder(
      id: _s(j['id']),
      number: _s(j['number']),
      branchName: _s((j['branch'] as Map? ?? {})['name']),
      status: _s(j['status']),
      history: {for (final h in _l(j['history'])) _s(h['status']): DateTime.tryParse(_s(h['at'])) ?? DateTime.now()},
      type: _s(f['type']),
      scheduledFor: f['scheduledFor'] == null ? null : DateTime.tryParse('${f['scheduledFor']}'),
      estimatedReadyAt: f['estimatedReadyAt'] == null ? null : DateTime.tryParse('${f['estimatedReadyAt']}'),
      lines: _l(j['lines'])
          .map((l) => OrderLine(_s(l['name']), _i(l['quantity']), _l(l['options']).map((o) => _s(o['choice'] ?? o['choiceName'])).toList(), _i(l['lineTotalCents'])))
          .toList(),
      totalCents: _i(t['totalCents']),
      subtotalCents: _i(t['subtotalCents']),
      discountCents: _i(t['discountCents']),
      deliveryFeeCents: _i(t['deliveryFeeCents']),
      taxCents: _i(t['taxCents']),
      paymentMethod: _s(p['method']),
      paymentStatus: _s(p['status']),
      paymentSimulated: _b(p['simulated']),
      canCancel: _b(j['canCancel']),
      createdAt: DateTime.tryParse(_s(j['createdAt'])) ?? DateTime.now(),
    );
  }
  final String id;
  final String number;
  final String branchName;
  final String status;
  final Map<String, DateTime> history;
  final String type;
  final DateTime? scheduledFor;
  final DateTime? estimatedReadyAt;
  final List<OrderLine> lines;
  final int totalCents;
  final int subtotalCents;
  final int discountCents;
  final int deliveryFeeCents;
  final int taxCents;
  final String paymentMethod;
  final String paymentStatus;
  final bool paymentSimulated;
  final bool canCancel;
  final DateTime createdAt;

  bool get isActive => const ['pending_payment', 'confirmed', 'preparing', 'ready', 'out_for_delivery'].contains(status);
}

class AppUser {
  AppUser(this.id, this.email, this.name, this.phone, this.role, this.lang, this.marketingConsent);
  factory AppUser.fromJson(Json j) => AppUser(_s(j['id']), _s(j['email']), _sn(j['name']), _sn(j['phone']), _s(j['role']), _s(j['lang']), _b(j['marketingConsent']));
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String role;
  final String lang;
  final bool marketingConsent;
}
