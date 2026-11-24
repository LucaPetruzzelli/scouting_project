import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final eventLogisticsRepositoryProvider = Provider<EventLogisticsRepository>((ref) {
  return EventLogisticsRepository(Supabase.instance.client);
});

class EventLogisticsRepository {
  final SupabaseClient _supabase;

  EventLogisticsRepository(this._supabase);

  /// Gets all logistics users for a specific event
  Future<List<Map<String, dynamic>>> getLogisticsUsers(String eventId) async {
    try {
      final response = await _supabase
          .from('event_logistics_members')
          .select('user_id, profiles!inner(id, nome, cognome, branch, squad_name, is_warehouse_keeper)')
          .eq('event_id', eventId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Errore getLogisticsUsers: $e');
      return [];
    }
  }

  /// Gets expected participants for an event (users matching event targets)
  Future<List<Map<String, dynamic>>> getExpectedParticipants(
    List<String> branches,
    List<String> roles,
    List<String> squads,
    List<String> specificUsers,
  ) async {
    try {
      final response = await _supabase.from('profiles').select('id, nome, cognome, branch, role, squad_name, is_warehouse_keeper');
      final allProfiles = List<Map<String, dynamic>>.from(response);

      return allProfiles.where((p) {
        // Se l'utente è in specificUsers, è un candidato
        if (specificUsers.contains(p['id'])) return true;
        // Se non ci sono target specifici, è per tutti?
        if (branches.isEmpty && roles.isEmpty && squads.isEmpty && specificUsers.isEmpty) return true;
        // Check branches
        if (branches.isNotEmpty && branches.contains(p['branch'])) return true;
        // Check roles
        if (roles.isNotEmpty && roles.contains(p['role'])) return true;
        // Check squads
        if (squads.isNotEmpty && squads.contains(p['squad_name'])) return true;

        return false;
      }).toList();
    } catch (e) {
      debugPrint('Errore getExpectedParticipants: $e');
      return [];
    }
  }

  /// Adds a user to the logistics group for an event
  Future<bool> addLogisticsUser(String eventId, String userId) async {
    try {
      await _supabase.from('event_logistics_members').insert({
        'event_id': eventId,
        'user_id': userId,
      });
      return true;
    } catch (e) {
      debugPrint('Errore addLogisticsUser: $e');
      return false;
    }
  }

  /// Removes a user from the logistics group for an event
  Future<bool> removeLogisticsUser(String eventId, String userId) async {
    try {
      await _supabase
          .from('event_logistics_members')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Errore removeLogisticsUser: $e');
      return false;
    }
  }

  /// Clears all logistics users for an event (rarely needed, but useful for reseting)
  Future<void> clearLogisticsUsers(String eventId) async {
    try {
      await _supabase.from('event_logistics_members').delete().eq('event_id', eventId);
    } catch (e) {
      debugPrint('Errore clearLogisticsUsers: $e');
      rethrow;
    }
  }

  /// Updates the entire logistics members list for an event
  Future<bool> updateLogisticsUsers(String eventId, List<String> userIds) async {
    try {
      // First, remove all existing logistics members
      await _supabase.from('event_logistics_members').delete().eq('event_id', eventId);

      // Then, insert all new logistics members
      if (userIds.isNotEmpty) {
        final entries = userIds.map((userId) => {'event_id': eventId, 'user_id': userId}).toList();
        await _supabase.from('event_logistics_members').insert(entries);
      }

      return true;
    } catch (e) {
      debugPrint('Errore updateLogisticsUsers: $e');
      return false;
    }
  }

  /// Checks if a user is a logistics member for a specific event
  Future<bool> isLogisticsMember(String eventId, String userId) async {
    try {
      final response = await _supabase
          .from('event_logistics_members')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Errore isLogisticsMember: $e');
      return false;
    }
  }
}