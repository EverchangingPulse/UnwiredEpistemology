# ADR 0001: ClojureDart and Flutter for Android delivery

## Status

Accepted for the architecture scaffold.

## Context

The product must be mostly Clojure, target Android, and produce an installable APK using GitHub Actions. The archived JVM Clojure Android tooling does not satisfy the maintenance requirement. Writing the app primarily in Kotlin would violate the Clojure-first constraint.

## Decision

Use ClojureDart for domain, application, and UI code. Use Flutter as the maintained Android runtime and packaging toolchain. Keep Dart, Kotlin, Java, Gradle, and Android-specific code generated or confined to platform boundaries.

Pin ClojureDart to immutable commit `721e927ac7d3417b36e0187ccaff17b455e50897`, dated 2026-07-21. Use Clojure `1.12.5` through the current Clojure CLI toolchain. Use the Flutter stable channel in CI.

No additional runtime package is introduced in the first milestone.

## Consequences

- Product logic and the initial UI are written in a Clojure dialect.
- Flutter produces a standard Android APK.
- Native Bluetooth and Wi-Fi capabilities will require Flutter plugins or thin platform adapters.
- ClojureDart is less mature than Clojure/JVM, so every compiler upgrade requires domain tests and an APK build.
- The Flutter version should be pinned after the first green CI build establishes a verified compatibility baseline.

## Exit strategy

Domain policy remains immutable-data transformations without Flutter imports. If the UI toolchain must change, port the small application boundary while retaining the behavior specifications and state-machine tests.
