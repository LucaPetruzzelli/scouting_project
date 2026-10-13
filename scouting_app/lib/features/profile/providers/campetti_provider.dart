import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/campetti_repository.dart';
import '../../auth/providers/auth_provider.dart';

// Provider per i campetti dell'utente loggato
final myCampettiProvider = StateNotifierProvider<CampettiNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final authState = ref.watch(authProvider);
  final profileId = authState.profile?['id'];
  return CampettiNotifier(ref.read(campettiRepositoryProvider), profileId);
});

class CampettiNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final CampettiRepository _repository;
  final String? _profileId;

  CampettiNotifier(this._repository, this._profileId) : super(const AsyncValue.loading()) {
    if (_profileId != null) {
      loadCampetti();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadCampetti() async {
    if (_profileId == null) return;
    state = const AsyncValue.loading();
    final data = await _repository.getCampettiByProfile(_profileId);
    state = AsyncValue.data(data);
  }

  Future<bool> addCampetto(String titolo, String tipo, DateTime start, DateTime end) async {
    if (_profileId == null) return false;
    final success = await _repository.insertCampetto({
      'profile_id': _profileId,
      'titolo': titolo,
      'tipo': tipo,
      'data_inizio': start.toIso8601String(),
      'data_fine': end.toIso8601String(),
    });
    if (success) {
      loadCampetti(); // Ricarica la lista per prendere il nuovo ID e lo status 'pending'
    }
    return success;
  }

  Future<bool> removeCampetto(String id) async {
    final success = await _repository.deleteCampetto(id);
    if (success) {
      state = state.whenData((list) => list.where((c) => c['id'] != id).toList());
    }
    return success;
  }
}

// Provider separato per le richieste in attesa (lato Admin/Capo)
final pendingCampettiProvider = StateNotifierProvider<PendingCampettiNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return PendingCampettiNotifier(ref.read(campettiRepositoryProvider));
});

class PendingCampettiNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final CampettiRepository _repository;

  PendingCampettiNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPending();
  }

  Future<void> loadPending() async {
    state = const AsyncValue.loading();
    final data = await _repository.getPendingCampetti();
    state = AsyncValue.data(data);
  }

  Future<bool> approve(String id) async {
    final success = await _repository.updateCampettoStatus(id, 'approved');
    if (success) {
      state = state.whenData((list) => list.where((c) => c['id'] != id).toList());
    }
    return success;
  }

  Future<bool> reject(String id) async {
    final success = await _repository.updateCampettoStatus(id, 'rejected');
    if (success) {
      state = state.whenData((list) => list.where((c) => c['id'] != id).toList());
    }
    return success;
  }
}
