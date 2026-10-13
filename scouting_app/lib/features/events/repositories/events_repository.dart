import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(Supabase.instance.client);
});

class EventsRepository {
  final SupabaseClient _supabase;

  EventsRepository(this._supabase);

  Stream<List<EventModel>> streamEvents() {
    return _supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .order('start_date', ascending: true)
        .map((data) => data.map((json) => EventModel.fromJson(json)).toList());
  }

  Future<void> createEvent(EventModel event) async {
    try {
      await _supabase.from('events').insert(event.toJson());
    } catch (e) {
      print('Errore creazione evento: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      await _supabase.from('events').update(event.toJson()).eq('id', event.id);
    } catch (e) {
      print('Errore aggiornamento evento: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _supabase.from('events').delete().eq('id', id);
    } catch (e) {
      print('Errore eliminazione evento: $e');
      throw Exception('Impossibile eliminare l\'evento');
    }
  }
}
