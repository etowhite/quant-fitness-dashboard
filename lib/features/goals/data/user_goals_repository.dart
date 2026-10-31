import '../../../core/home_widgets/home_widgets.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_goals.dart';

class UserGoalsRepository {
  static const storageKey = 'user_goals.v1';

  Future<UserGoals> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(storageKey);
    if (saved == null) return const UserGoals();
    if (saved.length > 4096) {
      throw const FormatException('Слишком большой документ целей');
    }
    return UserGoals.fromJson(jsonDecode(saved) as Map<String, dynamic>);
  }

  Future<void> save(UserGoals goals) async {
    goals.validate();
    final preferences = await SharedPreferences.getInstance();
    // A single document prevents partially updated sets of goals.
    final saved =
        await preferences.setString(storageKey, jsonEncode(goals.toJson()));
    if (!saved) throw StateError('Не удалось сохранить цели');
    await HomeWidgets.refresh();
  }
}
