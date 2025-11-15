import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'presentation/screens/home_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize database
  final dbService = DatabaseService();
  await dbService.database; // Initialize database on app start
  
  // Note: Database is automatically created on first launch
  // Data will persist between app restarts
  
  // Initialize theme manager (it loads theme automatically in constructor)
  final themeManager = ThemeManager();
  
  runApp(
    ChangeNotifierProvider.value(
      value: themeManager,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return MaterialApp(
      title: 'Bill Divider',
      debugShowCheckedModeBanner: false,
      theme: themeManager.isDarkMode
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
