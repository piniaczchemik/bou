import 'package:flutter/material.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/programs/program_menu.dart';
import 'features/programs/program_detail.dart';

void main() {
  runApp(const BouApp());
}

class BouApp extends StatelessWidget {
  const BouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BOU',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32), // deep green vibe; tweak later
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const _HomeScreen(),
        '/onboarding': (_) => const OnboardingFlow(),
        '/programMenu': (_) => const ProgramMenuScreen(),
        '/programDetail': (_) => const ProgramDetailScreen(),
      },
      initialRoute: '/programMenu', // go straight to menu so you can see buttons now
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BOU Home')),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.of(context).pushNamed('/programMenu'),
          child: const Text('Open Program Menu'),
        ),
      ),
    );
  }
}
