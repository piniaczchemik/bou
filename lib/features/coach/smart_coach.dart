// BOU: Smart Coach + Adaptive Nutrition (single-file starter)
// Drop this into lib/features/coach/smart_coach.dart (or anywhere) and wire the hooks noted below.
// Assumes Flutter + Dart only (no external deps). Hive/Firestore integration points are marked TODO.

import 'package:flutter/material.dart';

// -----------------------------
// DATA MODELS
// -----------------------------

enum EffortTag { easy, solid, grind, nearFailure, failure }

enum TipKind { pushBeyond, dropset, amrap, tempo, restLonger, hydrate, breathe, posture }

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
  final Duration timeUnderTension; // optional estimate
  final EffortTag effort;
  const SetResult({
    required this.actualReps,
    this.actualLoadKg,
    required this.rir,
    required this.restTaken,
    required this.timeUnderTension,
    required this.effort,
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
  final int weeklyBonusKcalSoFar; // rolling total for current week
  final bool ibs;
  final bool lactoseFree;
  final int baselineDailyKcal; // from onboarding/TDEE goal
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
  const EffortScore(this.score, this.volumeBump);
}

class Scoring {
  // Compute a session effort score from set results.
  static EffortScore sessionEffort(SessionState s) {
    int score = 0;
    int volume = 0; // naive: reps*load; bodyweight ~ load 0.33 * body mass (not tracked here)

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
        // Small bonus for beating previous set within same exercise
        if (i > 0) {
          final prev = p.results[i - 1];
          if (r.actualReps > prev.actualReps || (r.actualLoadKg ?? 0) > (prev.actualLoadKg ?? 0)) {
            score += 4;
          }
        }
      }
    }
    // Cap to keep nutrition boosts sane
    score = score.clamp(0, 120);
    return EffortScore(score, volume);
  }

  // Convert effort score to ranking points (gamification)
  static int rankingPoints(EffortScore e) {
    // Linear with diminishing bump above 80
    if (e.score <= 80) return e.score; // 1:1 up to 80
    return 80 + ((e.score - 80) * 0.5).round(); // softer above 80
  }
}

// -----------------------------
// COACH TIP ENGINE (rule-based)
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
  final void Function()? onAccept; // e.g., convert next set to AMRAP or Dropset
  CoachTip({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.suggestedRest,
    this.onAccept,
  });
}

class CoachEngine {
  // Main entry: provide a tip between sets
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

    // 1) Near failure early? Suggest longer rest.
    if (last.rir <= 1 && !c.isFinalSet) {
      return CoachTip(
        kind: TipKind.restLonger,
        title: "Big set — breathe.",
        subtitle: "You were ~${last.rir} RIR. Take +30–45s and keep form pristine on the next set.",
        suggestedRest: last.restTaken + const Duration(seconds: 40),
      );
    }

    // 2) Mid-session push-beyond cue (set 2/3 or 3/4)
    if ((c.nextSetIndex == 2 || c.nextSetIndex == 3) && last.effort.index >= EffortTag.solid.index) {
      return CoachTip(
        kind: TipKind.pushBeyond,
        title: "BOU moment: beat your last set.",
        subtitle: "Add 1 rep or +2.5kg if bar speed was good.",
        suggestedRest: c.plan.sets[c.nextSetIndex.clamp(0, c.plan.sets.length - 1)].rest,
      );
    }

    // 3) Dropset suggestion if isolation + grind/nearFailure and allowed
    if (c.plan.isIsolation && c.plan.allowDropset && last.effort.index >= EffortTag.grind.index && !c.isFinalSet) {
      return CoachTip(
        kind: TipKind.dropset,
        title: "Optional dropset",
        subtitle: "Strip ~20% load and hit 8–12 quality reps. Pump > ego.",
        suggestedRest: const Duration(seconds: 20),
        onAccept: () {
          // TODO: mark next set as dropset in your controller/state
        },
      );
    }

    // 4) Final-set AMRAP if energy remains and allowed
    if (c.isFinalSet && c.plan.allowAmrapFinal && last.rir >= 2) {
      return CoachTip(
        kind: TipKind.amrap,
        title: "Final set: AMRAP",
        subtitle: "Leave 1–2 RIR. Count clean reps only.",
        suggestedRest: const Duration(seconds: 30),
        onAccept: () {
          // TODO: mark final set as AMRAP in your controller/state
        },
      );
    }

    // 5) General technique cues fallback
    return CoachTip(
      kind: TipKind.posture,
      title: "Form first",
      subtitle: "Brace, control the eccentric, drive through full range.",
      suggestedRest: c.plan.sets[c.nextSetIndex.clamp(0, c.plan.sets.length - 1)].rest,
    );
  }
}

// -----------------------------
// ADAPTIVE NUTRITION ENGINE
// -----------------------------

class NutritionDecision {
  final int bonusKcalToday; // apply today (or next day post-PM session)
  final int newWeeklyBonusTotal;
  final String rationale;
  const NutritionDecision(this.bonusKcalToday, this.newWeeklyBonusTotal, this.rationale);
}

class AdaptiveNutrition {
  // Policy knobs (tune to taste)
  static const int weeklyBonusCap = 900; // max +900 kcal / week from boosts
  static const int singleDayCap = 300;   // max +300 kcal on a day

  static NutritionDecision decide({
    required UserProfile user,
    required EffortScore effort,
    required DateTime now,
  }) {
    // Map effort score → kcal bonus
    int bonus;
    if (effort.score < 40) {
      bonus = 0; // recovery focus
    } else if (effort.score < 60) {
      bonus = 100;
    } else if (effort.score < 80) {
      bonus = 150;
    } else if (effort.score < 100) {
      bonus = 200;
    } else {
      bonus = 250; // monster session
    }

    // Respect caps
    bonus = bonus.clamp(0, singleDayCap);
    final projectedWeekly = user.weeklyBonusKcalSoFar + bonus;
    if (projectedWeekly > weeklyBonusCap) {
      bonus = (weeklyBonusCap - user.weeklyBonusKcalSoFar).clamp(0, singleDayCap);
    }

    // Optional: Shift to next day if session finished late (post 7pm)
    final bool shiftToTomorrow = now.hour >= 19;

    final rationale = shiftToTomorrow
        ? "High effort day → +${bonus} kcal on tomorrow's plan (late session)."
        : "High effort day → +${bonus} kcal on today's plan.";

    return NutritionDecision(bonus, user.weeklyBonusKcalSoFar + bonus, rationale);
  }
}

// -----------------------------
// POPUP UI
// -----------------------------

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
                    Icon(Icons.timer, size: 18),
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

// -----------------------------
// CONTROLLER WIRES (call these from your Workout screen)
// -----------------------------

class SmartCoachController {
  // TODO inject persistence + ranking services
  Future<void> onSetCompleted({
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

    if (tip != null && context.mounted) {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: false,
        backgroundColor: Colors.transparent,
        builder: (_) => CoachTipSheet(tip: tip),
      );
    }
  }

  // Call once per session end to update ranking + nutrition
  Future<void> onSessionCompleted({
    required UserProfile user,
    required SessionState session,
  }) async {
    final effort = Scoring.sessionEffort(session);

    // Ranking update (hook into your backend later)
    final points = Scoring.rankingPoints(effort);
    // TODO: push points to Firestore/Supabase in the future

    // Adaptive nutrition decision
    final decision = AdaptiveNutrition.decide(user: user, effort: effort, now: DateTime.now());

    // TODO: Persist today's (or tomorrow's) plan bonus kcal into Hive "meal_targets" box
    // Example pseudo:
    // final box = await Hive.openBox("meal_targets");
    // final key = shiftToTomorrow ? tomorrowKey : todayKey;
    // box.put(key, (box.get(key) ?? baseTarget) + decision.bonusKcalToday);

    // TODO: Persist user.weeklyBonusKcalSoFar = decision.newWeeklyBonusTotal

    debugPrint("Session effort=${effort.score}, points=$points, kcal+${decision.bonusKcalToday}");
  }
}

// -----------------------------
// MINI DEMO WIDGET (for quick testing)
// -----------------------------

class DemoSmartCoachButton extends StatelessWidget {
  const DemoSmartCoachButton({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = ExercisePlan(
      id: "db_incline_dumbbell_press",
      name: "Incline DB Press",
      isIsolation: false,
      sets: const [
        SetPlan(targetReps: 10, targetLoadKg: 22.5, rest: Duration(seconds: 90)),
        SetPlan(targetReps: 10, targetLoadKg: 22.5, rest: Duration(seconds: 90)),
        SetPlan(targetReps: 8, targetLoadKg: 25, rest: Duration(seconds: 120)),
      ],
    );

    final done = <SetResult>[
      const SetResult(actualReps: 10, actualLoadKg: 22.5, rir: 3, restTaken: Duration(seconds: 95), timeUnderTension: Duration(seconds: 28), effort: EffortTag.solid),
      const SetResult(actualReps: 10, actualLoadKg: 22.5, rir: 2, restTaken: Duration(seconds: 90), timeUnderTension: Duration(seconds: 30), effort: EffortTag.grind),
    ];

    final controller = SmartCoachController();

    return ElevatedButton(
      onPressed: () async {
        await controller.onSetCompleted(
          context: context,
          plan: plan,
          doneSoFar: done,
          nextSetIndex: 2,
        );
      },
      child: const Text("Test Smart Coach"),
    );
  }
}

// -----------------------------
// INTEGRATION CHECKLIST
// -----------------------------
/*
1) Where to call onSetCompleted:
   - After the user logs a set in your Exercise screen, call controller.onSetCompleted(...) to surface a contextual tip.

2) Where to call onSessionCompleted:
   - When user taps "Finish Session". This computes effort, boosts ranking points (future), and adjusts kcal for today/tomorrow.

3) Hive wires (TODOs):
   - meal_targets box: store daily kcal target overrides (date -> kcalDelta).
   - user_profile box: store weeklyBonusKcalSoFar, reset each Monday.

4) UI links:
   - Home rings should read baselineDailyKcal + (meal_targets[date] ?? 0).
   - Settings: show a "Weekly BOU Boost: +XYZ kcal" line with reset day.

5) Safeguards:
   - Respect IBS/lactose flags when suggesting foods; kcal boost should shift macros proportionally to user goal.
   - Deload week: attenuate effort → kcal mapping by ~50%.

6) Future (Cloud):
   - Ranking service -> award points from Scoring.rankingPoints(effort).
   - Leaderboards per weight class.
   - Store AMRAP PRs per exercise.
*/
