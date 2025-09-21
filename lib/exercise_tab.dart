import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/models.dart';
import 'programs.dart';

class ExerciseTab extends StatefulWidget {
  const ExerciseTab({super.key});
  @override
  State<ExerciseTab> createState() => _ExerciseTabState();
}

class _ExerciseTabState extends State<ExerciseTab> {
  final _prefs = Hive.box('prefs');
  final _ticks = Hive.box('ticks');

  late Program _currentProgram;
  int _currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    final savedProgramId = _prefs.get('program_id', defaultValue: 'home_start') as String;
    _currentProgram = homeStartProgram; // only one for now
    _currentDayIndex = _prefs.get('day_index_${_currentProgram.id}', defaultValue: 0) as int;
  }

  void _saveSelection() {
    _prefs.put('program_id', _currentProgram.id);
    _prefs.put('day_index_${_currentProgram.id}', _currentDayIndex);
  }

  String _tickKey(WorkoutDay day, ExerciseItem ex, int setNo) =>
      "${_currentProgram.id}|${day.id}|${ex.id}|set$setNo";

  bool _isSetDone(WorkoutDay day, ExerciseItem ex, int setNo) =>
      (_ticks.get(_tickKey(day, ex, setNo), defaultValue: false) as bool);

  void _toggleSet(WorkoutDay day, ExerciseItem ex, int setNo, bool value) {
    _ticks.put(_tickKey(day, ex, setNo), value);
    setState(() {});
  }

  void _resetDay(WorkoutDay day) async {
    final keys = _ticks.keys.where((k) => k is String && (k as String).contains("|${day.id}|")).toList();
    for (final k in keys) {
      await _ticks.delete(k);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final day = _currentProgram.days[_currentDayIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercise"),
        actions: [
          IconButton(
            tooltip: "Reset today",
            onPressed: () => _resetDay(day),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Program:", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _currentProgram.id,
                  items: const [
                    DropdownMenuItem(value: "home_start", child: Text("Home Start (Obese-friendly)")),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _currentProgram = homeStartProgram; // only one currently
                      _currentDayIndex = 0;
                      _saveSelection();
                    });
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Previous day",
                  onPressed: _currentDayIndex > 0
                      ? () {
                          setState(() => _currentDayIndex--);
                          _saveSelection();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text("${_currentDayIndex + 1}/${_currentProgram.days.length}"),
                IconButton(
                  tooltip: "Next day",
                  onPressed: _currentDayIndex < _currentProgram.days.length - 1
                      ? () {
                          setState(() => _currentDayIndex++);
                          _saveSelection();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(day.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: day.items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final ex = day.items[i];
                  return _ExerciseCard(
                    title: ex.name,
                    sets: ex.sets,
                    reps: ex.reps,
                    isSetDone: (setNo) => _isSetDone(day, ex, setNo),
                    onToggle: (setNo, value) => _toggleSet(day, ex, setNo, value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String title;
  final int sets;
  final int reps;
  final bool Function(int setNo) isSetDone;
  final void Function(int setNo, bool value) onToggle;

  const _ExerciseCard({
    required this.title,
    required this.sets,
    required this.reps,
    required this.isSetDone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text("Target: $sets × $reps"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(sets, (k) {
                final setNo = k + 1;
                return FilterChip(
                  label: Text("Set $setNo"),
                  selected: isSetDone(setNo),
                  onSelected: (v) => onToggle(setNo, v),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
