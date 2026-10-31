import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends AsyncNotifier<bool> {
  static const key = 'hasCompletedOnboarding';
  @override
  Future<bool> build() async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;
  Future<void> setCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(key, value)) {
      throw StateError('Could not save onboarding');
    }
    state = AsyncData(value);
  }
}
