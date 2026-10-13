import 'package:flutter/material.dart';

class ScoutCard extends StatelessWidget {
  final String name;
  final String surname;
  final String role;
  final String branch;
  final String? jungleName;

  const ScoutCard({
    super.key,
    required this.name,
    required this.surname,
    required this.role,
    required this.branch,
    this.jungleName,
  });

  @override
  Widget build(BuildContext context) {
    final isCapoBranco = (role == 'capo' || role == 'capo gruppo') && branch == 'l/c';
    final hasJungleName = isCapoBranco && jungleName != null && jungleName!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.badge, color: Colors.white, size: 32),
              Text(
                role.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Capo branco: mostra il soprannome come nome principale
          if (hasJungleName) ...[
            Text(
              jungleName!,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$name $surname',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ] else ...[
            Text(
              '$name $surname',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              branch.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
