import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static GoRouter create() {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const _HomeScreen(),
        ),
      ],
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BOU — Best Of Yourself')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome to BOU'),
            SizedBox(height: 12),
            Text('Train • Eat • Compete with Friends'),
          ],
        ),
      ),
    );
  }
}
