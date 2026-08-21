# Unwired Epistemology

Unwired Epistemology is a Clojure-first Android application for anonymous, peer-to-peer spectrum discussions.

The application contains a business-driven replicated room cycle, a framework-independent ClojureDart domain core, deterministic state transitions, offline Nearby Connections, manual serverless WebRTC negotiation, and automated convergence tests. GitHub Actions compiles the ClojureDart source, runs the tests, builds an Android APK, launches it in an emulator, and publishes the APK as a workflow artifact.

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
- Nearby Connections for encrypted Bluetooth, BLE, and Wi-Fi links
- Flutter WebRTC for direct internet data channels
- Android secure storage and X25519 invitation keys
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
flutter build apk --release
```

The APK is written beneath `build/app/outputs/flutter-apk/`.

## Domain tests

After initialization:

```bash
dart pub add --dev test
clojure -M:cljd compile \
  unwired-epistemology.domain.peer-events-test \
  unwired-epistemology.domain.identity-test \
  unwired-epistemology.domain.admission-test \
  unwired-epistemology.domain.likert-test \
  unwired-epistemology.domain.questions-test \
  unwired-epistemology.domain.voting-test \
  unwired-epistemology.domain.empathy-test \
  unwired-epistemology.application.room-test \
  unwired-epistemology.application.identity-test \
  unwired-epistemology.application.peer-observer-test \
  unwired-epistemology.application.runtime-test
flutter test test/cljd-out
```

## Delivery

The `Android APK` workflow runs on pull requests, pushes to `main`, and manual dispatch. Its `unwired-epistemology-release-apk` artifact contains an optimized, installable release-mode APK. Until a private production keystore is supplied through protected repository secrets, Android's generated test signing identity is used; this APK is suitable for direct testing, but not Play Store publication or a stable production upgrade path.

## Scope

Implemented now:

- seven-value Likert domain;
- room-scoped membership;
- strict-majority question approval;
- blind-vote commitment readiness;
- deterministic reveal gating;
- post-reveal repositioning;
- exact `[1,7]` and `[2,6]` empathy-pair detection;
- pure application reducer and effect descriptions;
- Observer-based peer-event ingestion with deduplication and ordering;
- room-scoped anonymous identity generation with Android Keystore-backed restoration;
- deterministic Clojure wire protocol and hybrid-transport mesh relaying;
- approval, rejection, moderator assignment, removal, and admission recovery;
- system, saved-session, custom, and peer-shared question queues;
- SHA-256 vote commitments, isolated selections, deterministic reveal barrier, and live repositioning;
- seven-zone spectrum rendering with vertically stacked anonymous nicknames;
- targeted opposite-side perspective prompts and private recipient UI;
- code, Android link, QR generation, QR scanning, and manual offer/answer exchange;
- encrypted local session restoration and persisted outbound sequence recovery;
- multi-session direct WebRTC channels and simultaneous Nearby/WebRTC delivery.

Deployment-dependent limitations:

- symmetric NAT traversal can require a TURN relay, which is intentionally not bundled because rooms must remain direct P2P;
- verified HTTPS Android App Links require an owned HTTPS domain, its `assetlinks.json`, and the final release signing certificate;
- release APK/AAB signing requires a protected signing key configured in GitHub Actions;
- Bluetooth radio interoperability and internet NAT combinations require a physical-device test matrix in addition to the automated emulator gate.

See `CODE_STYLE.md`, `FEATURE_DEVELOPMENT_CONSTRAINTS.md`, and `docs/adr/0001-clojuredart-flutter.md`.
