import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/features/goals/application/user_goals_provider.dart';
import 'package:smart_fitness_dashboard/features/goals/data/user_goals_repository.dart';
import 'package:smart_fitness_dashboard/features/goals/domain/user_goals.dart';

class FailingGoalsRepository extends UserGoalsRepository {
  @override
  Future<UserGoals> load() async => const UserGoals(calories: 2000);
  @override
  Future<void> save(UserGoals goals) async =>
      throw StateError('disk unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first launch defaults; goals persist across provider containers',
      () async {
    final first = ProviderContainer();
    expect((await first.read(userGoalsProvider.future)).calories, 2200);
    const goals = UserGoals(
        calories: 1800, proteins: 120, fats: 60, carbs: 200, steps: 6000);
    await first.read(userGoalsProvider.notifier).save(goals);
    expect(first.read(effectiveUserGoalsProvider).steps, 6000);
    first.dispose();
    final reopened = ProviderContainer();
    addTearDown(reopened.dispose);
    final saved = await reopened.read(userGoalsProvider.future);
    expect(saved.toJson(), goals.toJson());
  });

  test('invalid persisted goals surface error and can be repaired explicitly',
      () async {
    SharedPreferences.setMockInitialValues(
        {UserGoalsRepository.storageKey: '{invalid'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await expectLater(container.read(userGoalsProvider.future),
        throwsA(isA<FormatException>()));
    expect(container.read(userGoalsProvider).hasError, isTrue);
    await container
        .read(userGoalsProvider.notifier)
        .save(const UserGoals(steps: 8000));
    expect(container.read(effectiveUserGoalsProvider).steps, 8000);
  });

  test('failed save retains last confirmed goals', () async {
    final container = ProviderContainer(overrides: [
      userGoalsRepositoryProvider.overrideWithValue(FailingGoalsRepository()),
    ]);
    addTearDown(container.dispose);
    await container.read(userGoalsProvider.future);
    await expectLater(
        container
            .read(userGoalsProvider.notifier)
            .save(const UserGoals(calories: 1700)),
        throwsStateError);
    expect(container.read(effectiveUserGoalsProvider).calories, 2000);
    expect(container.read(userGoalsProvider).hasError, isTrue);
  });

  test('goals reject zero, negative and non-finite values', () {
    for (final goals in [
      const UserGoals(calories: 0),
      const UserGoals(steps: -1),
      const UserGoals(proteins: double.infinity),
      const UserGoals(calories: 20001),
      const UserGoals(steps: 200001),
      const UserGoals(carbs: 2001),
    ]) {
      expect(goals.validate, throwsFormatException);
    }
  });
}
