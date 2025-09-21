// lib/features/coach/smart_coach.dart
import 'package:flutter/material.dart';
import '../../core/hive_service.dart';

// -----------------------------
// DATA MODELS
// -----------------------------

enum EffortTag { easy, solid, grind, nearFailure, failure }

enum TipKind {
  pushBeyond,
  dropset,
  amrap,
  tempo,
  restLonger,
  hydrate,
  breathe,
  posture,
  finishOptions // final set => offer choices
}

class SetPlan {
  final int targetReps;
  final double? targetLoadKg; // null for bodyweight
  final Duration rest;
  const SetPlan({required this.targetReps, this.targetLoadKg, required this.rest});
}

class SetResult {
  final int actualReps;
  final double? actualLoadKg;
  final int rir; // Reps In Reserve (0 = failure)
  final Duration restTaken;
  final Duration timeUnderTension;
  final EffortTag effort;

  // early stop / incomplete
  final bool completed; // finished as planned
  final bool quit; // stopped early (DNF)
  final int? stoppedAtRep;
  final String? reason;

  const SetResult({
    required this.actualReps,
    this.actualLoadKg,
    required this.rir,
    required this.restTaken,
    required this.timeUnderTension,
    required this.effort,
    this.completed = true,
    this.quit = false,
    this.stoppedAtRep,
    this.reason,
  });
}

class ExercisePlan {
  final String id;
  final String name;
  final List<SetPlan> sets;
  final bool isIsolation;
  final bool allowDropset;
  final bool allowAmrapFinal;
  const ExercisePlan({
    required this.id,
    required this.name,
    required this.sets,
    this.isIsolation = false,
    this.allowDropset = true,
    this.allowAmrapFinal = true,
  });
}

class ExerciseProgress {
  final String exerciseId;
  final List<SetResult> results;
  const ExerciseProgress({required this.exerciseId, required this.results});
}

class SessionState {
  final String sessionId;
  final DateTime start;
  final List<ExercisePlan> plan;
  final Map<String, ExerciseProgress> progress; // exerciseId -> progress
  final bool isDeloadWeek;
  const SessionState({
    required this.sessionId,
    required this.start,
    required this.plan,
    required this.progress,
    this.isDeloadWeek = false,
  });

  int get totalSetsCompleted => progress.values.fold(0, (a, e) => a + e.results.length);
}

class UserProfile {
  final String userId;
  final int weeklyBonusKcalSoFar;
  final bool ibs;
  final bool lactoseFree;
  final int baselineDailyKcal;
  const UserProfile({
    required this.userId,
    required this.weeklyBonusKcalSoFar,
    required this.ibs,
    required this.lactoseFree,
    required this.baselineDailyKcal,
  });

  UserProfile copyWith({int? weeklyBonusKcalSoFar, int? baselineDailyKcal}) => UserProfile(
        userId: userId,
        weeklyBonusKcalSoFar: weeklyBonusKcalSoFar ?? this.weeklyBonusKcalSoFar,
        ibs: ibs,
        lactoseFree: lactoseFree,
        baselineDailyKcal: baselineDailyKcal ?? this.baselineDailyKcal,
      );
}

// -----------------------------
// EFFORT + RANKING SCORING
// -----------------------------

class EffortScore {
  final int score; // 0-100 per session (soft cap 120)
  final int volumeBump; // proxy for work done
  final int incompletes;
  final int quits;
  const EffortScore(this.score, this.volumeBump, this.incompletes, this.quits);
}

class Scoring {
  static EffortScore sessionEffort(SessionState s) {
    int score = 0;
    int volume = 0; // naive: reps*load; bodyweight approximated
    int incompletes = 0;
    int quits = 0;

    for (final p in s.progress.values) {
      for (int i = 0; i < p.results.length; i++) {
        final r = p.results[i];
        final load = (r.actualLoadKg ?? 0);
        volume += (r.actualReps * (load > 0 ? load : 0.33 * 70 /* assume 70kg */)).round();

        switch (r.effort) {
          case EffortTag.easy:
            score += 1;
            break;
          case EffortTag.solid:
            score += 3;
            break;
          case EffortTag.grind:
            score += 6;
            break;
          case EffortTag.nearFailure:
            score += 10;
            break;
          case EffortTag.failure:
            score += 12;
            break;
        }

        if (!r.completed) {
          incompletes += 1;
          score -= 4;
        }
        if (r.quit) {
          quits += 1;
          score -= 10;
        }

        if (i > 0) {
          final prev = p.results[i - 1];
          if (r.actualReps > prev.actualReps || (r.actualLoadKg ?? 0) > (prev.actualLoadKg ?? 0)) {
            score += 4;
          }
        }
      }
    }
    score = score.clamp(0, 120);
    return EffortScore(score, volume, incompletes, quits);
  }

  static int rankingPoints(EffortScore e) {
    if (e.score <= 80) return e.score;
    return 80 + ((e.score - 80) * 0.5).round();
  }
}

// -----------------------------
// COACH TIP ENGINE
// -----------------------------

class CoachRuleContext {
  final ExercisePlan plan;
  final List<SetResult> completedSets;
  final int nextSetIndex; // 0-based
  final bool isFinalSet;
  const CoachRuleContext({
    required this.plan,
    required this.completedSets,
    required this.nextSetIndex,
    required this.isFinalSet,
  });
}

class CoachTip {
  final TipKind kind;
  final String title;
  final String subtitle;
  final Duration suggestedRest;
  final void Function()? onAccept;
  CoachTip({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.suggestedRest,
    this.onAccept,
  });
}

class CoachEngine {
  static CoachTip? nextTip(CoachRuleContext c) {
    if (c.completedSets.isEmpty) {
      return CoachTip(
        kind: TipKind.breathe,
        title: "Warm-up done?",
        subtitle: "Lock in form. First working set: smooth tempo, full range.",
        suggestedRest: c.plan.sets.first.rest,
      );
    }

    final last = c.completedSets.last;

    if (last.quit) {
      return CoachTip(
        kind: TipKind.restLonger,
        title: "Reset & recover",
        subtitle: (last.reason ?? "Stopped early") + ". Lower load 10–20% or drop 2 reps next set.",
        suggestedRest: last.restTaken + const Duration(seconds: 60),
      );
    }

    if (!last.completed) {
      return CoachTip(
        kind: TipKind.posture,
        title: "Missed a rep? No stress.",
        subtitle: "Next set: subtract 1 rep or -2.5kg and nail the form.",
        suggestedRest: last.restTaken + const Duration(seconds: 20),
      );
    }

    if (last.rir <= 1 && !c.isFinalSet) {
      return CoachTip(
        kind: TipKind.restLonger,
        title: "Big set — breathe.",
        subtitle: "You were ~${last.rir} RIR. Take +30–45s and keep it clean.",
        suggestedRest: last.restTaken + const Duration(seconds: 40),
      );
    }

    if (!c.isFinalSet && (c.nextSetIndex == 2 || c.nextSetIndex == 3) && last.effort.index >= EffortTag.solid.index) {
      return CoachTip(
        kind: TipKind.pushBeyond,
        title: "BOU moment: beat your last set.",
        subtitle: "Add 1 rep or +2.5kg if bar speed was good.",
        suggestedRest: c.plan.sets[c.nextSetIndex.clamp(0, c.plan.sets.length - 1)].rest,
      );
    }

    if (!c.isFinalSet && c.plan.isIsolation && c.plan.allowDropset && last.effort.index >= EffortTag.grind.index) {
      return CoachTip(
        kind: TipKind.dropset,
        title: "Optional dropset",
        subtitle: "Strip ~20% load and hit 8–12 quality reps.",
        suggestedRest: const Duration(seconds: 20),
      );
    }

    if (c.isFinalSet) {
      return CoachTip(
        kind: TipKind.finishOptions,
        title: "Feeling strong?",
        subtitle: "Bonus set (custom) • Back-off AMRAP • Move to accessory • Or finish.",
        suggestedRest: const Duration(seconds: 30),
      );
    }

    return CoachTip(
      kind: TipKind.posture,
      title: "Form first",
      subtitle: "Brace, control the eccentric, full range.",
      suggestedRest: c.plan.sets[c.nextSetIndex.clamp(0, c.plan.sets.length - 1)].rest,
    );
  }
}

// -----------------------------
// ADAPTIVE NUTRITION
// -----------------------------

class NutritionDecision {
  final int bonusKcalToday;
  final int newWeeklyBonusTotal;
  final String rationale;
  const NutritionDecision(this.bonusKcalToday, this.newWeeklyBonusTotal, this.rationale);
}

class AdaptiveNutrition {
  static const int weeklyBonusCap = 900;
  static const int singleDayCap = 300;

  static NutritionDecision decide({
    required UserProfile user,
    required EffortScore effort,
    required DateTime now,
  }) {
    int bonus;
    if (effort.score < 40) {
      bonus = 0;
    } else if (effort.score < 60) {
      bonus = 100;
    } else if (effort.score < 80) {
      bonus = 150;
    } else if (effort.score < 100) {
      bonus = 200;
    } else {
      bonus = 250;
    }

    bonus = bonus.clamp(0, singleDayCap);
    final projectedWeekly = user.weeklyBonusKcalSoFar + bonus;
    if (projectedWeekly > weeklyBonusCap) {
      bonus = (weeklyBonusCap - user.weeklyBonusKcalSoFar).clamp(0, singleDayCap);
    }

    final shiftToTomorrow = now.hour >= 19;
    final rationale = shiftToTomorrow
        ? "High effort → +$bonus kcal on tomorrow (late session)."
        : "High effort → +$bonus kcal on today.";

    return NutritionDecision(bonus, user.weeklyBonusKcalSoFar + bonus, rationale);
  }
}

// -----------------------------
// POPUPS (Set outcome, normal tip, finish options, custom set)
// -----------------------------

class SetOutcomeSheet extends StatefulWidget {
  final int targetReps;
  const SetOutcomeSheet({super.key, required this.targetReps});

  @override
  State<SetOutcomeSheet> createState() => _SetOutcomeSheetState();
}

class _SetOutcomeSheetState extends State<SetOutcomeSheet> {
  bool quit = false;
  int actualReps = 0;
  int rir = 2;
  String? reason;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Log Set Outcome", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(children: [
                  const Text("Quit early"),
                  const SizedBox(width: 8),
                  Switch(value: quit, onChanged: (v) => setState(() => quit = v)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text("Reps (target ${widget.targetReps})"),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: actualReps.toDouble(),
                      min: 0,
                      max: (widget.targetReps + 5).toDouble(),
                      divisions: widget.targetReps + 5,
                      label: "$actualReps",
                      onChanged: (v) => setState(() => actualReps = v.round()),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Text("Reps left in tank (RIR)"),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: rir.toDouble(),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: "$rir",
                      onChanged: (v) => setState(() => rir = v.round()),
                    ),
                  ),
                ]),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Reason (optional: pain, time, etc.)",
                  ),
                  onChanged: (t) => reason = t,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, {
                        'quit': quit,
                        'actualReps': actualReps,
                        'rir': rir,
                        'reason': reason,
                      }),
                      child: const Text("Save"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text("Cancel"),
                  ),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoachTipSheet extends StatelessWidget {
  final CoachTip tip;
  const CoachTipSheet({super.key, required this.tip});

  IconData _iconFor(TipKind k) {
    switch (k) {
      case TipKind.pushBeyond:
        return Icons.trending_up;
      case TipKind.dropset:
        return Icons.flash_on;
      case TipKind.amrap:
        return Icons.whatshot;
      case TipKind.tempo:
        return Icons.speed;
      case TipKind.restLonger:
        return Icons.hourglass_bottom;
      case TipKind.hydrate:
        return Icons.local_drink;
      case TipKind.breathe:
        return Icons.air;
      case TipKind.posture:
        return Icons.fitness_center;
      case TipKind.finishOptions:
        return Icons.add_task;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Icon(_iconFor(tip.kind))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip.title, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(tip.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 18),
                    const SizedBox(width: 6),
                    Text("Suggested rest: ~${tip.suggestedRest.inSeconds}s"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          tip.onAccept?.call();
                          Navigator.pop(context, true);
                        },
                        child: const Text("Got it"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Skip"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum FinishChoice { bonusSet, amrapBackoff, moveAccessory, done }

class FinishOptionsSheet extends StatelessWidget {
  const FinishOptionsSheet({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feeling strong?', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Bonus set (customise yourself)'),
                  subtitle: const Text('Pick your own reps/load and log it.'),
                  onTap: () => Navigator.pop(context, FinishChoice.bonusSet),
                ),
                ListTile(
                  leading: const Icon(Icons.whatshot),
                  title: const Text('Back-off AMRAP (~-15% load)'),
                  subtitle: const Text('As many clean reps as possible, leave 1–2 RIR.'),
                  onTap: () => Navigator.pop(context, FinishChoice.amrapBackoff),
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Move to accessory'),
                  subtitle: const Text('Continue workout with the next exercise.'),
                  onTap: () => Navigator.pop(context, FinishChoice.moveAccessory),
                ),
                const Divider(),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, FinishChoice.done),
                    child: const Text('Finish exercise'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Simple custom-set entry (load, reps, RIR; AMRAP toggle)
class CustomSetSheet extends StatefulWidget {
  final double? suggestedLoadKg;
  final bool amrapDefault;
  const CustomSetSheet({super.key, this.suggestedLoadKg, this.amrapDefault = false});

  @override
  State<CustomSetSheet> createState() => _CustomSetSheetState();
}

class _CustomSetSheetState extends State<CustomSetSheet> {
  final _loadCtrl = TextEditingController();
  final _repsCtrl = TextEditingController(text: "8");
  int rir = 2;
  bool amrap = false;

  @override
  void initState() {
    super.initState();
    amrap = widget.amrapDefault;
    if (widget.suggestedLoadKg != null) {
      _loadCtrl.text = widget.suggestedLoadKg!.toStringAsFixed(1);
    }
    if (amrap) _repsCtrl.text = "0"; // AMRAP => reps decided by user effort
  }

  @override
  void dispose() {
    _loadCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Custom bonus set", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _loadCtrl,
                      decoration: const InputDecoration(labelText: "Load (kg) — leave empty for bodyweight"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repsCtrl,
                      decoration: const InputDecoration(labelText: "Reps (0 = AMRAP)"),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Text("Reps left in tank (RIR)"),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: rir.toDouble(),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: "$rir",
                      onChanged: (v) => setState(() => rir = v.round()),
                    ),
                  ),
                ]),
                Row(
                  children: [
                    const Text("AMRAP"),
                    Switch(
                      value: amrap,
                      onChanged: (v) {
                        setState(() {
                          amrap = v;
                          if (amrap) {
                            _repsCtrl.text = "0";
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Flexible(child: Text("As many reps as possible; log real reps after.")),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final load = _loadCtrl.text.trim().isEmpty ? null : double.tryParse(_loadCtrl.text.trim());
                        final reps = int.tryParse(_repsCtrl.text.trim()) ?? 0;
                        Navigator.pop(context, {
                          'loadKg': load,
                          'reps': reps,
                          'rir': rir,
                          'amrap': amrap,
                        });
                      },
                      child: const Text("Add set"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text("Cancel"),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------
// CONTROLLER
// -----------------------------

class SmartCoachController {
  // Quick form to log outcome (quit/missed reps/RIR)
  Future<SetResult?> logSetOutcome({
    required BuildContext context,
    required SetPlan target,
    required double? loadKg,
  }) async {
    final data = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetOutcomeSheet(targetReps: target.targetReps),
    );

    if (data == null) return null;

    final quit = data['quit'] == true;
    final reps = (data['actualReps'] as int?) ?? 0;
    final rir = (data['rir'] as int?) ?? 2;
    final reason = (data['reason'] as String?);

    return SetResult(
      actualReps: reps,
      actualLoadKg: loadKg,
      rir: rir,
      restTaken: target.rest,
      timeUnderTension: const Duration(seconds: 0),
      effort: rir <= 1 ? EffortTag.nearFailure : EffortTag.solid,
      completed: !quit && reps >= target.targetReps,
      quit: quit,
      stoppedAtRep: quit ? reps : (reps < target.targetReps ? reps : null),
      reason: reason,
    );
  }

  // Ask for final-set finish choice; returns the choice if shown
  Future<FinishChoice?> _showFinishOptions(BuildContext context) async {
    return await showModalBottomSheet<FinishChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FinishOptionsSheet(),
    );
  }

  // Custom set prompt (bonus or back-off AMRAP)
  Future<SetResult?> promptCustomSet(BuildContext context, {double? suggestedLoadKg, bool amrap = false}) async {
    final data = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomSetSheet(suggestedLoadKg: suggestedLoadKg, amrapDefault: amrap),
    );
    if (data == null) return null;

    final load = data['loadKg'] as double?;
    final reps = (data['reps'] as int?) ?? 0;
    final rir = (data['rir'] as int?) ?? 2;

    return SetResult(
      actualReps: reps,
      actualLoadKg: load,
      rir: rir,
      restTaken: const Duration(seconds: 90),
      timeUnderTension: const Duration(seconds: 0),
      effort: rir <= 1 ? EffortTag.nearFailure : EffortTag.solid,
      completed: true,
      quit: false,
    );
    // Note: If AMRAP, reps=0 here; you can re-open a quick confirm after the set to log actual reps.
  }

  /// Show coach tip or final options.
  /// Returns a FinishChoice when final-set options were shown; otherwise null.
  Future<FinishChoice?> onSetCompleted({
    required BuildContext context,
    required ExercisePlan plan,
    required List<SetResult> doneSoFar,
    required int nextSetIndex,
  }) async {
    final tip = CoachEngine.nextTip(CoachRuleContext(
      plan: plan,
      completedSets: doneSoFar,
      nextSetIndex: nextSetIndex,
      isFinalSet: nextSetIndex >= plan.sets.length - 1,
    ));

    if (tip == null || !context.mounted) return null;

    final isFinal = nextSetIndex >= plan.sets.length - 1;
    if (isFinal && tip.kind == TipKind.finishOptions) {
      return await _showFinishOptions(context);
    }

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CoachTipSheet(tip: tip),
    );
    return null;
  }

  // End of session → compute effort, points, and persist kcal boosts
  Future<void> onSessionCompleted({
    required UserProfile user,
    required SessionState session,
  }) async {
    final effort = Scoring.sessionEffort(session);
    final points = Scoring.rankingPoints(effort);

    final now = DateTime.now();
    final decision = AdaptiveNutrition.decide(user: user, effort: effort, now: now);

    // Persist kcal boosts with Hive
    await HiveService.addWeeklyBonusKcal(decision.bonusKcalToday, now);
    await HiveService.addDailyBonusKcal(
      (now.hour >= 19) ? now.add(const Duration(days: 1)) : now,
      decision.bonusKcalToday,
    );

    debugPrint(
        "Session effort=${effort.score}, inc=${effort.incompletes}, quits=${effort.quits}, points=$points, kcal+${decision.bonusKcalToday}");
  }
}

// -----------------------------
// MINIMAL SCREEN (for testing)
// -----------------------------

class MinimalCoachScreen extends StatefulWidget {
  const MinimalCoachScreen({super.key});
  @override
  State<MinimalCoachScreen> createState() => _MinimalCoachScreenState();
}

class _MinimalCoachScreenState extends State<MinimalCoachScreen> {
  final controller = SmartCoachController();

  // simple 3-set exercise
  final plan = ExercisePlan(
    id: 'incline_db_press',
    name: 'Incline DB Press',
    isIsolation: false,
    sets: const [
      SetPlan(targetReps: 10, targetLoadKg: 22.5, rest: Duration(seconds: 90)),
      SetPlan(targetReps: 10, targetLoadKg: 22.5, rest: Duration(seconds: 90)),
      SetPlan(targetReps: 8, targetLoadKg: 25.0, rest: Duration(seconds: 120)),
    ],
  );

  final List<SetResult> doneSoFar = [];

  UserProfile get user => const UserProfile(
        userId: "demo",
        weeklyBonusKcalSoFar: 0,
        ibs: false,
        lactoseFree: true,
        baselineDailyKcal: 2600,
      );

  SessionState get session => SessionState(
        sessionId: "demo-session",
        start: DateTime.now(),
        plan: [plan],
        progress: {
          plan.id: ExerciseProgress(exerciseId: plan.id, results: doneSoFar),
        },
      );

  int nextSetIndex = 0;

  double? _lastLoad() {
    if (doneSoFar.isEmpty) return plan.sets.first.targetLoadKg;
    final loads = doneSoFar.map((r) => r.actualLoadKg).whereType<double>().toList();
    return loads.isNotEmpty ? loads.last : plan.sets.first.targetLoadKg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Coach — Minimal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Next set index: $nextSetIndex of ${plan.sets.length}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Log current set
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (nextSetIndex >= plan.sets.length) {
                    // Offer finish options again to add bonus sets if desired
                    final choice = await controller.onSetCompleted(
                      context: context,
                      plan: plan,
                      doneSoFar: doneSoFar,
                      nextSetIndex: nextSetIndex, // final
                    );

                    if (choice == FinishChoice.bonusSet) {
                      final r = await controller.promptCustomSet(context, suggestedLoadKg: _lastLoad());
                      if (r != null) {
                        doneSoFar.add(r);
                        setState(() {}); // stay at final index
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bonus set added.')));
                      }
                    } else if (choice == FinishChoice.amrapBackoff) {
                      final base = _lastLoad();
                      final suggested = (base != null) ? (base * 0.85) : null; // -15%
                      final r = await controller.promptCustomSet(context, suggestedLoadKg: suggested, amrap: true);
                      if (r != null) {
                        doneSoFar.add(r);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Back-off AMRAP added.')));
                      }
                    }
                    return;
                  }

                  final r = await controller.logSetOutcome(
                    context: context,
                    target: plan.sets[nextSetIndex],
                    loadKg: plan.sets[nextSetIndex].targetLoadKg,
                  );
                  if (r == null) return;

                  doneSoFar.add(r);
                  setState(() => nextSetIndex += 1);

                  final choice = await controller.onSetCompleted(
                    context: context,
                    plan: plan,
                    doneSoFar: doneSoFar,
                    nextSetIndex: nextSetIndex,
                  );

                  // if final-set options were shown and user picked something, handle it
                  if (choice == FinishChoice.bonusSet) {
                    final r2 = await controller.promptCustomSet(context, suggestedLoadKg: _lastLoad());
                    if (r2 != null) {
                      doneSoFar.add(r2);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bonus set added.')));
                    }
                  } else if (choice == FinishChoice.amrapBackoff) {
                    final base = _lastLoad();
                    final suggested = (base != null) ? (base * 0.85) : null; // -15%
                    final r2 = await controller.promptCustomSet(context, suggestedLoadKg: suggested, amrap: true);
                    if (r2 != null) {
                      doneSoFar.add(r2);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Back-off AMRAP added.')));
                    }
                  }
                },
                child: const Text('Log current set / Finish options'),
              ),
            ),
            const SizedBox(height: 12),

            // Force tip (debug)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  if (doneSoFar.isEmpty) {
                    doneSoFar.add(const SetResult(
                      actualReps: 10,
                      actualLoadKg: 22.5,
                      rir: 2,
                      restTaken: Duration(seconds: 90),
                      timeUnderTension: Duration(seconds: 30),
                      effort: EffortTag.grind,
                    ));
                    nextSetIndex = 1;
                  }
                  await controller.onSetCompleted(
                    context: context,
                    plan: plan,
                    doneSoFar: doneSoFar,
                    nextSetIndex: nextSetIndex,
                  );
                },
                child: const Text('FORCE TIP (debug)'),
              ),
            ),

            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: plan.sets.length + (doneSoFar.length > plan.sets.length ? (doneSoFar.length - plan.sets.length) : 0),
                itemBuilder: (context, i) {
                  final done = i < doneSoFar.length ? doneSoFar[i] : null;
                  return ListTile(
                    leading: Text('Set ${i + 1}'),
                    title: Text(done == null
                        ? 'Not logged'
                        : 'Reps ${done.actualReps}'
                            '${done.quit ? " (QUIT)" : (!done.completed ? " (incomplete)" : "")}'
                            '${done.actualLoadKg != null ? " @ ${done.actualLoadKg}kg" : ""}'
                            ' • RIR ${done.rir}'),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () async {
                  await controller.onSessionCompleted(user: user, session: session);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Session saved. Nutrition adjusted.")),
                    );
                  }
                },
                child: const Text('Finish Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
