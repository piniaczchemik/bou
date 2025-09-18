import 'package:flutter/material.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Chest', Icons.fitness_center),
      ('Push (Chest/Shoulders/Triceps)', Icons.sports_gymnastics),
      ('Pull (Back/Biceps)', Icons.fitness_center),
      ('Legs (Quads/Hams/Glutes)', Icons.directions_run),
      ('Calisthenics', Icons.accessibility_new),
      ('Endurance', Icons.directions_bike),
      ('Triathlon Prep', Icons.pool),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Training Programs')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final (title, icon) = items[i];
          return ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: const Text('Tap to view workouts'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Coming soon:  workouts')),
              );
            },
          );
        },
      ),
    );
  }
}
