import 'package:flutter/material.dart';

class UserSummaryBar extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String? jungleName;
  final String branca;
  final String role;
  final String? avatarUrl;
  final VoidCallback onTap;

  const UserSummaryBar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.jungleName,
    required this.branca,
    required this.role,
    this.avatarUrl,
    required this.onTap,
  });

  bool get _useJungleName =>
      role.toLowerCase().contains('capo') &&
      branca.toLowerCase() == 'branco' &&
      jungleName != null &&
      jungleName!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = _useJungleName
        ? '$jungleName ($firstName $lastName)'
        : '$firstName $lastName';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage:
                    avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Text(
                        (_useJungleName ? jungleName![0] : firstName[0]).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$branca • $role',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}