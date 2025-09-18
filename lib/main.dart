import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: add dotenv + Supabase.initialize() here later.
  final GoRouter router = AppRouter.create();

  runApp(ProviderScope(child: BOUApp(router: router)));
}

class BOUApp extends StatelessWidget {
  final GoRouter router;
  const BOUApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B5BF7), // temporary BOU primary
      brightness: Brightness.light,
    );

    return MaterialApp.router(
      title: 'BOU — Best Of Yourself',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      routerConfig: router,
    );
  }
}
