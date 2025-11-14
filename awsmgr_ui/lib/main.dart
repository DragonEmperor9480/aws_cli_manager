import 'package:flutter/material.dart';
import 'services/backend_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start backend automatically
  try {
    await BackendService.start();
  } catch (e) {
    debugPrint('Failed to start backend: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWS Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
