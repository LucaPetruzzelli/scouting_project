import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/admin_repository.dart';

final pendingUsersProvider = StateNotifierProvider<PendingUsersNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return PendingUsersNotifier(ref.read(adminRepositoryProvider));
});

class PendingUsersNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AdminRepository _repository;

  PendingUsersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPendingUsers();
  }

  Future<void> loadPendingUsers() async {
    state = const AsyncValue.loading();
    final users = await _repository.getPendingUsers();
    state = AsyncValue.data(users);
  }

  Future<bool> approveUser(String userId, Map<String, dynamic> updatedData) async {
    final success = await _repository.approveUser(userId, updatedData);
    if (success) {
      // Rimuoviamo l'utente dalla lista locale senza ricaricare tutto da DB
      state = state.whenData((users) => users.where((u) => u['id'] != userId).toList());
    }
    return success;
  }

  Future<bool> rejectUser(String userId) async {
    final success = await _repository.rejectUser(userId);
    if (success) {
      state = state.whenData((users) => users.where((u) => u['id'] != userId).toList());
    }
    return success;
  }
}

// Filtri per la lista utenti
class UsersFilter {
  final String? status;
  final String? branch;

  UsersFilter({this.status, this.branch});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsersFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          branch == other.branch;

  @override
  int get hashCode => status.hashCode ^ branch.hashCode;
}

final usersFilterProvider = StateProvider<UsersFilter>((ref) => UsersFilter());

final usersListProvider = StateNotifierProvider<UsersListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final filter = ref.watch(usersFilterProvider);
  return UsersListNotifier(ref.read(adminRepositoryProvider), filter);
});

class UsersListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AdminRepository _repository;
  final UsersFilter filter;

  UsersListNotifier(this._repository, this.filter) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    final users = await _repository.getUsers(status: filter.status, branch: filter.branch);
    state = AsyncValue.data(users);
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    final success = await _repository.updateUser(userId, data);
    if (success) {
      // Aggiorna la lista locale
      state = state.whenData((users) {
        return users.map((u) {
          if (u['id'] == userId) {
            return {...u, ...data};
          }
          return u;
        }).toList();
      });
    }
    return success;
  }
}
