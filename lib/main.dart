import 'package:flutter/material.dart';
import 'package:iot_app/core/footerNav.dart';
import 'package:iot_app/core/theme.dart';
import 'package:iot_app/presentation/services/loginPage.dart';
import 'package:iot_app/presentation/services/registerPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Check if user is logged in
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(BluetoothChatApp(isLoggedIn: isLoggedIn));
}

class BluetoothChatApp extends StatelessWidget {
  final bool isLoggedIn;
  const BluetoothChatApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Chat',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/login', // 👈 Decide based on login state
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const FooterNav(),
      },
    );
  }
}
