import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../repositories/events_repository.dart';
import '../../auth/providers/auth_provider.dart';

final eventsProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<EventModel>>>((ref) {
  final repository = ref.read(eventsRepositoryProvider);
  final authState = ref.watch(authProvider);
  return EventsNotifier(repository, authState.user?.id);
});

class EventsNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final EventsRepository _repository;
  final String? _userId;
  StreamSubscription<List<EventModel>>? _subscription;

  EventsNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _listenToStream();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  void _listenToStream() {
    _subscription?.cancel();
    if (_userId != null) {
      _subscription = _repository.streamEvents().listen(
        (events) {
          state = AsyncValue.data(events);
        },
        onError: (err, st) {
          state = AsyncValue.error(err, st);
        },
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> createEvent(EventModel event) async {
    await _repository.createEvent(event);
  }

  Future<void> updateEvent(EventModel event) async {
    await _repository.updateEvent(event);
  }

  Future<void> deleteEvent(String id) async {
    await _repository.deleteEvent(id);
  }
}
