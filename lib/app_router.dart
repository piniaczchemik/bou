import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/shell/bottom_nav_shell.dart';
import 'features/training/training_screen.dart';
import 'features/diet/diet_screen.dart';
import 'features/social/social_screen.dart';

class AppRouter {
  static GoRouter create() {
    return GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => BottomNavShell(child: child),
          routes: [
            GoRoute(path: '/', redirect: (_, __) => '/training'),
            GoRoute(
              path: '/training',
              name: 'training',
              pageBuilder: (context, state) => const NoTransitionPage(child: TrainingScreen()),
            ),
            GoRoute(
              path: '/diet',
              name: 'diet',
              pageBuilder: (context, state) => const NoTransitionPage(child: DietScreen()),
            ),
            GoRoute(
              path: '/social',
              name: 'social',
              pageBuilder: (context, state) => const NoTransitionPage(child: SocialScreen()),
            ),
          ],
        ),
      ],
    );
  }
}
