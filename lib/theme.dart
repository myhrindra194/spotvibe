import 'package:flutter/material.dart';

final appTheme = ThemeData(
  primarySwatch: Colors.deepPurple,
  colorScheme: ColorScheme.light(
    primary: Colors.deepPurple.shade500,
    secondary: Colors.deepPurple.shade200,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.deepPurple.shade500,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.deepPurple.shade500,
    foregroundColor: Colors.white,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
);
