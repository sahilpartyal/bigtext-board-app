import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class StorageService {
  StorageService(this._prefs);

  static const _userKey = 'session_user';

  final SharedPreferences _prefs;

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  UserModel? getUser() {
    final rawUser = _prefs.getString(_userKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawUser) as Map<String, dynamic>;
    return UserModel.fromJson(decoded);
  }

  bool hasSession() => _prefs.containsKey(_userKey);

  Future<void> clearSession() async {
    await _prefs.remove(_userKey);
  }
}
