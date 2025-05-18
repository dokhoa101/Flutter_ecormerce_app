import 'package:get/get.dart';

import '../../screens/login/login_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../services/auth_service.dart';

class AppPages {
  static const HOME = '/';

  static final routes = [
    GetPage(
      name: HOME,
      fullscreenDialog: true,
      page: () {
        final authService = Get.find<AuthService>();
        return authService.isLoggedIn.value ? MainScreen() : LoginScreen();
      },
    ),
    GetPage(name: '/login', page: () => LoginScreen()),
    GetPage(name: '/main', page: () => MainScreen()),
  ];
}
