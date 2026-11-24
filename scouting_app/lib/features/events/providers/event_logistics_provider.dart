import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../repositories/event_logistics_repository.dart';

final eventLogisticsProvider = StateNotifierProvider.family<EventLogisticsNotifier, AsyncValue<Map<String, dynamic>>, EventModel>(
  (ref, event) {
    final repo = ref.watch(eventLogisticsRepositoryProvider);
    return EventLogisticsNotifier(repo, event)..loadData();
  },
);

class EventLogisticsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final EventLogisticsRepository _repo;
  final EventModel _event;

  EventLogisticsNotifier(this._repo, this._event) : super(const AsyncValue.loading());

  Future<void> loadData() async {
    state = const AsyncValue.loading();
    try {
      // 1. Fetch current logistics users
      final logisticsUsers = await _repo.getLogisticsUsers(_event.id);

      // 2. Fetch expected participants
      final allParticipants = await _repo.getExpectedParticipants(
        _event.targetBranches,
        _event.targetRoles,
        _event.targetSquads,
        _event.targetUsers,
      );

      // 3. Get user IDs of logistics members
      final logisticsUserIds = logisticsUsers.map((p) => p['user_id'] as String).toSet();

      // 4. Filter participants to only those who are logistics members
      final logisticsMembers = allParticipants.where((p) {
        return logisticsUserIds.contains(p['id']);
      }).toList();

      // 5. Sort alphabetically
      logisticsMembers.sort((a, b) {
        int cmp = (a['cognome'] ?? '').compareTo(b['cognome'] ?? '');
        if (cmp != 0) return cmp;
        return (a['nome'] ?? '').compareTo(b['nome'] ?? '');
      });

      state = AsyncValue.data({
        'logisticsMembers': logisticsMembers,
        'allParticipants': allParticipants,
        'logisticsUserIds': logisticsUserIds,
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggle a user's logistics membership
  Future<bool> toggleLogisticsUser(String userId) async {
    final currentIds = state.value?['logisticsUserIds'] as Set<String>? ?? {};
    final shouldBeAdded = !currentIds.contains(userId);

    bool success;
    if (shouldBeAdded) {
      success = await _repo.addLogisticsUser(_event.id, userId);
    } else {
      success = await _repo.removeLogisticsUser(_event.id, userId);
    }

    if (success) {
      state = state.whenData((data) {
        final allParticipants = List<Map<String, dynamic>>.from(data['allParticipants']);
        final logisticsMembers = List<Map<String, dynamic>>.from(data['logisticsMembers']);
        final updatedIds = Set<String>.from(currentIds);

        if (shouldBeAdded) {
          final user = allParticipants.firstWhere((p) => p['id'] == userId, orElse: () => <String, dynamic>{});
          if (user.isNotEmpty) {
            logisticsMembers.add(user);
            updatedIds.add(userId);
          }
        } else {
          logisticsMembers.removeWhere((p) => p['id'] == userId);
          updatedIds.remove(userId);
        }

        // Sort again
        logisticsMembers.sort((a, b) {
          int cmp = (a['cognome'] ?? '').compareTo(b['cognome'] ?? '');
          if (cmp != 0) return cmp;
          return (a['nome'] ?? '').compareTo(b['nome'] ?? '');
        });

        return {
          'logisticsMembers': logisticsMembers,
          'allParticipants': data['allParticipants'],
          'logisticsUserIds': updatedIds,
          'selectedUserIds': updatedIds.toList(),
        };
      });
    }

    return success;
  }

  /// Replace the entire logistics members list (used when saving from the dialog)
  Future<void> updateLogisticsUsers(List<String> userIds) async {
    final success = await _repo.updateLogisticsUsers(_event.id, userIds);

    if (success) {
      await loadData();
    }
  }
}