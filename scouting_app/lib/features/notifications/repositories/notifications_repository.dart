import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(Supabase.instance.client);
});

class NotificationsRepository {
  final SupabaseClient _supabase;

  NotificationsRepository(this._supabase);

  Future<List<NotificationModel>> fetchUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map((data) => NotificationModel.fromJson(data)).toList();
    } catch (e) {
      print('Errore recupero notifiche: $e');
      throw Exception('Impossibile caricare le notifiche');
    }
  }

  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }


  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      print('Errore aggiornamento notifica: $e');
      throw Exception('Impossibile aggiornare la notifica');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Errore aggiornamento notifiche: $e');
      throw Exception('Impossibile aggiornare le notifiche');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Errore eliminazione notifica: $e');
      throw Exception('Impossibile eliminare la notifica');
    }
  }
}
