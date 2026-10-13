import 'config.dart';

/// Web ↔ app bridge.
///
/// * Every shareable screen has a public, indexable web URL (the website is the search surface; the app is not
///   indexed). Share sheets always use these canonical URLs, never app-only links, so shared links get Open Graph
///   previews and work for people without the app.
/// * App Links / Universal Links open those same URLs in the app: [appLocationFor] maps a website path to the
///   app route. Unknown paths fall back to the home screen; anything the app cannot show (checkout, account
///   pages, legal texts) is excluded from the association files on the website and stays in the browser.
///
/// Spanish URLs have no prefix; other languages live under /{lang}/ (same scheme as the website).
class WebLinks {
  static String _base(String lang) => '${AppConfig.websiteUrl}${lang == 'es' ? '' : '/$lang'}';

  /// Canonical home URLs on the website: "/" for Spanish, "/en" (no trailing slash) for English.
  static String home(String lang) => lang == 'es' ? '${AppConfig.websiteUrl}/' : _base(lang);
  static String menu(String lang) => '${_base(lang)}/carta';
  static String dish(String lang, String slug) => '${_base(lang)}/carta/$slug';
  static String category(String lang, String key) => '${_base(lang)}/carta/categoria/$key';
  static String restaurant(String lang, String slug) => '${_base(lang)}/restaurantes/$slug';
  static String reservations(String lang) => '${_base(lang)}/reservas';
  static String offer(String lang, String code) => '${_base(lang)}/ofertas/${code.toLowerCase()}';
}

/// Result of mapping an incoming website URL: the app route plus the language encoded in the URL (if any) and an
/// order-tracking token carried by e-mail links (/pedido/{id}?t=…).
class DeepLink {
  const DeepLink(this.location, {this.lang, this.orderId, this.orderToken});
  final String location;
  final String? lang;
  final String? orderId;
  final String? orderToken;
}

const _appRoots = {'/', '/menu', '/cart', '/account', '/select', '/item', '/checkout', '/order', '/restaurants', '/reservations', '/login'};
const _langs = {'en'};

/// Maps a website path (as delivered by App Links / Universal Links) to an app location. Returns null for paths
/// that already are app routes, so in-app navigation is untouched.
DeepLink? appLocationFor(Uri uri) {
  var segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  String? lang;
  if (segs.isNotEmpty && _langs.contains(segs.first)) {
    lang = segs.first;
    segs = segs.sublist(1);
  } else if (segs.isNotEmpty && segs.first == 'es') {
    lang = 'es';
    segs = segs.sublist(1);
  }
  final first = segs.isEmpty ? '' : segs.first;
  if (lang == null && _appRoots.contains('/$first')) return null; // internal route
  DeepLink to(String loc) => DeepLink(loc, lang: lang ?? 'es');
  switch (first) {
    case '':
      return to('/');
    case 'carta':
      if (segs.length >= 3 && segs[1] == 'categoria') return to('/menu?cat=${Uri.encodeQueryComponent(segs[2])}');
      if (segs.length >= 2) return to('/item/${Uri.encodeComponent(segs[1])}');
      final q = uri.queryParameters['q'];
      return to(q == null ? '/menu' : '/menu?q=${Uri.encodeQueryComponent(q)}');
    case 'ofertas':
      return to('/menu'); // offers are applied as a promo code at checkout
    case 'restaurantes':
    case 'pizza-a-domicilio':
      return to('/restaurants');
    case 'reservas':
      final branch = uri.queryParameters['branch'];
      return to(branch == null ? '/reservations' : '/reservations?branch=${Uri.encodeQueryComponent(branch)}');
    case 'pedido':
      if (segs.length >= 2) return DeepLink('/order/${Uri.encodeComponent(segs[1])}', lang: lang ?? 'es', orderId: segs[1], orderToken: uri.queryParameters['t']);
      return to('/');
    default:
      return to('/'); // graceful fallback: unknown/web-only page → home
  }
}
