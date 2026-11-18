import 'package:flutter/material.dart';

import 'screens/ledger_home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AndroMoneyApp());
}

class AndroMoneyApp extends StatelessWidget {
  const AndroMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AndroMoney',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const LedgerHomeScreen(),
    );
  }
}
