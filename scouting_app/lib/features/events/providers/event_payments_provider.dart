import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/event_payments_repository.dart';
import '../models/event_model.dart';

final eventPaymentsProvider = StateNotifierProvider.family<EventPaymentsNotifier, AsyncValue<Map<String, dynamic>>, EventModel>((ref, event) {
  final repo = ref.watch(eventPaymentsRepositoryProvider);
  return EventPaymentsNotifier(repo, event)..loadData();
});

class EventPaymentsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final EventPaymentsRepository _repo;
  final EventModel _event;

  EventPaymentsNotifier(this._repo, this._event) : super(const AsyncValue.loading());

  Future<void> loadData() async {
    state = const AsyncValue.loading();
    try {
      // 1. Fetch expected participants
      final participants = await _repo.getExpectedParticipants(
        _event.targetBranches,
        _event.targetRoles,
        _event.targetSquads,
        _event.targetUsers,
      );

      // 2. Fetch payments for this event
      final payments = await _repo.getPayments(_event.id);
      final paymentMap = {for (var p in payments) p['profile_id'] as String: p['has_paid'] as bool};

      // 3. Combine
      final combined = participants.map((p) {
        return {
          ...p,
          'has_paid': paymentMap[p['id']] ?? false,
        };
      }).toList();

      // Sort by surname, then name
      combined.sort((a, b) {
        int cmp = (a['cognome'] ?? '').compareTo(b['cognome'] ?? '');
        if (cmp != 0) return cmp;
        return (a['nome'] ?? '').compareTo(b['nome'] ?? '');
      });

      state = AsyncValue.data({
        'participants': combined,
        'payments': payments,
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> togglePayment(String profileId, bool hasPaid) async {
    final success = await _repo.togglePayment(_event.id, profileId, hasPaid);
    if (success) {
      // Aggiorna lo stato localmente per non dover rifare tutte le query
      state = state.whenData((data) {
        final participants = List<Map<String, dynamic>>.from(data['participants']);
        final index = participants.indexWhere((p) => p['id'] == profileId);
        if (index != -1) {
          participants[index]['has_paid'] = hasPaid;
        }
        return {
          'participants': participants,
          'payments': data['payments'], // Questo non è strettamente necessario aggiornarlo se usiamo participants
        };
      });
    }
    return success;
  }
}
