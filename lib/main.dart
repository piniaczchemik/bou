import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final GoRouter router = AppRouter.create();
  runApp(ProviderScope(child: BOUApp(router: router)));
}

class BOUApp extends StatelessWidget {
  final GoRouter router;
  const BOUApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B5BF7),
      brightness: Brightness.light,
    );
    return MaterialApp.router(
      title: 'BOU — Best Of Yourself',
      theme: ThemeData(useMaterial3: true, colorScheme: colorScheme, appBarTheme: const AppBarTheme(centerTitle: true)),
      routerConfig: router,
    );
  }
}
