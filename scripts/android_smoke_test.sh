#!/usr/bin/env bash
set -euo pipefail

app_apk="${APP_APK:-build/app/outputs/flutter-apk/app-debug.apk}"
aapt_path="$(find "${ANDROID_HOME}/build-tools" -type f -name aapt | sort -V | tail -1)"
test -x "${aapt_path}"

app_id="$(${aapt_path} dump badging "${app_apk}" \
  | sed -n "s/package: name='\([^']*\)'.*/\1/p")"
test -n "${app_id}"
launch_activity="$(${aapt_path} dump badging "${app_apk}" \
  | sed -n "s/launchable-activity: name='\([^']*\)'.*/\1/p")"
test -n "${launch_activity}"

adb install -r "${app_apk}"
for permission in \
  android.permission.CAMERA \
  android.permission.ACCESS_FINE_LOCATION \
  android.permission.BLUETOOTH_ADVERTISE \
  android.permission.BLUETOOTH_CONNECT \
  android.permission.BLUETOOTH_SCAN \
  android.permission.NEARBY_WIFI_DEVICES; do
  adb shell pm grant "${app_id}" "${permission}" 2>/dev/null || true
done
adb logcat -c
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
adb shell am start -W -n "${app_id}/${launch_activity}"

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

dump_contains() {
  local remote_path="$1"
  local local_path="$2"
  local expected="$3"
  for attempt in 1 2 3 4 5 6 7 8; do
    adb shell uiautomator dump "${remote_path}" >/dev/null 2>&1 || true
    if adb pull "${remote_path}" "${local_path}" >/dev/null 2>&1 \
      && grep -q "${expected}" "${local_path}"; then
      return 0
    fi
    sleep 2
  done
  adb shell dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' || true
  adb logcat --pid="${app_pid}" -d || true
  test -f "${local_path}" && sed -n '1,40p' "${local_path}" || true
  return 1
}

dump_contains /sdcard/window.xml build/window.xml 'P2P Spectrum'

# The dynamic room button follows the invitation field and QR action.
adb shell input tap 160 349
sleep 2
dump_contains /sdcard/room-window.xml build/room-window.xml \
  'Choose the first question'

! adb logcat --pid="${app_pid}" -d | grep -q 'FATAL EXCEPTION'
