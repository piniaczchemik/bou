import 'package:flutter/material.dart';
import '../onboarding/onboarding_flow.dart' show ProgramCategory;

class ProgramDetailScreen extends StatelessWidget {
  const ProgramDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final category = ModalRoute.of(context)!.settings.arguments as ProgramCategory?;
    return Scaffold(
      appBar: AppBar(title: const Text('Program')),
      body: Center(
        child: Text(
          'Selected: ${category?.name ?? '—'}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
