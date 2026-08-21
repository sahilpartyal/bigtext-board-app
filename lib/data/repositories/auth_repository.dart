import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthRepository {
  AuthRepository({required this.storageService});

  final StorageService storageService;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _extractNameFromEmail(email),
      email: email.trim(),
    );

    await storageService.saveUser(user);
    return user;
  }

  Future<UserModel> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('All fields are required.');
    }

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim(),
    );

    await storageService.saveUser(user);
    return user;
  }

  Future<void> logout() => storageService.clearSession();

  UserModel? getCurrentUser() => storageService.getUser();

  String _extractNameFromEmail(String email) {
    final localPart = email.trim().split('@').first;
    if (localPart.isEmpty) {
      return 'User';
    }

    return localPart[0].toUpperCase() + localPart.substring(1);
  }
}
