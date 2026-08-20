#!/usr/bin/env bash
set -euo pipefail

app_apk="build/app/outputs/flutter-apk/app-debug.apk"
aapt_path="$(find "${ANDROID_HOME}/build-tools" -type f -name aapt | sort -V | tail -1)"
test -x "${aapt_path}"

app_id="$(${aapt_path} dump badging "${app_apk}" \
  | sed -n "s/package: name='\([^']*\)'.*/\1/p")"
test -n "${app_id}"

adb install -r "${app_apk}"
adb logcat -c
adb shell monkey -p "${app_id}" -c android.intent.category.LAUNCHER 1

app_pid=""
for attempt in 1 2 3 4 5 6 7 8; do
  app_pid="$(adb shell pidof "${app_id}" 2>/dev/null | tr -d '\r' || true)"
  test -n "${app_pid}" && break
  sleep 2
done
if test -z "${app_pid}"; then
  adb logcat -d | tail -300
  exit 1
fi

sleep 4
adb shell uiautomator dump /sdcard/window.xml
adb pull /sdcard/window.xml build/window.xml
grep -q 'P2P Spectrum' build/window.xml

# The first room-mode button is centered in the upper half on the test AVD.
adb shell input tap 160 230
sleep 2
adb shell uiautomator dump /sdcard/room-window.xml
adb pull /sdcard/room-window.xml build/room-window.xml
grep -q 'Choose the first question' build/room-window.xml

! adb logcat --pid="${app_pid}" -d | grep -q 'FATAL EXCEPTION'
