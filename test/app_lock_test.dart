import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fitness_dashboard/core/security/app_lock.dart';

class FakeAuth extends AppLockService {
  bool success = false;
  int calls = 0;
  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return success;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('lock preference changes only after system authentication succeeds',
      () async {
    final auth = FakeAuth();
    final ref = ProviderContainer(
        overrides: [appLockServiceProvider.overrideWithValue(auth)]);
    addTearDown(ref.dispose);
    expect(await ref.read(appLockProvider.future), isFalse);
    expect(await ref.read(appLockProvider.notifier).setEnabled(true, 'quant'),
        isFalse);
    expect(ref.read(appLockProvider).requireValue, isFalse);
    auth.success = true;
    expect(await ref.read(appLockProvider.notifier).setEnabled(true, 'quant'),
        isTrue);
    final other = ProviderContainer();
    addTearDown(other.dispose);
    expect(await other.read(appLockProvider.future), isTrue);
  });
  testWidgets(
      'cold start blocks content; cancel stays locked; background minute relocks',
      (tester) async {
    SharedPreferences.setMockInitialValues({AppLockNotifier.key: true});
    final auth = FakeAuth();
    var now = DateTime(2026);
    final ref = ProviderContainer(
        overrides: [appLockServiceProvider.overrideWithValue(auth)]);
    addTearDown(ref.dispose);
    await ref.read(appLockProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: ref,
        child: MaterialApp(
            builder: (context, child) =>
                AppLockGate(clock: () => now, child: child!),
            home: const Scaffold(body: Text('private diary')))));
    await tester.pumpAndSettle();
    expect(find.text('private diary'), findsNothing);
    expect(auth.calls, 1);
    auth.success = true;
    await tester.tap(find.text('Разблокировать'));
    await tester.pumpAndSettle();
    expect(find.text('private diary'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 30));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(auth.calls, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 61));
    auth.success = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(auth.calls, 3);
    expect(find.text('private diary'), findsNothing);
  });
}
