import 'package:flutter/material.dart';


class AppTheme {
static final ThemeData lightTheme = ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
useMaterial3: true,
scaffoldBackgroundColor: Colors.grey[50],
appBarTheme: const AppBarTheme(
backgroundColor: Colors.pinkAccent,
foregroundColor: Colors.white,
titleTextStyle: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),
centerTitle: true,
elevation: 2,
),

);
}