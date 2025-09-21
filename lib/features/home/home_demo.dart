// lib/features/home/home_demo.dart
import 'package:flutter/material.dart';
import '../../core/hive_service.dart';

class HomeDemoPage extends StatefulWidget {
  const HomeDemoPage({super.key});
  @override
  State<HomeDemoPage> createState() => _HomeDemoPageState();
}

class _HomeDemoPageState extends State<HomeDemoPage> {
  late DateTime today;
  @override
  void initState() {
    super.initState();
    today = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final baseline = HiveService.getBaselineDailyKcal();
    final bonus = HiveService.getDailyBonusKcal(today);
    final total = baseline + bonus;
    final weekly = HiveService.getWeeklyBonusKcalSoFar(today);

    return Scaffold(
      appBar: AppBar(title: const Text('Home Rings (Demo)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Baseline kcal: $baseline', style: Theme.of(context).textTheme.titleMedium),
            Text('Bonus today: +$bonus', style: Theme.of(context).textTheme.titleMedium),
            Text('Target today: $total', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Weekly BOU Boost: +$weekly kcal', style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await HiveService.addDailyBonusKcal(today, 50);
                    await HiveService.addWeeklyBonusKcal(50, today);
                    if (mounted) setState(() {});
                  },
                  child: const Text('+50 kcal (simulate)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await HiveService.setDailyBonusKcal(today, 0);
                    if (mounted) setState(() {});
                  },
                  child: const Text('Reset today bonus'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
