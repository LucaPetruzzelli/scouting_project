import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../auth/providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../repositories/notifications_repository.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;

  return NotificationsNotifier(repository, userId);
});

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationsRepository _repository;
  final String? _userId;
  StreamSubscription<List<NotificationModel>>? _subscription;

  NotificationsNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadNotifications(); // Initial load for speed
      _listenToStream();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  List<NotificationModel> _latestStreamData = [];
  final Set<String> _pendingDeletes = {};
  final Map<String, Timer> _deleteTimers = {};

  void _listenToStream() {
    _subscription?.cancel();
    if (_userId != null) {
      _subscription = _repository.streamUserNotifications(_userId).listen(
        (notifications) {
          _latestStreamData = notifications;
          _updateStateFromStream();
        },
        onError: (err, st) {
          state = AsyncValue.error(err, st);
        },
      );
    }
  }

  void _updateStateFromStream() {
    state = AsyncValue.data(
      _latestStreamData.where((n) => !_pendingDeletes.contains(n.id)).toList(),
    );
  }

  @override
  void dispose() {
    for (var timer in _deleteTimers.values) {
      timer.cancel();
    }
    _subscription?.cancel();
    super.dispose();
  }


  Future<void> loadNotifications() async {
    if (_userId == null) return;
    
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.fetchUserNotifications(_userId);
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    if (state.value == null) return;
    
    // Optimistic UI update
    final currentList = state.value!;
    final updatedList = currentList.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    
    state = AsyncValue.data(updatedList);

    try {
      await _repository.markAsRead(id);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentList);
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null || state.value == null) return;

    final currentList = state.value!;
    final updatedList = currentList.map((n) => n.copyWith(isRead: true)).toList();
    
    state = AsyncValue.data(updatedList);

    try {
      await _repository.markAllAsRead(_userId);
    } catch (e) {
      state = AsyncValue.data(currentList);
    }
  }

  void deleteNotification(String id) {
    if (state.value == null) return;

    // Aggiungiamo ai pending delete e aggiorniamo la UI localmente
    _pendingDeletes.add(id);
    _updateStateFromStream();

    // Impostiamo un timer per l'effettiva eliminazione su DB dopo 4 secondi
    _deleteTimers[id]?.cancel();
    _deleteTimers[id] = Timer(const Duration(seconds: 4), () async {
      _pendingDeletes.remove(id);
      _deleteTimers.remove(id);
      try {
        await _repository.deleteNotification(id);
      } catch (e) {
        // Se fallisce, ricarichiamo i dati dal DB (il backend ha l'ultima parola)
        loadNotifications();
      }
    });
  }

  void restoreNotification(String id) {
    if (_pendingDeletes.contains(id)) {
      // Annulliamo il timer e rimuoviamo dai pending delete
      _deleteTimers[id]?.cancel();
      _deleteTimers.remove(id);
      _pendingDeletes.remove(id);
      
      // Ripristiniamo la UI
      _updateStateFromStream();
    }
  }

  int get unreadCount {
    if (state.value == null) return 0;
    return state.value!.where((n) => !n.isRead).length;
  }
}

