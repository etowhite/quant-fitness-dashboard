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

Локальный эмулятор установлен, но его процесс завершается в Windows с
`0xC0000135` (DLL startup failure). Android runtime, системные окна Health Connect,
реальная камера, доставка уведомлений после перезагрузки и OEM-ограничения
**не подтверждены** локально. Отдельная задача GitHub Actions запускает Android 35
и `integration_test/`. Результат следует смотреть в Actions; это не утверждение,
что облачная проверка уже прошла.

## APK

Релизная сборка выполняется. Данные о размере, SHA-256 и проверке упакованного
manifest будут обновлены после успешного завершения. Без приватного
`android/key.properties` используется предусмотренная debug-подпись.

OSV покрывает только известные advisories Pub, не нативные Maven/NDK-зависимости.
Формальный security-audit workflow остается частичным: см. [security_audit.md](security_audit.md).
