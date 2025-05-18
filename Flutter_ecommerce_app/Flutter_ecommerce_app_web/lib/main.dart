import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cart/cart.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:flutter_ecommerce_app/screen/auth_screen/login_screen.dart';
import 'package:flutter_ecommerce_app/screen/home_screen.dart';
import 'package:flutter_ecommerce_app/utility/constants.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/data/data_provider.dart';
import 'models/user.dart';
import 'screen/auth_screen/provider/user_provider.dart';
import 'screen/product_by_category_screen/provider/product_by_category_provider.dart';
import 'screen/product_cart_screen/provider/cart_provider.dart';
import 'screen/product_details_screen/provider/product_detail_provider.dart';
import 'screen/product_favorite_screen/provider/favorite_provider.dart';
import 'screen/profile_screen/provider/profile_provider.dart';
import 'utility/app_theme.dart';
import 'utility/extensions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterCart().initializeCart(isPersistenceSupportEnabled: true);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProxyProvider<DataProvider, UserProvider>(
          create: (_) => UserProvider(null),
          update: (_, dataProvider, previous) =>
              previous!..update(dataProvider),
        ),
        ChangeNotifierProxyProvider<DataProvider, ProfileProvider>(
          create: (_) => ProfileProvider(null),
          update: (_, dataProvider, previous) =>
              previous!..update(dataProvider),
        ),
        ChangeNotifierProxyProvider<DataProvider, ProductByCategoryProvider>(
          create: (_) => ProductByCategoryProvider(null),
          update: (_, dataProvider, previous) =>
              previous!..update(dataProvider),
        ),
        ChangeNotifierProxyProvider<DataProvider, ProductDetailProvider>(
          create: (_) => ProductDetailProvider(null),
          update: (_, dataProvider, previous) =>
              previous!..update(dataProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, CartProvider>(
          create: (_) => CartProvider(null),
          update: (_, userProvider, previous) =>
              previous!..update(userProvider),
        ),
        ChangeNotifierProxyProvider<DataProvider, FavoriteProvider>(
          create: (_) => FavoriteProvider(null),
          update: (_, dataProvider, previous) =>
              previous!..update(dataProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _loginUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _loadLoginUser);
  }

  Future<void> _loadLoginUser() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = await userProvider.getLoginUsr();
      setState(() {
        _loginUser = user;
        _isLoading = false;
      });

      if (_loginUser?.sId == null) {
        print("➡️ Routing to LoginScreen");
      } else {
        print("✅ Routing to HomeScreen with user ID: ${_loginUser!.sId}");
      }
    } catch (e) {
      print("❌ Error in _loadLoginUser: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightAppTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),
      home: _loginUser?.sId == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
