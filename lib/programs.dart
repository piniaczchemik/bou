import 'models/models.dart';

final Program homeStartProgram = Program(
  id: "home_start",
  name: "Home Start (Obese-friendly)",
  days: [
    WorkoutDay(
      id: "hs_w1_d1",
      title: "Week 1 • Day 1",
      items: [
        ExerciseItem(id:"hs_sit_to_stand", name:"Sit-to-Stand (Chair)", sets:3, reps:8),
        ExerciseItem(id:"hs_wall_pushup", name:"Wall Push-Ups", sets:3, reps:8),
        ExerciseItem(id:"hs_march", name:"March in Place (Low-impact)", sets:3, reps:30),
      ],
    ),
    WorkoutDay(
      id: "hs_w1_d2",
      title: "Week 1 • Day 2",
      items: [
        ExerciseItem(id:"hs_chair_row", name:"Towel Row (Seated/Chair)", sets:3, reps:10),
        ExerciseItem(id:"hs_wall_squat", name:"Wall Sit (assisted)", sets:3, reps:20),
        ExerciseItem(id:"hs_breath_core", name:"Breathing + Bracing Core", sets:3, reps:30),
      ],
    ),
  ],
);
