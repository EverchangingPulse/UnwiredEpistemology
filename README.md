# Unwired Epistemology

Unwired Epistemology is a Clojure-first Android application for anonymous, peer-to-peer spectrum discussions.

This first milestone contains an executable Flutter shell, a framework-independent ClojureDart domain core, deterministic state transitions, and automated domain tests. GitHub Actions compiles the ClojureDart source, runs the tests, builds an Android APK, and publishes the APK as a workflow artifact.

## Architecture

Dependencies point inward:

```text
composition root -> application -> domain
                         |
                         v
                 presentation API
                         |
                         v
                  Flutter adapter
```

The business application owns control and calls the graphical interface through an injected presentation API. The Flutter adapter never imports or calls the application or domain. The executable entry point only composes the application with the adapter.

The domain contains no Flutter, Android, Bluetooth, networking, storage, or cryptography implementation. Cryptographic verification and transport delivery enter through narrow function boundaries.

## Toolchain

- ClojureDart pinned to an immutable upstream commit
- Flutter stable
- Java 17
- Clojure CLI
- GitHub Actions for tests and APK delivery

The ClojureDart source is compiled to generated Dart. Generated Dart is not committed.

## Local initialization

Install Flutter stable, Java 17, and Clojure CLI, then run:

```bash
clojure -M:cljd init
dart pub add --dev test
clojure -M:cljd compile
flutter build apk --debug
```

The APK is written beneath `build/app/outputs/flutter-apk/`.

## Domain tests

After initialization:

```bash
dart pub add --dev test
clojure -M:cljd compile \
  unwired-epistemology.domain.admission-test \
  unwired-epistemology.domain.likert-test \
  unwired-epistemology.domain.questions-test \
  unwired-epistemology.domain.voting-test \
  unwired-epistemology.domain.empathy-test \
  unwired-epistemology.application.room-test \
  unwired-epistemology.application.runtime-test
flutter test test/cljd-out
```

## Delivery

The `Android APK` workflow runs on pull requests, pushes to `main`, and manual dispatch. Its `unwired-epistemology-debug-apk` artifact contains an installable debug APK. Release signing remains a later milestone and will use protected repository secrets.

## Scope

Implemented now:

- seven-value Likert domain;
- room-scoped membership;
- strict-majority question approval;
- blind-vote commitment readiness;
- deterministic reveal gating;
- post-reveal repositioning;
- exact `[1,7]` and `[2,6]` empathy-pair detection;
- pure application reducer and effect descriptions.

Deferred behind explicit ports and architecture decisions:

- BLE and Wi-Fi Direct adapters;
- internet P2P discovery and NAT traversal;
- cryptographic commitment implementation;
- encrypted transport and persistence;
- production Android UI and accessibility;
- signed release APK/AAB distribution.

See `CODE_STYLE.md`, `FEATURE_DEVELOPMENT_CONSTRAINTS.md`, and `docs/adr/0001-clojuredart-flutter.md`.
