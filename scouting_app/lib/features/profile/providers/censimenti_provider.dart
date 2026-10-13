import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/censimenti_repository.dart';

// Provider per il censimento (tutti i documenti dell'anno corrente) dell'utente loggato
final myCensimentoProvider = StateNotifierProvider<MyCensimentoNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final repo = ref.watch(censimentiRepositoryProvider);
  return MyCensimentoNotifier(repo)..loadCensimento(DateTime.now().year); // Usa l'anno corrente
});

class MyCensimentoNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final CensimentiRepository _repo;
  int _currentAnno = DateTime.now().year;

  MyCensimentoNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> loadCensimento(int anno) async {
    _currentAnno = anno;
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getMyCensimentoDocuments(anno);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> uploadDocument(String documentType, File file, {String? existingDocId}) async {
    final success = await _repo.uploadDocument(_currentAnno, documentType, file, existingDocId: existingDocId);
    if (success) {
      await loadCensimento(_currentAnno); // Ricarica dopo l'upload
    }
    return success;
  }
}

// Provider per i censimenti in attesa di validazione (per i capi)
final pendingCensimentiProvider = StateNotifierProvider<PendingCensimentiNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final repo = ref.watch(censimentiRepositoryProvider);
  return PendingCensimentiNotifier(repo)..loadPending();
});

class PendingCensimentiNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final CensimentiRepository _repo;

  PendingCensimentiNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> loadPending() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getPendingCensimentoDocuments();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> approve(String id) async {
    final success = await _repo.updateDocumentStatus(id, 'approved');
    if (success) {
      state = state.whenData((list) => list.where((c) => c['id'] != id).toList());
    }
    return success;
  }

  Future<bool> reject(String id) async {
    final success = await _repo.updateDocumentStatus(id, 'rejected');
    if (success) {
      state = state.whenData((list) => list.where((c) => c['id'] != id).toList());
    }
    return success;
  }
}
