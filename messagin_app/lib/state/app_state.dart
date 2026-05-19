import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../db/local_cache.dart';
import '../db/neon_client.dart';
import '../db/repository.dart';
import '../models/user.dart';

class AppState extends ChangeNotifier {
  AppUser? me;
  bool initializing = true;
  bool justSignedIn = false;
  String? lastError;
  late final Repository repo;
  final LocalCache cache = LocalCache();

  // --- Signaling server health ---
  bool serverHealthy = true;
  bool _bannerDismissed = false;
  DateTime? _bannerDismissedAt;
  Timer? _healthTimer;
  bool get showServerDownBanner =>
      !serverHealthy &&
      (!_bannerDismissed ||
          (_bannerDismissedAt != null &&
              DateTime.now().difference(_bannerDismissedAt!) >
                  const Duration(minutes: 5)));

  List<AppUser> _contacts = [];
  bool _contactsLoaded = false;
  bool _contactsLoading = false;
  DateTime? _contactsLoadedAt;

  static const String universalOtp = '1234';

  AppState() {
    repo = Repository(NeonClient.instance);
    _bootstrap();
    _startHealthPolling();
  }

  void _startHealthPolling() {
    _checkServerHealth();
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkServerHealth(),
    );
  }

  Future<String> _signalingHttpBase() async {
    // Prefer the ngrok override file the signaling-server task writes.
    if (!kIsWeb) {
      try {
        final home = Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'];
        if (home != null) {
          final f = File('$home/.messagin-signal.json');
          if (await f.exists()) {
            final j = jsonDecode(await f.readAsString());
            final https = (j is Map ? j['https'] : null) as String?;
            if (https != null && https.isNotEmpty) return https;
          }
        }
      } catch (_) {}
    }
    // Derive HTTP base from the WSS URL.
    final wss = dotenv.env['SIGNAL_WSS_URL'] ?? 'ws://localhost:8787';
    return wss
        .replaceFirst(RegExp(r'^ws://'), 'http://')
        .replaceFirst(RegExp(r'^wss://'), 'https://');
  }

  Future<void> _checkServerHealth() async {
    try {
      final base = await _signalingHttpBase();
      final uri = Uri.parse('$base/health');
      final resp = await http
          .get(uri)
          .timeout(const Duration(seconds: 4));
      final healthy = resp.statusCode >= 200 && resp.statusCode < 400;
      _setServerHealthy(healthy);
    } catch (_) {
      _setServerHealthy(false);
    }
  }

  void _setServerHealthy(bool healthy) {
    if (serverHealthy == healthy) return;
    serverHealthy = healthy;
    if (healthy) {
      // Reset dismissal so the next outage shows the banner again.
      _bannerDismissed = false;
      _bannerDismissedAt = null;
    }
    notifyListeners();
  }

  void dismissServerDownBanner() {
    _bannerDismissed = true;
    _bannerDismissedAt = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      // Open local cache early so we can hydrate UI from disk before
      // the network call resolves. Cheap on android/ios/macos; no-op on web
      // and unsupported platforms.
      await cache.init();
      final cached = await cache.allUsers();
      if (cached.isNotEmpty) {
        _contacts = cached;
        _contactsLoaded = true;
        // Leave _contactsLoadedAt null so the next preloadContacts() still
        // refreshes from Neon — the cache only seeds the first paint.
      }

      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('me_phone');
      if (savedPhone != null) {
        me = await repo.userByPhone(savedPhone);
        // Now that `me` is known, drop self from the cached contacts so the
        // NewChatScreen list doesn't include the current user.
        if (me != null && _contacts.isNotEmpty) {
          _contacts = _contacts.where((u) => u.id != me!.id).toList();
        }
      }
    } catch (e) {
      lastError = e.toString();
    } finally {
      initializing = false;
      notifyListeners();
      // Defer heavy contact preload so it doesn't compete with HomeShell's
      // first paint + initial listChatsFor on a single shared pg connection.
      if (me != null) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          preloadContacts();
        });
      }
    }
  }

  bool verifyOtp(String code) => code.trim() == universalOtp;

  Future<AppUser?> lookupUserByPhone(String phone) async {
    return repo.userByPhone(phone);
  }

  Future<void> completeSignIn(String phone, String name) async {
    me = await repo.upsertUser(phone, name);
    justSignedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('me_phone', phone);
    notifyListeners();
    // Fire preload during splash so welcome stats can populate. Splash
    // doesn't trigger listChatsFor (HomeShell does that post-splash), so
    // no contention.
    // ignore: unawaited_futures
    preloadContacts();
  }

  Future<void> resumeExisting(AppUser user) async {
    me = user;
    justSignedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('me_phone', user.phone);
    notifyListeners();
    // ignore: unawaited_futures
    preloadContacts();
  }

  void clearJustSignedIn() {
    justSignedIn = false;
    notifyListeners();
    // Splash is dismissed; HomeShell will mount now. Kick off the heavy
    // contact preload AFTER first frame so HomeShell's listChatsFor goes first.
    Future.delayed(const Duration(milliseconds: 800), () {
      preloadContacts();
    });
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('me_phone');
    me = null;
    _contacts = [];
    _contactsLoaded = false;
    _contactsLoadedAt = null;
    try {
      await cache.clear();
    } catch (e) {
      debugPrint('cache.clear() failed: $e');
    }
    notifyListeners();
  }

  List<AppUser> get contacts => _contacts;
  bool get contactsLoaded => _contactsLoaded;

  Future<void> preloadContacts({bool force = false}) async {
    // Single-flight: don't stack concurrent listUsers (1325 rows) calls.
    if (_contactsLoading) return;
    final fresh = _contactsLoadedAt != null &&
        DateTime.now().difference(_contactsLoadedAt!) < const Duration(minutes: 5);
    if (_contactsLoaded && fresh && !force) return;
    _contactsLoading = true;
    try {
      final all = await repo.listUsers();
      _contacts = me == null ? all : all.where((u) => u.id != me!.id).toList();
      _contactsLoaded = true;
      _contactsLoadedAt = DateTime.now();
      notifyListeners();
      // Persist refreshed list to local cache for next boot. Fire-and-forget
      // — UI is already updated; don't block on disk write.
      // ignore: unawaited_futures
      cache.upsertUsers(all).catchError((e) {
        debugPrint('cache.upsertUsers failed: $e');
      });
    } catch (e) {
      lastError = e.toString();
    } finally {
      _contactsLoading = false;
    }
  }
}
