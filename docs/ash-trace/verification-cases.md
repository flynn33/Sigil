# ASH-Trace Verification Cases

**Investigation:** `SIGIL-DEC-2026-10-09-ASH-TRACE`
**Product commit examined:** `53ba4895cdea2cb5d9188c369e1f980a2580067`
**Date:** 2026-11-02

Machine-readable form: [trace-ledger.json](trace-ledger.json) (`verification_cases`). This document is the human-readable mirror. Executed current-behavior observations are kept separate from proposed conformance oracles, per the investigation exit condition.

## Environment for the executed runs

macOS 27.0.1 (arm64), Xcode 27.0 (27A266a), Swift 6.4, git 2.54.0, Python 3.9.6. iOS simulator destination `SigilTraceiPhone17` (iOS 27.0 runtime). Fresh DerivedData directories and a fresh result bundle, all under the owner-external evidence root. Raw logs are cited by measured SHA-256 in the ledger sources and are not copied into this repository.

## Executed cases (current behavior at `53ba489`) — all passed

| Case | Description | Command (abridged) | Result | Evidence |
| --- | --- | --- | --- | --- |
| VC-EXEC-01 | Determinism of canonical and visible artifacts | `xcodebuild ... -scheme SigilApp -configuration Debug -destination 'platform=iOS Simulator,id=<SigilTraceiPhone17>' test` (fresh DerivedData) | `TEST SUCCEEDED`; 22 tests, 0 failures | `t130-ios-sim-tests.log` |
| VC-EXEC-02 | Golden profiles produce unique signatures and passing quality reports | same invocation | passed | `t130-ios-sim-tests.log` |
| VC-EXEC-03 | Quality gate rejects scribble-like output | same invocation | passed | `t130-ios-sim-tests.log` |
| VC-EXEC-04 | Collision resolution advances the candidate deterministically | same invocation | passed | `t130-ios-sim-tests.log` |
| VC-EXEC-05 | Flare presentation does not mutate canonical identity or vector data | same invocation | passed | `t130-ios-sim-tests.log` |
| VC-EXEC-06 | Artifact validation passes; fails closed on digest mismatch | same invocation | passed | `t130-ios-sim-tests.log` |
| VC-EXEC-07 | Aeostara health decision fails closed for invalid artifacts | same invocation | passed | `t130-ios-sim-tests.log` |
| VC-EXEC-08 | Runtime assembly: 8 modules, Forsetti 0.1.4 at pin `43eef7a` | same invocation | passed | `t130-ios-sim-tests.log` |
| VC-EXEC-09 | Privacy posture local-only; capability policy excludes network/telemetry | same invocation | passed | `t130-ios-sim-tests.log` |
| VC-EXEC-10 | Repository guardrails: strict validator, version guard, attribution guard, 17 guard unit tests, `git diff --check`, wrapper | `python3 tools/sigil_guardrails/verify_sigil_guardrails.py --strict ...; python3 scripts/version_guard.py ...; python3 scripts/attribution_guard.py --branch main ...; python3 -m unittest Tests/...Guard...; bash scripts/verify-sigil-guardrails.sh` | all exit 0; wrapper ran strict guard + 22/22 Swift package tests | `t130-repo-guards.log`, `t130-guard-unittests.log`, `t130-wrapper.log` |
| VC-EXEC-11 | Debug iOS simulator build | `xcodebuild ... -destination 'generic/platform=iOS Simulator' build` (fresh DerivedData) | `BUILD SUCCEEDED`; 0 errors; 0 project-code warnings; 12 `appintentsmetadataprocessor` toolchain notices recorded as non-project | `t130-ios-build.log` |
| VC-EXEC-12 | Instruction-package integrity and helper tests | `python3 tools/check_package.py; python3 -m unittest discover -s tests -v` (package directory) | package check passed (39 hashed payload files); 20 helper tests OK | `t130-package-checks.log` |

Notes on the executed native runs:

- The first simulator test invocation (2026-11-02) was interrupted by a host tool timeout after the build phase completed and during the first boot of the iOS 27.0 simulator runtime; the partial result bundle is preserved in the evidence root and is not used as evidence. The recorded pass is the clean third invocation, which completed with a fresh result bundle.
- The 12 build-log warning lines are all `appintentsmetadataprocessor` metadata-phase notices (no AppIntents.framework dependency); none is a project-code warning.
- Historical results from earlier publications are not relabeled as fresh; every result above was re-executed at `53ba489` on 2026-11-02.

## Proposed cases (post-implementation conformance) — none executed

| Case | Expected result (kind) | Source of expectation | Execution status and reason |
| --- | --- | --- | --- |
| VC-PROP-01 | Dominant plane = plane whose numerology values contain the life path (1977-11-04 -> 3) (value) | celestial generator; nine-planes | proposed — product derives dominance from digest bytes |
| VC-PROP-02 | Wolf balance follows the canonical modifier equation and thresholds; non-moral interpretation (invariant) | celestial generator; master-mythic-mapping | proposed — product derives wolf balance from digest bytes |
| VC-PROP-03 | Weekday archetype (Friday for 1977-11-04) represented with provenance (value) | celestial generator weekday table | proposed — weekday absent from the input type |
| VC-PROP-04 | 9-bit ASH state with integrity per the adopted formalization; decoder status against the closed code (invariant) | ASH-Model spec + codewords; APS state-space spec | proposed — formalization unresolved (F-01) and no canonical profile mapping exists (F-02) |
| VC-PROP-05 | Orbit of 16 states; coordinate 8 constant; no invented codewords (invariant) | ASH-Model spec section 6 + codewords; APS codeword-set spec | proposed — product computes no orbit |
| VC-PROP-06 | Depth-4 branch topology: 81 leaves / 121 nodes, all 16 messages, node state = x xor enc(m), L-system geometry (invariant) | ASH-Model branch topology + spec section 9 | proposed — product uses fixed anchors and hash-parameterized paths |
| VC-PROP-07 | Master-number policy (unresolved expectation) | none — missing source decision (F-05) | proposed — an unresolved expectation cannot pass |
| VC-PROP-08 | Every retained plan input has an explicit, cited, deterministic treatment (invariant) | project plan input model | not_run — weekday, parents' birth order, and ancestral surnames absent; time/location/birth order digest-only |
| VC-PROP-09 | No payload encoder/decoder/sidecar/scan-to-record anywhere (invariant) | no-embedding decision; project plan | not_run — no named regression test exists; the investigation verified the boundary by full source read at `53ba489` |

Proposed cases define expected results with their sources; they are planning oracles, not passing conformance tests. They become runnable only under a separately authorized implementation assignment that first records the owner decisions named in [findings-and-next-change.md](findings-and-next-change.md).
