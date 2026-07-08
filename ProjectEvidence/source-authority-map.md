# Source Authority Map

## ASH Pattern System

- Scope: ASH Pattern semantic behavior, conformance, diagnostics, rule identifiers, codeword/state/recovery/topology semantics, and Apple-native package expectations.
- Files consulted for this guardrail pass:
  - `evidence/phase1/source-authority-evidence.md`
  - `evidence/phase1/build-test-evidence.md`
  - `tools/sigil_guardrails/sigil_guardrail_policy.json`
  - `sigil_project_guardrail_instruction_package/IMPLEMENTATION_INSTRUCTION_PACKAGE.md`
- Sigil implementation areas affected:
  - Guardrail policy for future ASH Pattern implementation surfaces.
  - Source/test scans for superseded ASH implementation markers.
  - Diagnostic and codeword verifier hooks for future source expansion.

## Aeostara

- Scope: Aeostara product usage, platform branch isolation, baseline provenance, and platform-specific realization boundaries.
- Files consulted for this guardrail pass:
  - `evidence/phase1/source-authority-evidence.md`
  - `evidence/phase1/build-test-evidence.md`
  - `tools/sigil_guardrails/sigil_guardrail_policy.json`
  - `sigil_project_guardrail_instruction_package/IMPLEMENTATION_INSTRUCTION_PACKAGE.md`
- Sigil implementation areas affected:
  - Platform-boundary evidence.
  - Baseline-pinned Aeostara integration status.
  - Guardrail policy preventing product-boundary collapse.

## Forsetti

- Scope: Runtime framework integration, module boundaries, public API usage, Apple-native implementation policy, and architecture guardrails.
- Files consulted for this guardrail pass:
  - `Package.swift`
  - `project.yml`
  - `Sources/RFSigilForsettiModules/SigilModuleCatalog.swift`
  - `Sources/RFSigilRuntime/SigilRuntimeAssembly.swift`
  - `evidence/phase1/source-authority-evidence.md`
  - `tools/sigil_guardrails/sigil_guardrail_policy.json`
- Sigil implementation areas affected:
  - Sealed package dependency enforcement.
  - Public Forsetti module registration boundaries.
  - Guardrail scan for copied Forsetti internal source trees.

## Boundary Notes

- Confirmed separate products: ASH Pattern System for Mac/iOS, Aeostara Mac/iOS, and Forsetti Framework for Mac/iOS remain separate source authorities.
- Confirmed ASH Pattern System is not the ASH Model: ASH Pattern System governs ASH Pattern implementation behavior for Sigil; ASH Model is not used as a direct Sigil implementation specification.
- Current limitation: the three named source authority archives were not present in this project folder during this guardrail pass. The guardrails were implemented against the current repository evidence and the supplied guardrail instruction package.
