// File: lib/main.dart (updated with Dark Mode toggle)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const BOUApp());
}

class BOUApp extends StatefulWidget {
  const BOUApp({super.key});

  @override
  State<BOUApp> createState() => _BOUAppState();
}

class _BOUAppState extends State<BOUApp> {
  ThemeMode _mode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFF4F46E5);
    final light = ColorScheme.fromSeed(seedColor: baseColor, brightness: Brightness.light);
    final dark = ColorScheme.fromSeed(seedColor: baseColor, brightness: Brightness.dark);

    return ThemeController(
      mode: _mode,
      toggle: _toggleTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BOU',
        themeMode: _mode,
        theme: ThemeData(
          colorScheme: light,
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: light.surface,
            foregroundColor: light.onSurface,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: light.onSurface,
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            margin: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: dark,
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          appBarTheme: AppBarTheme(
            backgroundColor: dark.surface,
            foregroundColor: dark.onSurface,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: dark.onSurface,
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            margin: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        home: const RootShell(),
      ),
    );
  }
}

// Inherited controller to let any widget toggle the theme
class ThemeController extends InheritedWidget {
  final ThemeMode mode;
  final VoidCallback toggle;
  const ThemeController({super.key, required this.mode, required this.toggle, required super.child});

  static ThemeController of(BuildContext context) {
    final ThemeController? result = context.dependOnInheritedWidgetOfExactType<ThemeController>();
    assert(result != null, 'No ThemeController found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant ThemeController oldWidget) => oldWidget.mode != mode;
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;
  final pages = const [HomePage(), DietPage(), ExercisePage(), SocialPage()];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Diet'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Exercise'),
          NavigationDestination(icon: Icon(Icons.groups_2_outlined), selectedIcon: Icon(Icons.groups_2), label: 'Social'),
        ],
        indicatorColor: scheme.secondaryContainer,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = ThemeController.of(context).mode == ThemeMode.dark;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('BOU Dashboard'),
          actions: [
            IconButton(onPressed: ThemeController.of(context).toggle, icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
            const SizedBox(width: 4),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCard(
                  title: 'Welcome back, Kamil',
                  subtitle: "Let's smash today's plan",
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Today at a glance'),
                Row(
                  children: const [
                    Expanded(child: StatCard(label: 'Calories left', value: '1,420 kcal')),
                    SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Workout', value: 'Push Day')),
                  ],
                ),
                Row(
                  children: const [
                    Expanded(child: StatCard(label: 'Protein', value: '92 g')),
                    SizedBox(width: 12),
                    Expanded(child: StatCard(label: 'Steps', value: '6,200')),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Start Workout',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  final List<MealCardData> _meals = [
    MealCardData(title: 'Breakfast', kcal: 520, protein: 32, items: ['2x brown toast', 'Eggs', 'Avocado']),
    MealCardData(title: 'Lunch', kcal: 650, protein: 42, items: ['Chicken & rice', 'Veggies']),
    MealCardData(title: 'Dinner', kcal: 700, protein: 45, items: ['Pasta bolognese (LF)']),
    MealCardData(title: 'Snacks', kcal: 300, protein: 20, items: ['Greek yogurt (LF)', 'Banana']),
  ];

  Future<void> _openAddMeal() async {
    final added = await showModalBottomSheet<MealCardData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const AddMealSheet(),
    );
    if (added != null) {
      setState(() => _meals.add(added));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _meals.length,
        itemBuilder: (context, i) => MealCard(data: _meals[i]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMeal,
        label: const Text('Add meal'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class AddMealSheet extends StatefulWidget {
  const AddMealSheet({super.key});

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _items = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _kcal.dispose();
    _protein.dispose();
    _items.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final items = _items.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final meal = MealCardData(
        title: _title.text.trim(),
        kcal: int.tryParse(_kcal.text.trim()) ?? 0,
        protein: int.tryParse(_protein.text.trim()) ?? 0,
        items: items,
      );
      Navigator.of(context).pop(meal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Meal', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title (e.g., Lunch)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _kcal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter a number' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _protein,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter a number' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _items,
                decoration: const InputDecoration(labelText: 'Items (comma-separated)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Save')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}


class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final List<Widget> _workouts = const [
    WorkoutTile(name: 'Flat Bench Press', sets: '4 x 6-8', rest: '120s'),
    WorkoutTile(name: 'Incline DB Press', sets: '4 x 8-10', rest: '90s'),
    WorkoutTile(name: 'Cable Fly (Mid)', sets: '3 x 12-15', rest: '60s'),
    WorkoutTile(name: 'Rotator Cuff (Cuban Press)', sets: '3 x 12', rest: '60s'),
  ];

  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _running = false;

  // Height of the outer NavigationBar in RootShell (approx Material 3 default)
  static const double _outerNavHeight = 80;

  void _toggleStartPause() {
    setState(() => _running = !_running);
    _ticker?.cancel();
    if (_running) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
    }
  }

  void _finishSession() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _elapsed = Duration.zero;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session saved (demo).')),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      // Use a Stack so we can FLOAT the timer above the root nav bar
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Push Day'),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: _workouts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _workouts[i],
                  ),
                ),
                PrimaryButton(
                  label: _running
                      ? 'Pause Session'
                      : (_elapsed == Duration.zero ? 'Start Session' : 'Resume Session'),
                  icon: _running ? Icons.pause : Icons.play_arrow_rounded,
                  onPressed: _toggleStartPause,
                ),
                const SizedBox(height: 8),
                // Add spacer so content doesn't hide behind the floating timer
                SizedBox(height: (_elapsed > Duration.zero || _running) ? 56 : 0),
              ],
            ),
          ),

          // Floating timer bar ABOVE the root bottom NavigationBar
          if (_elapsed > Duration.zero || _running)
            Positioned(
              left: 12,
              right: 12,
              bottom: _outerNavHeight + 12, // sit above the outer nav bar
              child: SessionTimerBar(
                elapsed: _elapsed,
                running: _running,
                onToggle: _toggleStartPause,
                onFinish: _finishSession,
              ),
            ),
        ],
      ),
    );
  }
}


  void _finishSession() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _elapsed = Duration.zero;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session saved (demo).')),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Push Day'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _workouts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _workouts[i],
              ),
            ),
            PrimaryButton(
              label: _running ? 'Pause Session' : (_elapsed == Duration.zero ? 'Start Session' : 'Resume Session'),
              icon: _running ? Icons.pause : Icons.play_arrow_rounded,
              onPressed: _toggleStartPause,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: (_elapsed > Duration.zero || _running)
          ? SessionTimerBar(
              elapsed: _elapsed,
              running: _running,
              onToggle: _toggleStartPause,
              onFinish: _finishSession,
            )
          : null,
    );
  }
}
class SessionTimerBar extends StatelessWidget {
  final Duration elapsed;
  final bool running;
  final VoidCallback onToggle;
  final VoidCallback onFinish;

  const SessionTimerBar({
    super.key,
    required this.elapsed,
    required this.running,
    required this.onToggle,
    required this.onFinish,
  });

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(running ? Icons.timer : Icons.timer_outlined, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Workout session', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_fmt(elapsed), style: GoogleFonts.inter(fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onToggle,
              icon: Icon(running ? Icons.pause : Icons.play_arrow_rounded),
              label: Text(running ? 'Pause' : 'Resume'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}


class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Friends Activity'),
            const SizedBox(height: 8),
            _ActivityTile(name: 'Anna', activity: 'Finished Pull session • 42m'),
            _ActivityTile(name: 'Liam', activity: 'Logged 120g protein today'),
            _ActivityTile(name: 'Marta', activity: '10k steps smashed'),
            const Spacer(),
            PrimaryButton(label: 'Invite a friend', icon: Icons.person_add_alt_1, onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

// ===== Reusable widgets =====
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface.withOpacity(.9),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withOpacity(.6),
              scheme.secondaryContainer.withOpacity(.6),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: scheme.onPrimaryContainer.withOpacity(.8))),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const PrimaryButton({super.key, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class MealCardData {
  final String title;
  final int kcal;
  final int protein;
  final List<String> items;
  MealCardData({required this.title, required this.kcal, required this.protein, required this.items});
}

class MealCard extends StatelessWidget {
  final MealCardData data;
  const MealCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(data.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                Row(children: [
                  Icon(Icons.local_fire_department, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text('${data.kcal} kcal', style: GoogleFonts.inter(fontSize: 12)),
                ]),
                const SizedBox(width: 12),
                Row(children: [
                  Icon(Icons.egg_alt, size: 18, color: scheme.secondary),
                  const SizedBox(width: 6),
                  Text('${data.protein} g', style: GoogleFonts.inter(fontSize: 12)),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: -8,
              children: data.items.map((t) => Chip(label: Text(t))).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add item')),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class WorkoutTile extends StatelessWidget {
  final String name;
  final String sets;
  final String rest;
  const WorkoutTile({super.key, required this.name, required this.sets, required this.rest});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$sets • Rest $rest', style: GoogleFonts.inter(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.check_circle_outline)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeroCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: scheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: scheme.onPrimary.withOpacity(.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () {},
            icon: const Icon(Icons.calendar_today),
            label: const Text('View today\'s plan'),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String name;
  final String activity;
  const _ActivityTile({required this.name, required this.activity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: scheme.primary, child: Text(name[0])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(activity, style: GoogleFonts.inter(fontSize: 12, color: scheme.onSurfaceVariant)),
            ]),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
        ],
      ),
    );
  }
}
