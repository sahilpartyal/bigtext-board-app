import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/storage_service.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'modules/splash/controllers/splash_controller.dart';
import 'theme/app_theme.dart';

class BigTextApp extends StatelessWidget {
  const BigTextApp({required this.storageService, super.key});

  final StorageService storageService;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BigText',
      debugShowCheckedModeBanner: false,
      theme: appDarkTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      initialBinding: BindingsBuilder(() {
        Get.put<StorageService>(storageService);
        Get.put<AuthRepository>(
          AuthRepository(storageService: Get.find<StorageService>()),
        );
        Get.put<AuthController>(
          AuthController(authRepository: Get.find<AuthRepository>()),
        );
        Get.put<SplashController>(
          SplashController(storageService: Get.find<StorageService>()),
        );
      }),
    );
  }
}
