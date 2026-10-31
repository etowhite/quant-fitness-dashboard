import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_goals_repository.dart';
import '../domain/user_goals.dart';

final userGoalsRepositoryProvider = Provider((ref) => UserGoalsRepository());
final userGoalsProvider =
    AsyncNotifierProvider<UserGoalsNotifier, UserGoals>(UserGoalsNotifier.new);

// Defaults on first launch / during initial loading; retained values on save errors.
final effectiveUserGoalsProvider = Provider<UserGoals>(
    (ref) => ref.watch(userGoalsProvider).valueOrNull ?? const UserGoals());

class UserGoalsNotifier extends AsyncNotifier<UserGoals> {
  bool _saving = false;

  @override
  Future<UserGoals> build() => ref.watch(userGoalsRepositoryProvider).load();

  Future<void> save(UserGoals goals) async {
    goals.validate();
    if (_saving) throw StateError('Сохранение уже выполняется');
    _saving = true;
    // Finish the initial load before saving to prevent a late load overwriting it.
    if (state.isLoading) {
      try {
        await future;
      } catch (_) {/* Explicit editing can repair invalid data. */}
    }
    final previous = state;
    state = const AsyncLoading<UserGoals>().copyWithPrevious(previous);
    try {
      await ref.read(userGoalsRepositoryProvider).save(goals);
      state = AsyncData(goals);
    } catch (error, stack) {
      state = AsyncError<UserGoals>(error, stack).copyWithPrevious(previous);
      rethrow;
    } finally {
      _saving = false;
    }
  }
}
