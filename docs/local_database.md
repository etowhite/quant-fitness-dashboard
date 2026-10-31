> Историческое описание этапа. Текущая реализация и сборка описаны в [README](../README.md).

# Локальная база — этап 3

Все операции выполняются локально в `smart_fitness.isar` в application documents
directory. Сервис не использует сеть. Нативный Android runner по-прежнему нужно
сгенерировать по README перед запуском приложения или integration test.

## Обязательная генерация

Три модели содержат `part '*.g.dart'`, файлы-заглушки содержат только `part of`.
Они намеренно не подменяют настоящие схемы. **До генерации проект не компилируется.** Это предусмотренный вариант
этого этапа: схемы и query extensions должен создать официальный генератор.

В Isar 3 нет `@id`: первичный ключ определяется типом `Id` и именем `id`.
Индекс имени продукта — регистронезависимый value index для поиска по префиксу.
Дата дневника индексирована, дата замера — уникальна после нормализации к
локальной полуночи. Связи IsarLink не нужны: дневник хранит снимок продукта,
поэтому редактирование справочника не меняет исторические КБЖУ.

Генератор 3.4.1 требует Dart >=3.9.0. Основной pubspec сохраняет SDK >=3.4.0
и не подключает требовательные dev-зависимости автоматически. На Flutter с
Dart >=3.9.0 добавьте согласованные зависимости и выполните:

```sh
flutter pub add --dev isar_community_generator:3.4.1 build_runner:2.10.5
dart run build_runner build --delete-conflicting-outputs
dart format lib test integration_test
flutter analyze
flutter test
flutter test integration_test/local_database_test.dart -d <android-device-id>
```

build_runner закреплен на ветке build 4, совместимой с генератором 3.4.1.
Если рабочий SDK — Dart 3.4, сгенерируйте файлы в отдельной копии проекта с
Dart >=3.9 и перенесите только три `.g.dart`, сохранив исходный pubspec.
Сохраните сгенерированные файлы в Git. Совместимость с самым старым SDK
нужно подтвердить analyze/build на нем; в этом окружении Flutter отсутствует.

Документация генератора: https://pub.dev/packages/isar_community_generator/versions/3.4.1

## Использование

```dart
final database = await ref.read(databaseServiceProvider.future);
final products = await database.searchProducts('кур');
await ref.read(foodDiaryProvider(DateTime.now()).notifier)
    .addProduct(products.first, 150, 'Обед');
final diary = ref.watch(foodDiaryProvider(DateTime.now()));
// diary.when(data: (day) => ... day.entries / day.totals ...)
final history = ref.watch(bodyMeasurementHistoryProvider);
await ref.read(bodyMeasurementActionsProvider).save(
  BodyMeasurement()..date = DateTime.now()..waist = 82,
);
```

Импорты: core/database/database_provider.dart,
features/nutrition/application/food_diary_provider.dart,
features/measurements/application/body_measurements_provider.dart и модель замера.

Провайдер сервиса открывает и заполняет БД один раз на ProviderContainer;
закрывает при уничтожении контейнера. isarProvider предоставляет сам Isar.
Не закрывайте БД вручную из экранов. Подписки дневника autoDispose и истории
перестают слушать после ухода потребителей. Записи сервиса уведомляют Isar
watchers, которые пересчитывают КБЖУ и обновляют историю без ручного invalidate.
Ошибки чтения попадают в AsyncError; ошибки записи возвращаются вызывающему UI
через Future и не маскируются под успешное сохранение.

В дневнике границы дня — [локальная полночь, следующая локальная полночь).
В замерах входящий id не определяет обновление: заменяется запись выбранного
дня с сохранением ее id. Отсутствующие поля при замене очищаются. Это полная
замена, а не частичный patch. История сортируется от новых дат к старым.
Строки КБЖУ в FoodLogEntry — итог на порцию; addProductToDiary рассчитывает их
как значение на 100 г × вес / 100. addFoodLogEntry принимает готовые итоги.
Изменение даты записи после ее сохранения не происходит автоматически при
смене часового пояса: Isar хранит DateTime как момент UTC.

Предустановка десяти продуктов выполняется атомарно при открытии пустого
справочника. Значения справочные, округленные, на съедобные 100 г, с указанием
сырого/готового состояния в названии. Значения отличаются по сорту, бренду и
рецепту; для точности создавайте продукт по этикетке. Например, сырое куриное
филе: 120 ккал, Б 22.5, Ж 2.62, У 0 — USDA SR Legacy 171077:
https://embed.myfooddata.com/nutrition-facts/171077/100g/1
Творог 5% — типичные значения 121/17/5/1.8; это не американский cottage cheese.

Интеграционный тест проверяет seed без дублирования после повторного открытия,
регистронезависимый поиск, границы дня, watcher, снимок порции, пересчет КБЖУ,
замену замера за день с сохранением id и сохранность данных после открытия БД.
В текущем окружении генератор, анализатор и тесты не запускались.
