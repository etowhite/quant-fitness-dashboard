# Проверка quant 1.3.0

Дата: 31 октября 2026.

## Пройдено локально

- Flutter 3.35.7 / Dart 3.9.2, Java 17, Android SDK / Build Tools 35, minSdk 26.
- `flutter pub get` и `dart run build_runner build --delete-conflicting-outputs`:
  четыре полноценные схемы Isar, без временных заглушек.
- `flutter analyze --fatal-infos`: **No issues found**.
- `flutter test`: **44 / 44** теста прошли.
- Проверены водный дневник, 547 продуктов, OFF-парсер, приоритеты Health Connect,
  цели, тема, RU/EN, JSON v1–v4, онбординг, защитные диалоги сброса.
- Реальный Isar Core на Windows: сохранение/повторное открытие, аддитивный посев,
  вода по датам, кэш штрихкодов, rollback импорта, выборочная и полная очистка.
- Дополнительная отрисовка трех UI-превью на ширине 390 px: без исключений,
  локальный Inter и Material Icons. Изображения в `docs/screenshots/`.
- `node tool/security_check.mjs --advisories`: 118 точных Pub-версий,
  **0 известных advisory-совпадений**, исходные security regression checks пройдены.
- Публикуемые файлы проверены на типовые секреты; SDK, keystore, key.properties,
  локальные пути SDK, build и временные отчеты исключены из Git.

## Android runtime

Локальный эмулятор завершается в Windows с `0xC0000135` (DLL startup failure).
Облачный эмулятор **Android 35 успешно прошел оба integration-теста**:
инициализация приложения и навигация по четырем вкладкам, реальный Isar
с сохранением данных. Сборка, анализ, 44 unit/widget-теста, security regression
checks и публикация также прошли в [CI build-4](https://github.com/etowhite/quant-smart-fitness-dashboard/actions/runs/41221927230).
Причины прежних ошибок исправлены: устаревший SDK package tools, glibc Isar
на Ubuntu 22.04 и недостаточный heap Gradle при debug-сборке для эмулятора.
Системные окна Health Connect, реальная камера, доставка уведомлений после
перезагрузки и ограничения Mi Fitness / Picooc требуют проверки на устройстве.

## APK

Локальная релизная сборка 1.3.0 (versionCode 4) успешно собрана. Проверка
упакованного manifest подтвердила имя quant, minSdk 26 / targetSdk 35,
отключенные backup, cleartext и debuggable, ожидаемый список разрешений.
`apksigner verify` подтвердил подпись APK Signature Scheme v2. Без приватного
`android/key.properties` используется предусмотренная debug-подпись.
Опубликованный APK из CI: **77 693 169 байт**.
SHA-256: `b2ef7797289d2279951b97ccb538c1c325f0d45d701da21a43b52517322f5627`.
Файл: `build/releases/quant-release.apk`.
[Релиз v1.3.0](https://github.com/etowhite/quant-smart-fitness-dashboard/releases/tag/v1.3.0).
Локальный APK и APK CI подписаны разными debug-ключами; обновление между ними
требует одинаковой подписи или переустановки с предварительным JSON-экспортом.

OSV покрывает только известные advisories Pub, не нативные Maven/NDK-зависимости.
Формальный security-audit workflow остается частичным: см. [security_audit.md](security_audit.md).
