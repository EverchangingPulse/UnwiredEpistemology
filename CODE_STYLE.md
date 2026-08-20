# Code Style and Architecture Rules

## 1. Purpose and priority

This document defines the default engineering rules for the project. Apply them in this order when rules compete:

1. Correctness, safety, and explicit product requirements.
2. Domain clarity and architectural boundaries.
3. Simplicity, testability, and maintainability.
4. Functional programming and immutability.
5. Clojure-first implementation.
6. Performance optimization supported by measurements.

Exceptions require a short written rationale, a narrow scope, and a test that protects the reason for the exception.

## 2. Core design principles

### SOLID

- **Single Responsibility:** each namespace, component, protocol, function, and data transformation has one reason to change.
- **Open/Closed:** extend behavior by adding data, functions, multimethod methods, or boundary implementations. Avoid editing stable domain policy for every new case.
- **Liskov Substitution:** every implementation honors the complete contract of the abstraction, including errors, ordering, nullability, timing, and resource ownership.
- **Interface Segregation:** expose small, consumer-specific protocols or function maps. Do not create broad service interfaces.
- **Dependency Inversion:** domain and application policy depend on abstractions and plain data. Frameworks, storage, networking, Android APIs, and external libraries implement or consume those boundaries.

Prefer ordinary functions and data over protocols. Introduce a protocol only when multiple runtime implementations or a genuine polymorphic boundary exist.

### Clean Architecture

- Dependencies point inward: `frameworks -> adapters -> application -> domain`.
- Domain code contains business rules and Clojure data. It imports no Android, database, HTTP, serialization, UI, or vendor API.
- Application code coordinates use cases and depends only on domain code and explicit boundary contracts.
- Adapters translate external representations into internal data and internal results back into external representations.
- Framework code owns Android lifecycle integration, persistence drivers, HTTP clients, dependency assembly, and process entry points.
- No external DTO, ORM entity, Android object, exception type, or library-specific value crosses an inward boundary.
- Boundary translation happens once, at the edge.
- The composition root is the only place that knows concrete implementations for all dependencies.
- Business/application logic owns runtime control. It invokes graphical presentation through an injected, narrow view API.
- The graphical interface MUST NOT import, locate, or call business services. User events enter callbacks or command sinks supplied by the application layer.
- The executable entry point only assembles dependencies and starts the application; it contains no presentation or business behavior.

Suggested namespace direction:

```text
app.domain.*
app.application.*
app.adapter.*
app.platform.android.*
app.infrastructure.*
app.main
```

Namespace names describe domain capability rather than technical buckets whenever possible.

## 3. Top-down construction

Build from policy and abstraction toward implementation. Do not begin with UI widgets, database schemas, framework classes, or vendor SDK calls.

For every feature:

1. State the user-visible outcome and acceptance examples.
2. Define domain vocabulary and represent it with simple immutable data.
3. Define invariants, decisions, and failure values.
4. Define the use-case function from input data to output data.
5. Identify effects and describe the smallest required boundary contracts.
6. Write executable examples or tests against the abstraction.
7. Implement the domain policy as pure functions.
8. Implement application orchestration with effects passed explicitly.
9. Implement adapters for storage, networking, time, randomness, Android, and other external systems.
10. Assemble concrete dependencies at the composition root.
11. Add UI and delivery details last.
12. Measure before optimizing and retain the original behavioral tests.

Use walking skeletons only after the central use case and its boundaries are understood. A skeleton must prove dependency direction without embedding business logic in framework code.

## 4. Functional programming rules

- Prefer pure functions. The same arguments produce the same result and no hidden state change.
- Use immutable persistent data by default.
- Model transformations as values flowing through small functions.
- Separate decisions from effects: pure code decides what should happen; edge code performs it.
- Pass dependencies, clocks, random generators, configuration, and effectful operations explicitly.
- Return data that describes success or expected failure. Reserve exceptions for unexpected, unrecoverable, or boundary-specific failures.
- Make illegal states difficult to represent through constructors, predicates, specs, schemas, and validated transitions.
- Prefer total functions. Define behavior for every valid input and validate data at boundaries.
- Prefer composition, higher-order functions, transducers, reducers, sequence operations, and data-driven dispatch over inheritance and stateful control flow.
- Use recursion only when the standard sequence abstractions do not express the operation clearly. Use `recur` for intentional loops.
- Keep effects at the edges and make effect order visible.
- Do not hide effects in lazy sequences.
- Avoid shared mutable state. When identity and coordinated change are essential, choose the narrowest suitable Clojure reference type and centralize state transitions.
- Keep state machines explicit: state plus event yields new state plus effect descriptions.
- Design concurrent code around immutable messages and ownership. Do not share mutable platform objects across components.

## 5. Clojure-first rules

- Write domain, application, validation, transformation, orchestration, and state-transition code in Clojure.
- Prefer Clojure libraries and idioms when they meet the requirement and are healthy enough for production.
- Use Clojure data structures at internal boundaries.
- Prefer maps, vectors, sets, keywords, qualified keys, and small functions over class hierarchies and mutable object graphs.
- Use destructuring when it improves clarity; avoid deeply nested or clever destructuring.
- Use threading macros for a readable transformation pipeline, not to conceal incompatible operations or effects.
- Use `let` to name meaningful intermediate values. Keep bindings close to use.
- Use namespaced keywords for data shared across modules.
- Use predicates with a `?` suffix and effectful commands with clear verbs.
- Avoid macros unless ordinary functions cannot provide the needed semantics. Every custom macro requires tests and a clear reduction in conceptual complexity.
- Avoid Java/Kotlin wrappers that merely rename Clojure functions.

### Android exception boundary

- Keep Java or Kotlin limited to unavoidable Android entry points, lifecycle bridges, generated interfaces, build tooling, and APIs that Clojure cannot integrate with safely or clearly.
- Keep each non-Clojure bridge thin, stable, and behavior-free. It converts platform calls and values into Clojure data and invokes Clojure functions.
- Do not duplicate domain logic in Java or Kotlin.
- Do not leak `Activity`, `Fragment`, `Context`, `View`, `Bundle`, coroutine scope, callback, or Android lifecycle objects into domain or application code.
- Treat lifecycle, permissions, storage, background execution, navigation, and UI rendering as outer-layer effects.
- Make process death and state restoration explicit in application state design.
- Prefer a unidirectional data flow: event -> pure update -> new model plus effect descriptions -> renderer/effect handler.

## 6. Clean Code rules

- Optimize for the next reader. Prefer obvious code over clever code.
- Use names that reveal domain intent. Avoid vague names such as `data`, `info`, `manager`, `helper`, `util`, `processor`, and `thing` unless the domain uses that term.
- Functions should be small enough to explain with their name and should operate at one level of abstraction.
- Extract a function when a name communicates intent better than an inline expression.
- Do not use comments to compensate for unclear code. Improve names, structure, and boundaries. Comments are reserved for rationale, external constraints, and non-obvious trade-offs.
- Remove dead code, commented-out code, speculative abstractions, duplicate policy, and unused dependencies.
- Avoid boolean arguments. Prefer separate functions or descriptive option maps.
- Avoid long positional parameter lists. Prefer cohesive data maps with validated required keys.
- Keep public APIs minimal. Make implementation details private.
- Normalize inputs at boundaries; do not spread defensive parsing through the domain.
- Use one canonical representation for each concept inside the system.
- Make errors actionable and preserve their causes. Do not catch an error unless adding context, translating it at a boundary, retrying deliberately, or recovering.
- Never log secrets, credentials, access tokens, personal data, or complete sensitive payloads.
- Formatting is automatic and consistent. Do not hand-align code.
- Lint warnings and compiler warnings are failures unless explicitly suppressed with a documented rationale.

## 7. Data and contracts

- Prefer explicit data contracts over implicit map conventions.
- Validate untrusted data on entry and trusted assumptions at construction points.
- Use qualified keys across architectural boundaries.
- Distinguish absent, unknown, invalid, and empty when the domain distinguishes them.
- Do not use `nil` as a universal failure channel. Use a deliberate result shape for expected failures.
- Version persisted and remotely exchanged data when compatibility matters.
- Keep serialization formats out of domain models; translate them in adapters.
- Define preconditions and postconditions in tests or contract schemas, not as prose alone.

## 8. Effects and dependencies

- Treat I/O, time, randomness, environment access, logging, metrics, persistence, network calls, Android APIs, and global configuration as effects.
- Obtain effects through narrow injected functions, protocols, or component maps.
- Do not access global singletons from domain or application code.
- Keep transactions in application orchestration or infrastructure adapters; domain functions remain unaware of transaction machinery.
- Define timeouts, cancellation, retry policy, idempotency, and backoff at effect boundaries.
- Retries must be bounded and safe. Never retry non-idempotent work without an idempotency strategy.
- Resource acquisition and release must be lexical and deterministic.

## 9. Open-source dependency policy

Implement non-trivial lower-level capabilities last. Before building one, look for a mature open-source library, preferring a Clojure implementation.

A dependency is acceptable only when evidence shows:

- a license compatible with the project;
- active or intentionally stable maintenance;
- recent releases or credible maintenance activity appropriate to its maturity;
- responsive security handling and no unresolved critical advisory affecting the intended use;
- meaningful adoption, documentation, tests, and release history;
- compatibility with the supported Clojure, JVM, Android, and build-tool versions;
- an API smaller and more stable than the code it replaces;
- acceptable transitive dependency count, binary size, startup cost, and Android method impact;
- no unnecessary Java/Kotlin layer when a maintained Clojure option is equivalent.

Record the alternatives, maintenance evidence, license, version rationale, and exit strategy in a short architecture decision record. Re-evaluate dependency health during upgrades; “popular” and “recently updated” are signals, not proof.

Build locally when the capability is trivial, domain-specific, security-sensitive, smaller than the integration cost, or no candidate meets the criteria. Do not build custom cryptography, parsers for complex standards, databases, HTTP stacks, serialization engines, concurrency runtimes, or security protocols when a proven maintained implementation exists.

Wrap important third-party APIs behind narrow adapters when replacement cost or vendor coupling is material. Do not wrap stable standard-library functions without a concrete reason.

Pin direct dependency versions. Commit dependency lock data where the toolchain supports it. Automate vulnerability and outdated-dependency checks without accepting upgrades blindly.

## 10. Testing rules

- Test behavior and contracts, not private implementation details.
- Write most tests against pure domain functions; they should be fast, deterministic, and independent of Android or I/O.
- Use example tests for named business cases and generative/property tests for invariants and broad input spaces.
- Contract-test every adapter against the abstraction it implements.
- Use integration tests at real boundaries and a small number of end-to-end tests for critical journeys.
- Replace effects with deterministic fakes or injected functions. Do not mock immutable data or pure functions.
- Tests follow the same readability and architecture rules as production code.
- Every defect fix adds the smallest test that would have exposed it.
- Test failure paths, cancellation, retries, lifecycle changes, offline behavior, and state restoration where applicable.

## 11. Performance and observability

- Establish a measurable performance budget before optimizing.
- Prefer clear persistent-data code until profiling identifies a real bottleneck.
- Use transients, mutation, eager realization, caching, parallelism, or platform-specific code only behind a small boundary and only with benchmark evidence.
- Observability is an outer-layer effect. Domain code returns facts; adapters turn them into logs, traces, and metrics.
- Use structured events and correlation identifiers. Avoid logs that are only prose.

## 12. Definition of done

A change is complete only when:

- acceptance examples pass;
- domain rules are pure and independent of frameworks;
- dependency direction points inward;
- external data is translated and validated at boundaries;
- expected failures are modeled explicitly;
- new effects are isolated and tested;
- non-Clojure code is minimal and justified;
- new libraries satisfy the dependency policy and have an architecture decision record when material;
- formatting, linting, tests, security checks, and relevant benchmarks pass;
- duplicated code, obsolete paths, temporary workarounds, and unused dependencies are removed;
- documentation describes architectural decisions and operational constraints, not code that already explains itself.

## 13. Review checklist

Reject or revise a change when any answer below is “no”:

- Can the central business behavior run without Android, a database, a network, or a framework?
- Do dependencies point toward policy rather than toward implementation?
- Is the feature expressed first through domain data and use-case contracts?
- Are pure decisions separated from effect execution?
- Is mutation absent or isolated behind a justified boundary?
- Is Clojure used everywhere except unavoidable platform edges?
- Is every function and namespace at a consistent abstraction level?
- Is the amount of code and the public API close to the minimum needed?
- Are expected failures, lifecycle transitions, and boundary translations explicit?
- Does each third-party dependency provide more maintained value than its integration and replacement cost?
- Do tests protect behavior, invariants, and adapter contracts?
- Can an engineer replace an outer-layer implementation without changing domain policy?
