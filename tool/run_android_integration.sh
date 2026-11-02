#!/usr/bin/env bash
set -euo pipefail
mkdir -p .reports
adb -s emulator-5554 logcat -c
trap 'adb -s emulator-5554 logcat -d -t 500 > .reports/integration-logcat.txt || true; tail -n 150 .reports/integration-logcat.txt || true' ERR
flutter test integration_test -d emulator-5554 --timeout 20m
