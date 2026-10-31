import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterPresetsRepository {
  static const key = 'quant.waterQuickButtons.v2';
  static const legacyKey = 'quant.waterPresets';
  static const defaults = [150, 250, 500];
  static const maxButtons = 11;
  static List<int> validate(Object? values) {
    if (values is! List ||
        values.length > maxButtons ||
        values.any((v) => v is! int || v < 1 || v > 5000)) {
      throw const FormatException('Некорректные объемы воды');
    }
    return values.cast<int>().toSet().toList()..sort();
  }

  Future<List<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(key);
    if (values != null) return validate(values.map(int.parse).toList());
    // Earlier versions stored only additional buttons, not the three defaults.
    final legacy = prefs.getStringList(legacyKey) ?? [];
    return validate({...defaults, ...legacy.map(int.parse)}.toList());
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
  Future<void> _pending = Future.value();
  @override
  Future<List<int>> build() => WaterPresetsRepository().load();
  Future<void> save(List<int> values) async {
    return _mutate((_) => values);
  }

  Future<void> _mutate(List<int> Function(List<int>) change) {
    final operation = _pending.then((_) async {
      final current = [...await future];
      final next = WaterPresetsRepository.validate(change(current));
      await WaterPresetsRepository().save(next);
      state = AsyncData(next);
    });
    _pending =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  Future<void> add(int volume) => _mutate((values) {
        if (values.contains(volume)) throw StateError('Duplicate volume');
        return [...values, volume];
      });

  Future<void> replace(int previous, int volume) => _mutate((values) {
        if (!values.contains(previous)) throw StateError('Missing button');
        if (previous != volume && values.contains(volume)) {
          throw StateError('Duplicate volume');
        }
        return [for (final v in values) v == previous ? volume : v];
      });

  Future<void> remove(int volume) =>
      _mutate((values) => values..remove(volume));

  // Merge undo with the latest settings rather than overwriting later edits.
  Future<void> restore(int volume) => _mutate(
      (values) => values.contains(volume) ? values : [...values, volume]);
}
