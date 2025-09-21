import 'package:flutter/material.dart';
import 'core/hive_service.dart';
import 'features/home/home_demo.dart';
import 'features/coach/smart_coach.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const BOUApp());
}

class BOUApp extends StatefulWidget {
  const BOUApp({super.key});
  @override
  State<BOUApp> createState() => _BOUAppState();
}

class _BOUAppState extends State<BOUApp> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeDemoPage(),
      const MinimalCoachScreen(), // comes from smart_coach.dart
    ];
    return MaterialApp(
      title: 'BOU (Hive + Smart Coach Demo)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Workout'),
          ],
          onDestinationSelected: (i) => setState(() => index = i),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
