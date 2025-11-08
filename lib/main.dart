// main.dart
import 'package:flutter/material.dart';
// import 'package:iot_app/core/footerNav.dart';
import 'package:iot_app/core/theme.dart';
import 'package:iot_app/presentation/bluetooth_messaging/bluetoothConnection.dart';
// import 'package:iot_app/presentation/services/loginPage.dart';
// import 'package:iot_app/presentation/services/registerPage.dart';

void main() {
  runApp(const BluetoothChatApp());
}

class BluetoothChatApp extends StatelessWidget {
  const BluetoothChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Chat',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // initialRoute: '/login', // 👈 start from login page
      // routes: {
      //   '/login': (context) => const LoginScreen(),
      //   '/signup': (context) => const SignupScreen(),
      //   '/home': (context) => const FooterNav(), // 👈 after login success
      // },
      home: BluetoothConnectionScreen(),
    );
  }
}
