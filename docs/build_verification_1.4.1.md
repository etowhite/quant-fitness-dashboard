# quant 1.4.1 (versionCode 6): постоянная подпись

## Ключ и конфигурация

- RSA 3072, alias `quant_key`, validity 10 000 дней.
- Приватный ключ: `android/app/quant-release-key.jks` (исключён из Git).
- Фиксированные пароли: локальный `android/key.properties` (исключён из Git).
- Обе signingConfigs (`debug`, `release`) используют один ключ из properties.
- Три GitHub Actions Secrets настроены через `gh secret set` со stdin;
  приватные значения не выводились в логи и не передавались через аргументы CLI.
- Workflow восстанавливает ключ только для доверенных push/manual-сборок.
  Без секретов распространение APK останавливается; внешний PR не получает ключ.
- `tool/check_signing.mjs` проверяет подпись и закреплённый SHA-256 сертификата:
  `ac045c7e55aee1859c6c1b7a802ff36ca6c7b9426ba28ec6fbfe944ab11404ea`.

## APK

- Локальный release build прошёл, подпись соответствует постоянному сертификату.
- Проверены разрешения, minSdk 26 / targetSdk 35, backup/cleartext/debuggable отключены.
- Файл: `build/releases/quant-release.apk`, 78 176 179 байт.
- SHA-256 APK: `a0aaa9ae0e6ee026993bd3345737b94b61f27d321b0ceb4d680e11dee762662f`.
- [Релиз 1.4.1](https://github.com/etowhite/quant-fitness-dashboard/releases/tag/v1.4.1).
- [CI](https://github.com/etowhite/quant-fitness-dashboard/actions/runs/41239102999):
  **все задачи прошли**. Анализатор без замечаний, 54 unit/widget-теста,
  2 Android 35 integration-теста, OSV/source security checks, сборка и публикация.
  Сертификаты CI release и debug APK совпадают с закреплённым постоянным
  сертификатом и с локальным release APK.

Код интерфейса и интеграции совпадает с проверенной 1.4.0:
[54 unit/widget-теста и Android 35 integration](build_verification_1.4.md).
Физические биометрия/ПИН, камера и выгрузка данных устройств требуют проверки на телефоне.

## Переход и сохранность ключа

При несовпадении старого сертификата нужна одна переустановка с предварительным
экспортом JSON. Последующие APK, подписанные этим ключом, обновляются без удаления
при неизменном applicationId и неуменьшающемся versionCode. Не генерируйте ключ заново.
Сохраните защищённую копию JKS и key.properties: GitHub Secrets нельзя прочитать обратно.
