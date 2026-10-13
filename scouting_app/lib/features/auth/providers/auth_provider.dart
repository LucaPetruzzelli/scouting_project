import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../../../core/services/push_notification_service.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticatedPending,
  authenticatedActive,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final Map<String, dynamic>? profile;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Map<String, dynamic>? profile,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState()) {
    _init();
  }

  void _init() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (session == null || event == AuthChangeEvent.signedOut) {
        state = AuthState(status: AuthStatus.unauthenticated);
      } else {
        // L'utente è loggato, recuperiamo il profilo
        final user = session.user;
        final profile = await _authRepository.getProfile(user.id);
        
        // Salva il token FCM per le notifiche push
        PushNotificationService().saveTokenToSupabase(user.id);
        
        if (profile != null) {
          final statusString = profile['status'] as String?;
          if (statusString == 'active') {
            state = AuthState(status: AuthStatus.authenticatedActive, user: user, profile: profile);
          } else {
            // Se è pending, rejected, o altro
            state = AuthState(status: AuthStatus.authenticatedPending, user: user, profile: profile);
          }
        } else {
          // Profilo non trovato (anomalia o appena creato)
          state = AuthState(status: AuthStatus.authenticatedPending, user: user);
        }
      }
    });
  }

  Future<void> refreshProfile() async {
    final user = state.user;
    if (user != null) {
      final profile = await _authRepository.getProfile(user.id);
      if (profile != null) {
        final statusString = profile['status'] as String?;
        if (statusString == 'active') {
          state = AuthState(status: AuthStatus.authenticatedActive, user: user, profile: profile);
        } else {
          state = AuthState(status: AuthStatus.authenticatedPending, user: user, profile: profile);
        }
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    return await _authRepository.signIn(email: email, password: password);
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}
