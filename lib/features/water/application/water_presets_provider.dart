import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterPresetsRepository {
  static const key = 'quant.waterPresets';
  static List<int> validate(Object? values) {
    if (values is! List ||
        values.length > 8 ||
        values.any((v) => v is! int || v < 1 || v > 5000)) {
      throw const FormatException('Некорректные объемы воды');
    }
    return values.cast<int>().toSet().toList()..sort();
  }

  Future<List<int>> load() async {
    final values =
        (await SharedPreferences.getInstance()).getStringList(key) ?? [];
    return validate(values.map(int.parse).toList());
  }

  Future<void> save(List<int> values) async {
    if (!await (await SharedPreferences.getInstance())
        .setStringList(key, validate(values).map((v) => '$v').toList())) {
      throw StateError('Could not save water presets');
    }
  }
}

final waterPresetsProvider =
    AsyncNotifierProvider<WaterPresetsNotifier, List<int>>(
        WaterPresetsNotifier.new);

class WaterPresetsNotifier extends AsyncNotifier<List<int>> {
  @override
  Future<List<int>> build() => WaterPresetsRepository().load();
  Future<void> save(List<int> values) async {
    await WaterPresetsRepository().save(values);
    state = AsyncData(WaterPresetsRepository.validate(values));
  }
}
