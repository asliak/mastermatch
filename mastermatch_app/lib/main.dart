import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('server_url');
  if (savedUrl != null && 
      (savedUrl.contains('169.254.') || 
       savedUrl.contains('127.0.0.1') || 
       savedUrl.contains('10.0.2.2'))) {
    await prefs.setString('server_url', 'https://mastermatch.onrender.com');
  }
  runApp(const MasterMatchApp());
}

class MasterMatchApp extends StatelessWidget {
  const MasterMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MasterMatch',
      theme: AppTheme.theme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
