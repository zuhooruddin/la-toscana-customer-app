import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../core/models.dart';

/// Shared app data: language, chosen restaurant + mode, restaurants, the menu for the chosen restaurant (prices and
/// availability are per restaurant), home banners and the signed-in customer (optional: guests can order).
class AppState extends ChangeNotifier {
  AppState(this.api, this.tokens) {
    api.onSessionExpired = () {
      user = null;
      notifyListeners();
    };
  }

  final Api api;
  final TokenStore tokens;

  String lang = 'es';

  /// Store listings + live languages from admin → settings (GET /public/site). Null until loaded.
  String? appStoreUrl;
  String? playStoreUrl;
  /// Languages the owner enabled that this app has strings for (always includes Spanish).
  List<String> languages = const ['es', 'en'];
  static const supportedLanguages = ['es', 'en'];
  String? branchSlug;
  String mode = 'pickup'; // pickup | delivery
  List<Branch> branches = [];
  Menu? menu;
  List<Banner> banners = [];
  AppUser? user;
  bool loading = true;
  Object? error;

  Branch? get branch => branches.where((b) => b.slug == branchSlug).firstOrNull;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    lang = p.getString('lt_lang') ?? (PlatformDispatcher.instance.locale.languageCode == 'en' ? 'en' : 'es');
    branchSlug = p.getString('lt_branch');
    mode = p.getString('lt_mode') ?? 'pickup';
    await tokens.load();
    await refresh();
    if (tokens.hasSession) await loadUser();
  }

  /// Restaurants, menu and banners. Safe to call again (pull to refresh, app resume).
  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.get<Map<String, dynamic>>('/api/v1/public/branches'),
        api.get<Map<String, dynamic>>('/api/v1/public/menu', query: {'branch': branchSlug, 'lang': lang}),
        api.get<Map<String, dynamic>>('/api/v1/public/banners', query: {'placement': 'home_top', 'lang': lang}),
      ]);
      branches = (results[0]['items'] as List).map((b) => Branch.fromJson((b as Map).cast<String, dynamic>())).toList();
      if (branchSlug != null && branch == null) branchSlug = null; // restaurant unpublished
      menu = Menu.fromJson(results[1]);
      banners = (results[2]['items'] as List? ?? const []).map((b) => Banner.fromJson((b as Map).cast<String, dynamic>())).toList();
      await _loadSite();
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Optional: a failure here never blocks the menu.
  Future<void> _loadSite() async {
    try {
      final site = await api.get<Map<String, dynamic>>('/api/v1/public/site', query: {'lang': lang});
      final apps = (site['apps'] as Map?)?.cast<String, dynamic>() ?? const {};
      appStoreUrl = apps['ios'] as String?;
      playStoreUrl = apps['android'] as String?;
      final enabled = ((site['languages'] as List?) ?? const []).map((l) => '${(l as Map)['code']}').toSet();
      languages = supportedLanguages.where((l) => l == 'es' || enabled.contains(l)).toList();
      if (!languages.contains(lang)) lang = 'es';
    } catch (_) {}
  }

  Future<void> selectBranch(String slug, String newMode) async {
    final changed = slug != branchSlug;
    branchSlug = slug;
    mode = newMode;
    final p = await SharedPreferences.getInstance();
    await p.setString('lt_branch', slug);
    await p.setString('lt_mode', newMode);
    notifyListeners();
    if (changed) await refresh();
  }

  Future<void> setLang(String l) async {
    lang = l;
    final p = await SharedPreferences.getInstance();
    await p.setString('lt_lang', l);
    notifyListeners();
    await refresh();
  }

  // ---------------------------------------------------------------- session
  Future<void> loadUser() async {
    try {
      final r = await api.get<Map<String, dynamic>>('/api/v1/auth/me');
      final u = AppUser.fromJson((r['user'] as Map).cast<String, dynamic>());
      // This app is for customers; staff use the admin and driver apps.
      if (u.role != 'customer') {
        await logout();
        return;
      }
      user = u;
    } catch (_) {
      user = null;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await api.post<Map<String, dynamic>>('/api/v1/auth/login', body: {'email': email, 'password': password, 'client': 'mobile'});
    await tokens.save(r['accessToken'] as String, r['refreshToken'] as String);
    await loadUser();
    if (user == null) throw ApiException(403, 'NOT_CUSTOMER', 'Use the staff apps');
  }

  Future<void> register({required String email, required String password, required String name, String? phone, required bool marketing}) async {
    final r = await api.post<Map<String, dynamic>>('/api/v1/auth/register', body: {
      'email': email,
      'password': password,
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'lang': lang,
      'marketingConsent': marketing,
      'acceptTerms': true,
      'client': 'mobile',
    });
    await tokens.save(r['accessToken'] as String, r['refreshToken'] as String);
    await loadUser();
  }

  Future<void> logout() async {
    final refresh = tokens.refresh;
    try {
      if (refresh != null) await api.post('/api/v1/auth/logout', body: {'refreshToken': refresh});
    } catch (_) {}
    await tokens.clear();
    user = null;
    notifyListeners();
  }

  Future<void> deleteAccount(String password) async {
    await api.post('/api/v1/me/delete', body: {'password': password, 'confirm': 'ELIMINAR'});
    await tokens.clear();
    user = null;
    notifyListeners();
  }
}
