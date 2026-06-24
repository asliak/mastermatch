import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
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
