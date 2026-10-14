// lib/features/profile/widgets/profile_commitments_objectives_section.dart
import 'package:flutter/material.dart';

class ObjectiveItem {
  final String id;
  final String title;
  final String description;
  final List<String> linkedCommitments; // Impegni collegati all'obiettivo
  final bool isPublic;

  ObjectiveItem({
    required this.id,
    required this.title,
    required this.description,
    required this.linkedCommitments,
    this.isPublic = false,
  });
}

class ProfileCommitmentsObjectivesSection extends StatelessWidget {
  final List<ObjectiveItem> objectives;
  final bool canEdit;
  final bool isClanMember;
  final String? clanServiceType; // es. "Servizio Associativo in Branco" o "Extra-associativo"
  final VoidCallback onAddObjective;

  const ProfileCommitmentsObjectivesSection({
    super.key,
    required this.objectives,
    required this.canEdit,
    required this.isClanMember,
    this.clanServiceType,
    required this.onAddObjective,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isClanMember) ...[
          Card(
            child: ListTile(
              leading: Icon(Icons.volunteer_activism_rounded, color: colorScheme.primary),
              title: const Text('Servizio R/S (Clan/Fuoco)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(clanServiceType?.isNotEmpty == true
                  ? clanServiceType!
                  : 'Nessun servizio specificato'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Obiettivi e Impegni Annuali',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (canEdit)
              TextButton.icon(
                onPressed: onAddObjective,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Nuovo Obiettivo'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tocca un obiettivo per visualizzare gli impegni collegati per raggiungerlo.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (objectives.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nessun obiettivo o impegno inserito per l\'anno in corso.'),
            ),
          )
        else
          ...objectives.map(
            (obj) => Card(
              child: ExpansionTile(
                leading: Icon(Icons.flag_rounded, color: colorScheme.primary),
                title: Text(obj.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(obj.description),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  const Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Impegni collegati a questo obiettivo:',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...obj.linkedCommitments.map(
                    (commitment) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(commitment)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}