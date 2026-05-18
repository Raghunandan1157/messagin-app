import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/neon_client.dart';
import '../db/repository.dart';
import '../models/user.dart';

class AppState extends ChangeNotifier {
  AppUser? me;
  bool initializing = true;
  String? lastError;
  late final Repository repo;

  static const String universalOtp = '1234';

  AppState() {
    repo = Repository(NeonClient.instance);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('me_phone');
      if (savedPhone != null) {
        me = await repo.userByPhone(savedPhone);
      }
    } catch (e) {
      lastError = e.toString();
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  bool verifyOtp(String code) => code.trim() == universalOtp;

  Future<AppUser?> lookupUserByPhone(String phone) async {
    return repo.userByPhone(phone);
  }

  Future<void> completeSignIn(String phone, String name) async {
    me = await repo.upsertUser(phone, name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('me_phone', phone);
    notifyListeners();
  }

  Future<void> resumeExisting(AppUser user) async {
    me = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('me_phone', user.phone);
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('me_phone');
    me = null;
    notifyListeners();
  }
}
