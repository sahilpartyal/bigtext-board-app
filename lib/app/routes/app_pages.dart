import 'package:get/get.dart';

import '../../modules/splash/views/splash_screen.dart';
import '../../screens/main_display_wrapper.dart';
import '../../screens/purchase_success_wrapper.dart';
import '../../screens/recents_wrapper.dart';
import '../../screens/settings_wrapper.dart';
import '../../screens/subscription_wrapper.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage<dynamic>(name: AppRoutes.splash, page: SplashScreen.new),
    GetPage<dynamic>(name: AppRoutes.home, page: MainDisplayWrapper.new),
    GetPage<dynamic>(name: '/text-display', page: MainDisplayWrapper.new),
    GetPage<dynamic>(name: '/settings', page: SettingsWrapper.new),
    GetPage<dynamic>(name: '/recents', page: RecentsWrapper.new),
    GetPage<dynamic>(name: '/subscription', page: SubscriptionWrapper.new),
    GetPage<dynamic>(name: '/purchase-success', page: PurchaseSuccessWrapper.new),
  ];
}
