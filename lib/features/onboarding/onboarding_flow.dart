import 'package:flutter/material.dart';

// ——— MODELS / ENUMS ———

enum SexAtBirth { male, female }

enum Goal { gain, lose, maintain }

enum ProgramCategory {
  bodybuilding,
  hiit,
  calisthenics,
  pilates,
  weightLoss,
  homeStart,   // overweight-friendly (renamed)
  glutesFocus, // women-focused glutes & lower body
}

class WorkoutProgram {
  final ProgramCategory id;
  final String name;
  final String description;
  final List<String> tags;
  final List<SexAtBirth> recommendedFor;

  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.recommendedFor,
  });
}

class OnboardingResult {
  final SexAtBirth sexAtBirth;
  final Goal goal;
  final ProgramCategory selectedProgram;
  final bool includeChestWorkForFemale; // if female, allow opt-out of chest

  const OnboardingResult({
    required this.sexAtBirth,
    required this.goal,
    required this.selectedProgram,
    required this.includeChestWorkForFemale,
  });
}

// ——— STATIC CATALOGUE (used by the menu too) ———

const programsCatalog = <WorkoutProgram>[
  WorkoutProgram(
    id: ProgramCategory.bodybuilding,
    name: 'Bodybuilding / Hypertrophy',
    description: 'Classic splits (PPL, upper/lower). Progressive overload.',
    tags: ['gym', 'muscle', 'progressive overload'],
    recommendedFor: [SexAtBirth.male, SexAtBirth.female],
  ),
  WorkoutProgram(
    id: ProgramCategory.hiit,
    name: 'HIIT',
    description: 'Short, intense circuits for conditioning & calorie burn.',
    tags: ['circuits', 'timer', 'cardio+strength'],
    recommendedFor: [SexAtBirth.male, SexAtBirth.female],
  ),
  WorkoutProgram(
    id: ProgramCategory.calisthenics,
    name: 'Calisthenics',
    description: 'Bodyweight strength & skill progressions.',
    tags: ['bodyweight', 'progressions'],
    recommendedFor: [SexAtBirth.male, SexAtBirth.female],
  ),
  WorkoutProgram(
    id: ProgramCategory.pilates,
    name: 'Pilates (Core & Mobility)',
    description: 'Low-impact, controlled moves for core, posture, mobility.',
    tags: ['low impact', 'core', 'mobility'],
    recommendedFor: [SexAtBirth.male, SexAtBirth.female],
  ),
  WorkoutProgram(
    id: ProgramCategory.weightLoss,
    name: 'Weight Loss / Conditioning',
    description: 'Metabolic, beginner-friendly sessions (low-impact options).',
    tags: ['metabolic', 'conditioning', 'fat loss'],
    recommendedFor: [SexAtBirth.male, SexAtBirth.female],
  ),
  WorkoutProgram(
    id: ProgramCategory.homeStart,
    name: 'Home Start',
    description: 'Overweight-friendly, safe at-home plan (chair/wall support).',
    tags: ['at-home', 'low impact', 'beginner'],
    recommendedFor: [SexAtBirth.male, SexAtBirth.female],
  ),
  WorkoutProgram(
    id: ProgramCategory.glutesFocus,
    name: 'Women: Glutes & Lower Body',
    description: 'Female-focused plan emphasizing glutes, legs, hip stability.',
    tags: ['glutes', 'lower body', 'female'],
    recommendedFor: [SexAtBirth.female],
  ),
];

// ——— Onboarding UI (you can use later; not required to see the menu now) ———

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  SexAtBirth? sexAtBirth;
  Goal goal = Goal.maintain;
  ProgramCategory? selectedProgram;
  bool includeChestForFemale = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BOU • Onboarding'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(1, 'Sex at birth'),
            RadioListTile<SexAtBirth>(
              value: SexAtBirth.male,
              groupValue: sexAtBirth,
              onChanged: (v) => setState(() => sexAtBirth = v),
              title: const Text('Male'),
              subtitle: const Text('Were you born with a male body?'),
            ),
            RadioListTile<SexAtBirth>(
              value: SexAtBirth.female,
              groupValue: sexAtBirth,
              onChanged: (v) => setState(() => sexAtBirth = v),
              title: const Text('Female'),
              subtitle: const Text('Were you born with a female body?'),
            ),
            const SizedBox(height: 12),
            _header(2, 'Goal'),
            Wrap(
              spacing: 8,
              children: Goal.values.map((g) {
                final label = switch (g) {
                  Goal.gain => 'Gain muscle',
                  Goal.lose => 'Lose fat',
                  Goal.maintain => 'Maintain',
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: g == goal,
                  onSelected: (_) => setState(() => goal = g),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _header(3, 'Choose your program'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: programsCatalog.map((p) {
                return ChoiceChip(
                  label: Text(p.name),
                  selected: p.id == selectedProgram,
                  onSelected: (_) async {
                    if (sexAtBirth == SexAtBirth.female) {
                      final include = await showModalBottomSheet<bool>(
                        context: context,
                        builder: (_) => const _ChestExplainerSheet(),
                      );
                      if (include != null) includeChestForFemale = include;
                    }
                    setState(() => selectedProgram = p.id);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: sexAtBirth != null && selectedProgram != null
                  ? () {
                      Navigator.of(context).pop(OnboardingResult(
                        sexAtBirth: sexAtBirth!,
                        goal: goal,
                        selectedProgram: selectedProgram!,
                        includeChestWorkForFemale: includeChestForFemale,
                      ));
                    }
                  : null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Finish & start training'),
            )
          ],
        ),
      ),
    );
  }

  Widget _header(int i, String t) => Row(
        children: [
          CircleAvatar(radius: 14, child: Text('$i')),
          const SizedBox(width: 8),
          Text(t, style: Theme.of(context).textTheme.titleMedium),
        ],
      );
}

class _ChestExplainerSheet extends StatefulWidget {
  const _ChestExplainerSheet();

  @override
  State<_ChestExplainerSheet> createState() => _ChestExplainerSheetState();
}

class _ChestExplainerSheetState extends State<_ChestExplainerSheet> {
  bool includeChest = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text('Chest training for women', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Breasts are mostly fatty tissue that sits on top of the pectoral muscles. '
            'Training chest will not reduce breast size. It strengthens the upper body and posture. '
            'If you prefer to skip chest, we’ll substitute with back/shoulder/glute work.',
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: includeChest,
            onChanged: (v) => setState(() => includeChest = v),
            title: const Text('Include chest exercises in my plan'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                  label: const Text('Skip chest'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(includeChest),
                  icon: const Icon(Icons.check),
                  label: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
