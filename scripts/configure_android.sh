#!/usr/bin/env bash
set -euo pipefail

manifest="android/app/src/main/AndroidManifest.xml"

sed -i '/<application/i\
    <uses-permission android:name="android.permission.CAMERA" />\
    <uses-permission android:maxSdkVersion="30" android:name="android.permission.BLUETOOTH" />\
    <uses-permission android:maxSdkVersion="30" android:name="android.permission.BLUETOOTH_ADMIN" />\
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />\
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />\
    <uses-permission android:maxSdkVersion="28" android:name="android.permission.ACCESS_COARSE_LOCATION" />\
    <uses-permission android:minSdkVersion="29" android:maxSdkVersion="31" android:name="android.permission.ACCESS_FINE_LOCATION" />\
    <uses-permission android:minSdkVersion="31" android:name="android.permission.BLUETOOTH_ADVERTISE" />\
    <uses-permission android:minSdkVersion="31" android:name="android.permission.BLUETOOTH_CONNECT" />\
    <uses-permission android:minSdkVersion="31" android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />\
    <uses-permission android:minSdkVersion="32" android:name="android.permission.NEARBY_WIFI_DEVICES" android:usesPermissionFlags="neverForLocation" />' "$manifest"

sed -i '/<\/activity>/i\
            <intent-filter>\
                <action android:name="android.intent.action.VIEW" />\
                <category android:name="android.intent.category.DEFAULT" />\
                <category android:name="android.intent.category.BROWSABLE" />\
                <data android:scheme="unwiredepistemology" />\
            </intent-filter>' "$manifest"
