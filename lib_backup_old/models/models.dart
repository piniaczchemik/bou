class ExerciseItem {
  final String id;
  final String name;
  final int sets;
  final int reps;

  ExerciseItem({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
  });
}

class WorkoutDay {
  final String id;
  final String title;
  final List<ExerciseItem> items;

  WorkoutDay({
    required this.id,
    required this.title,
    required this.items,
  });
}

class Program {
  final String id;
  final String name;
  final List<WorkoutDay> days;

  Program({
    required this.id,
    required this.name,
    required this.days,
  });
}
