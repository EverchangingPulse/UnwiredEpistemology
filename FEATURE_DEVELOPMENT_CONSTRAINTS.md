# Feature Development Constraints: P2P Spectrum App

## 1. Status and interpretation

This file defines mandatory product and engineering constraints. The terms **MUST**, **MUST NOT**, **SHOULD**, and **MAY** are normative.

- A feature is incomplete if it violates a **MUST** or **MUST NOT** rule.
- Product behavior described here takes precedence over implementation convenience.
- The project architecture and code must also comply with `CODE_STYLE.md`.
- Ambiguities listed under Open Decisions MUST be resolved before the affected feature is implemented.
- An implementation MUST NOT silently replace peer-to-peer behavior with a centralized service.

## 2. Product objective

The app enables anonymous participants to join a shared room, vote on a sequence of questions, reveal the distribution only after everyone has voted, reposition themselves during discussion, and exchange targeted perspective-taking messages with participants holding specific opposing positions.

Rooms MUST work across local and remote peer-to-peer transports and MUST support both transport types in the same live room.

## 3. Architectural invariants

### 3.1 Peer-to-peer only

- Room state, membership, questions, approvals, votes, reveal state, nicknames, and empathy messages MUST be exchanged directly among participating peers.
- A central cloud database, authoritative application server, hosted room coordinator, mandatory relay, or server-owned room state is prohibited.
- No peer MAY become a permanent source of truth merely because that peer created the room.
- The room MUST continue when the original host disconnects, provided enough mutually reachable peers remain to form a valid room.
- A temporary coordinator MAY be elected by the peers for ordering or coordination, but its authority MUST be derived from replicated room state and MUST be recoverable through deterministic re-election.
- The replicated protocol MUST define message identity, sender identity, room identity, schema version, causal or deterministic ordering information, replay protection, and integrity verification.
- Duplicate, delayed, reordered, or replayed messages MUST NOT corrupt room state or produce duplicate actions.
- Conflict resolution MUST be deterministic so peers converge after partitions and reconnections.

### 3.2 Clean architecture boundary

- Domain rules MUST be independent of Bluetooth, Wi-Fi, TCP/IP, Android, QR scanning, storage, and UI frameworks.
- Transport adapters MUST expose the same application-level message contract.
- Transport selection, fallback, and simultaneous routing MUST NOT alter domain semantics.
- The voting and room-state engines MUST be executable and testable with an in-memory transport.
- The business application MUST own runtime control and invoke the graphical interface through an injected presentation API.
- Graphical code MUST NOT import or call application services or domain functions. It MAY emit user events only through callbacks supplied by the application.
- The executable entry point MUST be a composition root that assembles adapters and starts the business application.

## 4. Transport and topology constraints

### 4.1 Supported links

The application MUST support these physical paths:

- **Local link:** Bluetooth Low Energy or Wi-Fi Direct for co-located peers.
- **Remote link:** TCP/IP over internet-connected Wi-Fi or cellular data.

Bluetooth and internet transport MUST be capable of operating simultaneously. A room MAY contain Bluetooth-only peers, internet-only peers, and bridge peers connected through both.

### 4.2 Mesh and bridging

- Each peer MUST advertise the transports through which it is reachable.
- A peer connected to multiple network partitions MUST be capable of forwarding permitted room protocol messages between them.
- Forwarded messages MUST retain their original sender and message identity.
- Loop prevention, deduplication, hop limits or equivalent safeguards, and replay protection are mandatory.
- A transport handover MUST preserve participant identity, nickname, submitted vote, approvals, active question, reveal state, and queued messages.
- The protocol MUST tolerate temporary partitions and converge when connectivity returns.
- Sensitive room traffic MUST be authenticated and encrypted in transit on every transport.

### 4.3 Room connection modes

Room creation MUST offer exactly these connection modes:

1. **Strictly Local**: discovery and joining are restricted to Bluetooth or local Wi-Fi discovery.
2. **Strictly Remote**: joining is restricted to the WAN invitation mechanism.
3. **Dynamic Auto-Discovery**: both transport families are allowed and transport selection or fallback is automatic. This is the default.

For Dynamic Auto-Discovery:

- The app MUST prefer a currently healthy route according to an explicit policy.
- Loss of internet connectivity MUST trigger discovery of an eligible local route without resetting room state.
- Recovery of internet connectivity MAY restore remote paths without duplicating the participant or their messages.
- Switching transport MUST NOT cause a visible room departure when continuous logical membership can be preserved.
- Users MUST be able to see the current room mode and their current connection status.

### 4.4 Invitation vectors

The same invitation state MUST be representable as:

- an alphanumeric room code;
- a standard URL hyperlink;
- a high-density dynamic QR code readable by a device camera.

All three forms MUST resolve to the same canonical invitation payload and room identity. The payload MUST be versioned and integrity-protected.

Invitations MUST NOT contain reusable private identity keys, plaintext secrets that expose past room content, or more routing data than is required to join.

Invalid, expired, incompatible, or tampered invitations MUST produce distinct user-visible errors.

## 5. Identity and anonymity constraints

### 5.1 Generated identity

- On first entry into a room, the client MUST generate a random, neutral nickname such as `Anonymous Owl` or `Pixel Fox`.
- Users MUST NOT type, edit, or select a custom nickname.
- Nickname generation SHOULD minimize collisions within a room.
- A nickname collision MUST be resolved deterministically or by generating another neutral nickname before membership is finalized.
- Public room data MUST NOT expose a device name, account identifier, telephone number, network address, contact entry, advertising identifier, or stable cross-room identifier.
- Room-scoped peer identities MUST NOT be linkable across rooms by other participants.

### 5.2 Room-scoped persistence

- The local client MUST securely associate the room identity with the participant's room-scoped identity and generated nickname.
- Rejoining the same room after signal loss, app closure, process death, or transport handover MUST restore the exact original nickname.
- Rejoining MUST restore the same logical participant instead of increasing the active member count.
- Persistence MUST be local to the participant's device and protected from unauthorized access.
- Clearing app data, uninstalling the app, or losing the room-scoped secret MAY prevent identity restoration; the UI MUST not falsely claim successful restoration.
- “Absolute anonymity” is a product goal, not a claim that MAY be presented without a documented threat model and verification. The implementation MUST document observable metadata and residual privacy risks.

## 6. Room and membership state

At minimum, the replicated room state MUST represent:

- canonical room identity and protocol version;
- room connection mode;
- active, temporarily disconnected, and departed participants;
- room-scoped peer identities and nicknames;
- current question and question phase;
- system catalogue entries available to the room;
- submitted questions and their approval state;
- votes and reveal readiness without leaking blind selections;
- post-reveal positions;
- empathy-pair state and private message delivery acknowledgements.

### 6.1 Admission control

- A remote invitation MUST carry the complete connection offer and routing material required to deliver a join request without a discovery or signaling service.
- Remote invitation data MAY be long. Links and QR codes MUST preserve it losslessly. A short code MUST NOT claim remote reachability unless it contains or resolves the required connection data without central infrastructure.
- Joining from an invitation MUST create a pending request. Invitation possession alone MUST NOT activate membership.
- Room creation MUST select one of these admission modes:
  - `creator-only`: only the creator may approve or reject join requests and remove participants;
  - `moderators`: the creator and explicitly delegated moderators may approve, reject, or remove participants;
  - `any-member`: any active participant may approve or reject join requests, while the creator and delegated moderators retain removal authority.
- The room creator MUST be recorded as a room-scoped identity and MUST retain authority to grant or revoke moderator status.
- Moderator authority MUST be room-scoped, replicated, versioned, and auditable.
- The creator MUST NOT be removable through ordinary participant-removal commands.
- Every join request, approval, rejection, moderator change, and removal MUST produce a deterministic audit event without exposing cross-room identity.
- A removed identity MUST NOT rejoin from an old invitation without a new explicit approval.

### 6.2 Membership definition

- The protocol MUST define when a peer becomes active, temporarily disconnected, departed, or evicted.
- The active-node set used by approval and reveal barriers MUST be based on a deterministic membership snapshot or version.
- Membership changes during a vote MUST follow a deterministic rule and MUST NOT leave the room permanently blocked.
- All peers MUST converge on the same membership version before using it to declare reveal readiness.
- Reconnection MUST reconcile state before the peer can create new actions.

## 7. Question catalogue and queue

### 7.1 Sequential cycles

- A room MUST support multiple sequential question cycles.
- Exactly one question MAY be in the live voting or post-reveal discussion phase at a time.
- Completing one cycle MUST NOT discard the remaining approved queue.
- Each cycle MUST have a stable question identifier independent of its text.

### 7.2 Sources

The question pool MUST accept:

- **System catalogue questions:** preloaded philosophical, legal, and sociological macro-claims.
- **User-generated questions:** prompts typed and submitted by any active peer.

Catalogue questions MUST be stored locally and MUST be usable without internet access. Shared catalogue entries MUST include a stable identifier, content version, language, source classification, and question text.

### 7.3 Democratic approval

- A user-generated question MUST enter a holding queue and MUST NOT become active immediately.
- Every active participant MUST be able to cast one approval decision per submitted question.
- A question is promoted only after reaching the configured democratic threshold.
- Unless another rule is selected before room creation, the threshold MUST be a strict simple majority: approvals greater than half of the eligible membership snapshot.
- The eligibility snapshot, approval count, threshold, and final status MUST be reproducible from replicated state.
- Duplicate approvals from one logical participant MUST count once.
- Ties MUST NOT promote a question under strict simple-majority rules.
- The ordering of multiple approved questions MUST be deterministic.
- Editing a submitted question after approval begins MUST create a new version and invalidate approvals for the earlier text.

## 8. Voting constraints

### 8.1 Seven-point Likert scale

The only valid vote values are:

| Value | Label |
| ---: | --- |
| 1 | Strongly Disagree |
| 2 | Disagree |
| 3 | Slightly Disagree |
| 4 | Neutral |
| 5 | Slightly Agree |
| 6 | Agree |
| 7 | Strongly Agree |

- The wire protocol and domain model MUST use the integer value as the canonical value.
- Labels MUST be localized without changing their numeric meaning.
- No fractional, missing, out-of-range, or alternate response MAY count as a submitted vote.

### 8.2 Question state machine

Each question MUST follow these logical phases:

```text
queued -> voting -> reveal-ready -> revealed -> discussion -> closed
```

- Invalid phase transitions MUST be rejected.
- A new question MUST NOT enter `voting` while the current question remains active.
- A peer joining after the voting membership snapshot MUST follow the defined late-join policy and MUST NOT silently change the reveal denominator.

### 8.3 Blind vote isolation

- While a question is in `voting`, no peer may display another participant's selection.
- Plaintext vote selections MUST NOT be broadcast before the reveal barrier.
- Vote readiness and vote content MUST be represented separately.
- The protocol MUST provide a verifiable commit-then-reveal mechanism or an equivalent design that prevents peers from learning selections early while still proving that every eligible peer submitted exactly one valid committed vote.
- Logs, analytics, notifications, accessibility descriptions, debug screens, and transport metadata MUST NOT leak blind vote content.

### 8.4 Deterministic reveal barrier

- The room MUST compare the current voting membership snapshot with valid submitted commitments.
- When the final eligible active participant has submitted, every converged peer MUST transition exactly once to `reveal-ready`.
- Each device MUST show a modal containing exactly: `The votes are ready to be revealed.`
- The graphical distribution MUST remain hidden on that device until that device's user selects `[OK]`.
- Acknowledging the modal reveals the result only on that device; one user's acknowledgement MUST NOT dismiss another user's barrier.
- Duplicate readiness messages MUST NOT display duplicate modals or advance the state twice.
- Vote content MUST be disclosed only through the reveal protocol after readiness is established.
- A missing or invalid reveal MUST have a deterministic timeout and failure policy defined before implementation.

### 8.5 Post-reveal repositioning

- After reveal, a participant MAY move to any other valid Likert value during discussion.
- A changed position MUST be broadcast immediately across all reachable room paths.
- Every peer MUST update the participant's existing marker; it MUST NOT create another participant or another historical vote.
- Updates MUST include deterministic ordering so older positions cannot overwrite newer ones after network delay.
- Repositioning MUST NOT rewrite the original blind-vote audit value if historical comparison is retained.

## 9. Spectrum interface constraints

- The result UI MUST display one horizontal spectrum divided into seven visibly distinct zones in canonical numeric order.
- The current user's marker and every revealed participant marker MUST correspond to the canonical Likert value.
- Each marker MUST display the participant's generated nickname above or below the spectrum.
- Nicknames at the same value MUST stack vertically without overlap, clipping, or hidden labels.
- Stacking MUST update smoothly when membership or positions change.
- Layout MUST remain usable with large accessibility fonts, translated labels, narrow screens, and the maximum supported room size.
- Color MUST NOT be the only means of distinguishing zones or positions.
- Before local reveal acknowledgement, the UI MUST NOT expose distribution information through layout, counts, accessibility nodes, animations, or placeholder geometry.

## 10. Cognitive empathy triggers

### 10.1 Exact pair detection

The empathy flow MUST trigger only for these opposing value pairs:

- Type A: `Strongly Disagree [1]` paired with `Strongly Agree [7]`.
- Type B: `Disagree [2]` paired with `Agree [6]`.

No other combination, including `[3]` with `[5]`, may trigger this flow.

- Detection occurs only after the question is revealed on the relevant device.
- Repositioning MUST re-evaluate pair eligibility.
- The protocol MUST deterministically select recipients when more than one participant occupies either side.
- A participant MUST NOT receive duplicate prompts for the same pairing version.
- Leaving an eligible pair MUST invalidate any unsent prompt tied to that obsolete position version.

### 10.2 Perspective-taking prompt

For a selected opposing pair, the app MUST show the relevant participant this modal text:

> You are on the opposite side of another participant. Try to guess the exact underlying reason or logical baseline for why they hold their opposing view.

- The modal MUST include a text input and a submission action.
- Empty guesses MUST NOT be submitted.
- The sender MUST be shown the target's room nickname and opposing position, but no private or cross-room identity.
- The guess MUST NOT be posted to a public board or broadcast in plaintext to unrelated peers.

### 10.3 Private empathy route

- A submitted guess MUST be encrypted so only the intended opposing participant can read it.
- Mesh forwarding peers MUST be able to route the message without reading its content.
- The target device MUST display the guess in a dedicated notification modal.
- Delivery MUST be idempotent and MUST survive temporary disconnection according to a defined room-scoped retention policy.
- The sender MUST receive delivery state without receiving private device or network details.
- Message content MUST be deleted according to the room retention policy and MUST NOT become a permanent cross-room profile.

## 11. Security, privacy, and abuse constraints

- Room membership and protocol messages MUST be authenticated with room-scoped cryptographic identity.
- End-to-end encryption is mandatory for private empathy messages and SHOULD protect all room traffic from non-members.
- Invitation possession alone MUST NOT expose prior room content.
- The protocol MUST protect against spoofed members, nickname takeover, forged votes, replayed approvals, duplicate membership, and unauthorized room-state mutation.
- User-generated prompts and empathy messages MUST be treated as untrusted input and rendered without executable markup.
- The UI MUST provide a safe way to leave a room and erase its local room-scoped identity and content.
- Resource limits MUST protect peers from oversized messages, question flooding, connection flooding, QR payload abuse, and unbounded queues.
- Privacy and safety behavior MUST function without a central moderation service.

## 12. Offline and recovery constraints

- Strictly Local rooms MUST remain usable without internet access.
- Catalogue reading, question submission, approval, voting, reveal, repositioning, and empathy routing MUST work within a connected local mesh.
- Process death and app restart MUST not corrupt persisted room identity or accepted replicated state.
- Reconnected peers MUST authenticate, exchange state summaries, request missing operations, and converge before participating again.
- Partial writes MUST be recoverable or rejected atomically.
- Protocol and stored-state schema migrations MUST preserve supported room state or fail explicitly.

## 13. Acceptance gates

A feature release MUST demonstrate at least these scenarios:

1. Three local peers join the same room using code, link, and QR invitation forms.
2. Remote peers join a WAN room without any central room-state service.
3. One room contains Bluetooth-only, internet-only, and dual-connected peers and converges on the same state.
4. Dynamic mode survives loss and recovery of internet connectivity without duplicating identities or votes.
5. The original host leaves and the remaining reachable peers continue the room.
6. A participant rejoins the same room after process death with the exact original nickname.
7. A submitted question fails on a tie and passes only after achieving a strict majority.
8. No peer can observe another vote before commit completion and the reveal protocol.
9. The final vote causes exactly one readiness modal per device, and results remain locally hidden until `[OK]`.
10. Multiple peers at one value produce readable, non-overlapping nickname stacks.
11. A post-reveal move propagates once and older delayed updates do not overwrite it.
12. Only `[1]-[7]` and `[2]-[6]` trigger empathy prompts; `[3]-[5]` does not.
13. A private empathy guess is readable only by its target even when forwarded through other peers.
14. Partitioned groups reconnect and deterministically converge without losing accepted operations.
15. Malformed, replayed, duplicated, oversized, and unauthorized protocol messages are rejected safely.

## 14. Open decisions that block implementation

The following decisions MUST be recorded before their affected feature is considered ready:

- **Remote discovery and NAT traversal:** a purely serverless room code cannot generally discover or connect arbitrary peers behind NAT or restrictive firewalls. Define the supported reachability model, IPv6 assumptions, manual endpoint exchange, local port mapping, distributed discovery mechanism, and behavior when direct connectivity is impossible. Mandatory central STUN, TURN, signaling, or relay infrastructure would conflict with the current P2P-only constraint and requires an explicit product decision.
- **BLE capability:** define whether BLE is only for discovery and negotiation or also transports room messages, plus payload fragmentation, throughput, background limits, and supported Android versions.
- **Wi-Fi Direct versus multicast:** define which mechanism is mandatory and how devices remain connected to internet Wi-Fi while participating locally on Android hardware that restricts concurrent network roles.
- **Consensus model:** define operation ordering, leader election if any, quorum assumptions, split-brain handling, and deterministic conflict resolution.
- **Active membership:** define heartbeat intervals, disconnection grace period, voluntary departure, eviction, and how membership changes affect an in-progress vote.
- **Late joiners:** define whether they observe, join the next question, or restart the current voting snapshot.
- **Reveal failure:** define behavior when a peer commits but never reveals, including timeout, exclusion, restart, or cancellation.
- **Approval scope:** confirm whether “from all active nodes” means all may vote with simple-majority promotion or unanimous approval.
- **Question ordering:** define promotion order, tie breaking, duplicate detection, withdrawal, rejection, and queue limits.
- **Pair multiplicity:** when several peers are on each opposing side, define one-to-one matching, all-to-all prompts, deterministic rotation, or another bounded policy.
- **Empathy consent and safety:** define whether forced input may be skipped, reporting/blocking behavior, message size, expiry, delivery retry, and abuse mitigation.
- **Room limits:** define maximum active peers, queued questions, message size, catalogue size, and retained history.
- **Room lifetime:** define expiration, archival, secure deletion, and whether a room can be resumed after all peers leave.
- **Invitation lifetime:** define expiration, revocation, rotation, join authorization, and whether QR content is static or dynamically refreshed.
- **Threat model:** define protected assets, attackers, metadata exposure, device compromise assumptions, and the precise anonymity claim allowed in product copy.
- **Accessibility and localization:** define supported locales, bidirectional layout, screen-reader behavior, reduced motion, and minimum contrast targets.

## 15. Definition of feature complete

A feature is complete only when:

- its domain behavior is expressed independently of transport and Android APIs;
- its relevant constraints and acceptance gates pass under deterministic automated tests;
- local, remote, mixed, partitioned, and reconnecting topologies are tested where applicable;
- privacy properties are tested, including absence of blind-vote and private-message leakage;
- replicated state converges under duplicate, reordered, delayed, and replayed messages;
- Android lifecycle and permission failures are handled explicitly;
- accessibility behavior is verified;
- security review covers the new protocol messages and persisted data;
- unresolved decisions affecting the behavior have approved architecture decision records;
- no central service has been introduced implicitly.
