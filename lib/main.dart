
import 'package:flutter/material.dart';

import 'screens/ledger_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AndroMoneyApp());
}

class AndroMoneyApp extends StatelessWidget {
  const AndroMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF080D12);
    const surfaceColor = Color(0xFF141C24);
    const primaryGreen = Color(0xFF00E676);

    return MaterialApp(
      title: 'AndroMoney',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        scaffoldBackgroundColor: backgroundColor,

        colorScheme: const ColorScheme.dark(
          primary: primaryGreen,
          secondary: Color(0xFF69F0AE),
          surface: surfaceColor,
          error: Color(0xFFFF5252),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),

        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF263440),
              width: 0.6,
            ),
          ),
        ),

        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          labelStyle: const TextStyle(
            color: Colors.white70,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF344451),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: primaryGreen,
              width: 1.5,
            ),
          ),
        ),

        dividerColor: const Color(0xFF344451),

        snackBarTheme: const SnackBarThemeData(
          backgroundColor: surfaceColor,
          contentTextStyle: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      darkTheme: ThemeData.dark(),

      themeMode: ThemeMode.dark,

      home: const LedgerHomeScreen(),
    );
  }
}
