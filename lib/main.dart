import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'exercise_tab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('prefs');
  await Hive.openBox('ticks');
  runApp(const BouApp());
}

class BouApp extends StatelessWidget {
  const BouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bou App',
      theme: ThemeData(useMaterial3: true),
      home: const ExerciseTab(),
    );
  }
}
