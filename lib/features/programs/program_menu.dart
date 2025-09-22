import 'package:flutter/material.dart';
import '../onboarding/onboarding_flow.dart' show ProgramCategory, SexAtBirth, programsCatalog;

class ProgramMenuScreen extends StatelessWidget {
  final SexAtBirth? sexAtBirth; // optional: hide women-only tile for male
  final void Function(ProgramCategory category)? onSelect;
  const ProgramMenuScreen({super.key, this.sexAtBirth, this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = _visiblePrograms(sexAtBirth);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Training Type'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              return _ProgramTile(
                icon: _iconFor(p.id),
                title: p.name,
                subtitle: p.description,
                badge: p.id == ProgramCategory.homeStart
                    ? 'Beginner'
                    : (p.id == ProgramCategory.glutesFocus ? 'Women' : null),
                onTap: () {
                  if (onSelect != null) {
                    onSelect!(p.id);
                  } else {
                    Navigator.of(context).pushNamed('/programDetail', arguments: p.id);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List _visiblePrograms(SexAtBirth? sex) {
    if (sex == SexAtBirth.male) {
      return programsCatalog.where((p) => p.id != ProgramCategory.glutesFocus).toList();
    }
    return programsCatalog;
  }

  IconData _iconFor(ProgramCategory id) {
    switch (id) {
      case ProgramCategory.bodybuilding:
        return Icons.fitness_center;
      case ProgramCategory.hiit:
        return Icons.timer;
      case ProgramCategory.calisthenics:
        return Icons.accessibility_new;
      case ProgramCategory.pilates:
        return Icons.self_improvement_outlined;
      case ProgramCategory.weightLoss:
        return Icons.local_fire_department;
      case ProgramCategory.homeStart:
        return Icons.home;
      case ProgramCategory.glutesFocus:
        return Icons.self_improvement;
    }
  }
}

class _ProgramTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  const _ProgramTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primary.withOpacity(0.12),
                    ),
                    child: Text(badge!, style: theme.textTheme.labelSmall),
                  ),
              ],
            ),
            const Spacer(),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: const [Spacer(), Icon(Icons.arrow_forward)]),
          ],
        ),
      ),
    );
  }
}
