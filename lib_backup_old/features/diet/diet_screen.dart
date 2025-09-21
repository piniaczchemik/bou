import 'package:flutter/material.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final diets = const [
      'Balanced (Clean Eating)',
      'High-Protein',
      'Keto / Low-Carb',
      'Mediterranean',
      'Vegan / Plant-based',
      'Vegetarian',
      'Paleo',
      'Bulk (Calorie Surplus)',
      'Cut (Calorie Deficit)',
      'Maintenance',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Diet Plans')),
      body: ListView.separated(
        itemCount: diets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) => ListTile(
          leading: const Icon(Icons.restaurant),
          title: Text(diets[i]),
          subtitle: const Text('Tap to see macros & sample meals'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Coming soon:  plan')),
            );
          },
        ),
      ),
    );
  }
}
