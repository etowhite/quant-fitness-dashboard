class MealReminder {
  const MealReminder({this.enabled = false, required this.minute});
  final bool enabled;
  final int minute;
  MealReminder copyWith({bool? enabled, int? minute}) => MealReminder(
      enabled: enabled ?? this.enabled, minute: minute ?? this.minute);
  Map<String, dynamic> toJson() => {'enabled': enabled, 'minute': minute};
  factory MealReminder.fromJson(Map<String, dynamic> json) {
    if (json['enabled'] is! bool ||
        json['minute'] is! int ||
        (json['minute'] as int) < 0 ||
        (json['minute'] as int) >= 1440) {
      throw const FormatException('Некорректное время');
    }
    return MealReminder(
        enabled: json['enabled'] as bool, minute: json['minute'] as int);
  }
}

class ReminderSettings {
  const ReminderSettings(
      {this.water = false,
      this.waterInterval = 120,
      this.waterStart = 540,
      this.waterEnd = 1260,
      this.breakfast = const MealReminder(minute: 540),
      this.lunch = const MealReminder(minute: 810),
      this.dinner = const MealReminder(minute: 1140),
      this.measurements = const MealReminder(minute: 480),
      this.weekday = 0});
  final bool water;
  final int waterInterval, waterStart, waterEnd;
  final MealReminder breakfast, lunch, dinner, measurements;
  final int weekday; // 0 = daily, 1..7 = ISO weekday.
  bool get anyEnabled =>
      water ||
      breakfast.enabled ||
      lunch.enabled ||
      dinner.enabled ||
      measurements.enabled;
  void validate() {
    if (![90, 120, 180].contains(waterInterval) ||
        waterStart < 0 ||
        waterEnd > 1439 ||
        waterStart >= waterEnd ||
        weekday < 0 ||
        weekday > 7) {
      throw const FormatException('Некорректное окно напоминаний');
    }
    for (final meal in [breakfast, lunch, dinner, measurements]) {
      if (meal.minute < 0 || meal.minute >= 1440) {
        throw const FormatException('Некорректное время');
      }
    }
  }

  ReminderSettings copyWith(
          {bool? water,
          int? waterInterval,
          int? waterStart,
          int? waterEnd,
          MealReminder? breakfast,
          MealReminder? lunch,
          MealReminder? dinner,
          MealReminder? measurements,
          int? weekday}) =>
      ReminderSettings(
          water: water ?? this.water,
          waterInterval: waterInterval ?? this.waterInterval,
          waterStart: waterStart ?? this.waterStart,
          waterEnd: waterEnd ?? this.waterEnd,
          breakfast: breakfast ?? this.breakfast,
          lunch: lunch ?? this.lunch,
          dinner: dinner ?? this.dinner,
          measurements: measurements ?? this.measurements,
          weekday: weekday ?? this.weekday);
  Map<String, dynamic> toJson() => {
        'water': water,
        'waterInterval': waterInterval,
        'waterStart': waterStart,
        'waterEnd': waterEnd,
        'breakfast': breakfast.toJson(),
        'lunch': lunch.toJson(),
        'dinner': dinner.toJson(),
        'measurements': measurements.toJson(),
        'weekday': weekday
      };
  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    if (json['water'] is! bool ||
        [
          json['waterInterval'],
          json['waterStart'],
          json['waterEnd'],
          json['weekday']
        ].any((v) => v is! int)) {
      throw const FormatException('Некорректные напоминания');
    }
    MealReminder meal(String key) {
      final value = json[key];
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Некорректное напоминание');
      }
      return MealReminder.fromJson(value);
    }

    final settings = ReminderSettings(
        water: json['water'] as bool,
        waterInterval: json['waterInterval'] as int,
        waterStart: json['waterStart'] as int,
        waterEnd: json['waterEnd'] as int,
        weekday: json['weekday'] as int,
        breakfast: meal('breakfast'),
        lunch: meal('lunch'),
        dinner: meal('dinner'),
        measurements: meal('measurements'));
    settings.validate();
    return settings;
  }
}

class ReminderSlot {
  const ReminderSlot(this.id, this.title, this.body, this.minute,
      {this.weekday = 0});
  final int id, minute, weekday;
  final String title, body;
}

List<ReminderSlot> buildReminderSlots(ReminderSettings settings) {
  settings.validate();
  return [
    if (settings.water)
      for (var m = settings.waterStart, i = 0;
          m <= settings.waterEnd;
          m += settings.waterInterval, i++)
        ReminderSlot(100 + i, 'quant · вода',
            'Время сделать глоток воды и отметить порцию.', m),
    if (settings.breakfast.enabled)
      ReminderSlot(201, 'quant · завтрак',
          'Не забудьте внести завтрак в дневник.', settings.breakfast.minute),
    if (settings.lunch.enabled)
      ReminderSlot(202, 'quant · обед',
          'Время обеда: отметьте продукты в дневнике.', settings.lunch.minute),
    if (settings.dinner.enabled)
      ReminderSlot(203, 'quant · ужин', 'Отметьте ужин в дневнике питания.',
          settings.dinner.minute),
    if (settings.measurements.enabled)
      ReminderSlot(301, 'quant · замеры', 'Время взвеситься и обновить замеры.',
          settings.measurements.minute,
          weekday: settings.weekday),
  ];
}
