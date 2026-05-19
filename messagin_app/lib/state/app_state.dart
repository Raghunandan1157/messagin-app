import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../calls/signal_endpoint.dart';
import '../db/local_cache.dart';
import '../db/neon_client.dart';
import '../db/repository.dart';
import '../models/user.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
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

  Timer? _presenceTimer;

  AppState() {
    repo = Repository(NeonClient.instance);
    _bootstrap();
    _startHealthPolling();
    WidgetsBinding.instance.addObserver(this);
  }

  void _startPresenceHeartbeat() {
    _presenceTimer?.cancel();
    _touchPresence();
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _touchPresence(),
    );
  }

  Future<void> _touchPresence() async {
    final uid = me?.id;
    if (uid == null) return;
    try {
      await repo.touchPresence(uid);
    } catch (e) {
      debugPrint('touchPresence failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _touchPresence();
    }
  }

  void _startHealthPolling() {
    _checkServerHealth();
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkServerHealth(),
    );
  }

  Future<String?> _signalingHttpBase() async {
    // 1. Native: prefer the local override file the `call` shortcut writes.
    if (!kIsWeb) {
      final local = await localOverrideHttpBase();
      if (local != null && local.isNotEmpty) return local;
    }
    // 2. Native fallback + web: ask Vercel for the current published WSS.
    // Relative API_ENDPOINT values like `/api/sql` resolve against Uri.base
    // on web so the deployed app can use its own `/api/signal-url` route.
    try {
      final wss = await publishedSignalWss();
      if (wss != null && wss.isNotEmpty) return signalHttpBaseFromWss(wss);
    } catch (_) {}
    // 3. Explicit env override, then native localhost fallback.
    final wss = configuredSignalWss();
    if (wss != null) return signalHttpBaseFromWss(wss);
    return kIsWeb ? null : 'http://localhost:8787';
  }

  Future<void> _checkServerHealth() async {
    try {
      final base = await _signalingHttpBase();
      if (base == null || base.isEmpty) {
        _setServerHealthy(false);
        return;
      }
      final uri = Uri.parse('$base/health');
      final resp = await http
          .get(uri, headers: const {'ngrok-skip-browser-warning': '1'})
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
    _presenceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
        _preloadContactsAfter(const Duration(milliseconds: 1500));
        _startPresenceHeartbeat();
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
    _preloadContactsAfter(Duration.zero);
    _startPresenceHeartbeat();
  }

  Future<void> resumeExisting(AppUser user) async {
    me = user;
    justSignedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('me_phone', user.phone);
    notifyListeners();
    _preloadContactsAfter(Duration.zero);
    _startPresenceHeartbeat();
  }

  void clearJustSignedIn() {
    justSignedIn = false;
    notifyListeners();
    // Splash is dismissed; HomeShell will mount now. Kick off the heavy
    // contact preload AFTER first frame so HomeShell's listChatsFor goes first.
    _preloadContactsAfter(const Duration(milliseconds: 800));
  }

  void _preloadContactsAfter(Duration delay) {
    // On web the deployed app shares one serverless SQL proxy path for inbox
    // and directory calls. Loading the full directory eagerly can delay the
    // first useful home/chat paint, so the New Chat screen loads it on demand.
    if (kIsWeb) return;
    Future.delayed(delay, () {
      preloadContacts();
    });
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('me_phone');
    _presenceTimer?.cancel();
    _presenceTimer = null;
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
    final fresh =
        _contactsLoadedAt != null &&
        DateTime.now().difference(_contactsLoadedAt!) <
            const Duration(minutes: 5);
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
