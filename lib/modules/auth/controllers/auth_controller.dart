import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  AuthController({required this.authRepository});

  final AuthRepository authRepository;

  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    currentUser.value = authRepository.getCurrentUser();
    super.onInit();
  }

  Future<void> login({
    required String email,
    required String password,
    required GlobalKey<FormState> formKey,
  }) async {
    final formState = formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    try {
      isLoading.value = true;
      currentUser.value = await authRepository.login(
        email: email,
        password: password,
      );
      Get.offAllNamed(AppRoutes.home);
    } catch (error) {
      Get.snackbar(
        'Login failed',
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required GlobalKey<FormState> formKey,
  }) async {
    final formState = formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar(
        'Signup failed',
        'Password and confirm password must match.',
      );
      return;
    }

    try {
      isLoading.value = true;
      currentUser.value = await authRepository.signup(
        name: name,
        email: email,
        password: password,
      );
      Get.offAllNamed(AppRoutes.home);
    } catch (error) {
      Get.snackbar(
        'Signup failed',
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}
