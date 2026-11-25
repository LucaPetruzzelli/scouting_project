import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../repositories/events_repository.dart';
import '../repositories/event_logistics_repository.dart';
import '../../auth/providers/auth_provider.dart';

final eventsProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<EventModel>>>((ref) {
  final repository = ref.read(eventsRepositoryProvider);
  final logisticsRepository = ref.read(eventLogisticsRepositoryProvider);
  final authState = ref.watch(authProvider);
  return EventsNotifier(repository, logisticsRepository, authState.user?.id);
});

class EventsNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final EventsRepository _repository;
  final EventLogisticsRepository _logisticsRepository;
  final String? _userId;
  StreamSubscription<List<EventModel>>? _subscription;

  EventsNotifier(this._repository, this._logisticsRepository, this._userId) : super(const AsyncValue.loading()) {
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
        (events) async {
          // Carica i logistics user IDs per ogni evento
          final eventsWithLogistics = await _enrichEventsWithLogistics(events);
          state = AsyncValue.data(eventsWithLogistics);
        },
        onError: (err, st) {
          state = AsyncValue.error(err, st);
        },
      );
    }
  }

  Future<List<EventModel>> _enrichEventsWithLogistics(List<EventModel> events) async {
    final enrichedEvents = <EventModel>[];
    for (final event in events) {
      try {
        final logisticsUserIds = await _logisticsRepository.getLogisticsUserIds(event.id);
        enrichedEvents.add(EventModel.withLogistics(
          id: event.id,
          title: event.title,
          description: event.description,
          startDate: event.startDate,
          endDate: event.endDate,
          location: event.location,
          createdBy: event.createdBy,
          targetRoles: event.targetRoles,
          targetBranches: event.targetBranches,
          targetSquads: event.targetSquads,
          targetUsers: event.targetUsers,
          logisticsUserIds: logisticsUserIds,
          eventType: event.eventType,
          fee: event.fee,
          hasGroups: event.hasGroups,
          groupsData: event.groupsData,
          createdAt: event.createdAt,
        ));
      } catch (e) {
        // In caso di errore, continua con l'evento senza logistics user IDs
        enrichedEvents.add(event);
      }
    }
    return enrichedEvents;
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
