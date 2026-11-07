# Package 06 — Native experience, presentation-only Flare and explicit export

## Summary

Package 06 delivers the full native iOS workflow that connects validated input,
real identity/PersonalCodex/glyph generation, protected local records,
presentation-only Flare, and user-controlled sharing. The prior minimal
dashboard (a grid of status cards) is now complemented by a three-tab
experience: **Dashboard** (the existing status surface), **Create** (the new
input → generate → result journey), and **Records** (CRUD over the real
secure store).

This package does not change the canonical math, canon, or health contracts.
It builds the native UI *on top of* the real services delivered in Packages
02–05: `SigilVisibleGlyphService` (the ASH-derived glyph),
`SigilPersonalCodexService` (the readable interpretation + celestial name),
and `SigilSecurePersistenceService` (AES-GCM encrypted-at-rest local records).

## What was delivered

### 1. Profile draft and domain-boundary promotion (S1)

A `SigilProfileDraft` is the UI-facing record of *what the user has typed so
far*. It is deliberately distinct from the canonical `SigilProfileInput`: a
draft may be incomplete, inconsistent, or contain placeholder values. The
`SigilDraftPromoter` is the single point where a draft becomes a canonical
input. Required fields are name, birth date, and birth city; all other fields
are optional and **unknown is a legitimate state** (the ASH pipeline fails
closed on its own identity-core fields). Validation reports *all* field errors
at once (not fail-fast), so the user can fix them in one pass.

### 2. Generation journey (S1)

`SigilGenerationJourneyState` is a five-state machine: `idle`, `loading`,
`success`, `failure`, `cancelled`. Each state carries a `requestSequence` — a
monotonically-increasing counter that is the **out-of-order completion guard**.
Only an event whose sequence matches the state machine's expected sequence can
change the terminal state; older completions are dropped. A new generation
started while the old one is in flight supersedes it.

`SigilGenerationJourneyViewModel` is a `@MainActor ObservableObject` that owns
the state machine, an in-flight `Task`, and the sequence. The pipeline (glyph +
PersonalCodex) runs on detached tasks off the main actor; the main actor only
receives the final event.

### 3. Profile form and result view (S2)

`SigilProfileFormView` is a SwiftUI Form that binds to the draft with
field-level error display. All retained inputs are present: identity, birth
(date/time/city/order), appearance (eyes/hair), heritage groups, ancestral
surnames, and parental birth order.

`SigilResultView` displays the canonical glyph (rendered from SVG via
`Canvas`), the celestial name, a concise provenance summary, readable
PersonalCodex sections, and an advanced disclosure for raw geometry. Action
buttons for Save, Flare, and Export.

### 4. Records CRUD (S3)

`SigilRecordsStore` is an `actor` that wraps the real
`SigilSecurePersistenceService` with `upsert`/`open`/`delete`/`list` over
arbitrary `Codable` payloads keyed by `(storageID, recordType)`. Failures carry
a `SigilPersistenceFailureCategory` the UI maps to user-facing messages. The
records list view shows saved records, supports delete with a confirmation
dialog, and refreshes on pull-to-refresh.

The app constructs the **real** services (not placeholders): the
`SigilPersonalCodexService` with the canon loader, and the
`SigilSecurePersistenceService` with a `SigilKeychainKeyStore` and a records
directory under Application Support.

### 5. Flare presentation editor (S4)

Flare is **presentation-only**: it never modifies the canonical identity,
vector paths, or digests. The editor offers a small, fixed set of approved
palettes (canonical, aurora, ember, frost, midnight) and backgrounds
(transparent, light, dark), plus a glow slider. The editor shows a
side-by-side canonical-vs-styled preview. "Return to canonical" resets the
style; "Save" commits the style to the records store. The canonical data is
preserved throughout (verified by tests).

### 6. User-selected export/share (S5)

Five bounded export formats, each a distinct artifact the user explicitly
selects:

| Option | Format | Content |
| --- | --- | --- |
| Canonical glyph | SVG | The canonical `svgDocument` (no style). |
| Styled glyph | SVG | The Flare-styled SVG (palette + glow + background). |
| PersonalCodex | JSON | The full, deterministic record with all sections + provenance. |
| PersonalCodex | Markdown | A readable report of the sections. |
| Diagnostics | JSON | Redacted: record type, outcome, schema, digest. No personal data. |

The export writes to a temp file atomically and presents a native `ShareLink`.
The temp file is cleaned up when the user dismisses the sheet. There is no
automatic attachment of diagnostics or profile data; the user chooses exactly
what is included.

### 7. Integration tests (S6)

`JourneyIntegrationTests` exercises the real service integration (not mocks)
through the full create → generate → read record → save → reopen → Flare →
export journey with a synthetic fixture. Covers: save/reopen round-trip
integrity (digest stability), the Flare presentation-only guarantee
(canonical data unchanged across 3 styles), out-of-order completion drop,
empty-draft validation, and 10 concurrent writes serialized by the records
store actor.

## Boundaries preserved

- **No personal-data embedding** (removed in Package 05; unchanged here).
- **Canonical / Flare separation**: Flare edits never touch the canonical
  identity, vector, or digest (tested).
- **No new third-party runtime deps**: only SwiftUI, Foundation, CryptoKit,
  and UniformTypeIdentifiers (system frameworks).
- **No analytics / backend / upload**: all records are local-only,
  encrypted-at-rest. Export is a user-selected, local temp file handed to the
  native share sheet.
- **No redesign**: the existing dashboard is preserved as a tab; the new
  experience is additive.

## Files added / changed

- `Sources/RFSigilUIModule/SigilProfileDraft.swift` — draft, promoter, journey
  state machine, journey view model, records store.
- `Sources/RFSigilUIModule/SigilProfileFormView.swift` — form + result view +
  SVG glyph view.
- `Sources/RFSigilUIModule/SigilExperienceView.swift` — experience view model
  + main experience view + records list.
- `Sources/RFSigilUIModule/SigilFlareEditorView.swift` — Flare palettes,
  editor state/view model/view, Flare glyph view.
- `Sources/RFSigilUIModule/SigilExportView.swift` — export options, view model,
  export view.
- `Sources/SigilApp/SigilApp.swift` — TabView wiring, real service
  construction.
- `Sources/RFSigilPrivacySecurity/SigilSecurePersistenceService.swift` — added
  async `delete` and `list`.
- `Package.swift` — RFSigilUIModule now depends on RFSigilVisibleGlyph,
  RFSigilPrivacySecurity, RFSigilPersonalCodex.
- `Tests/SigilTests/ProfileDraftAndJourneyTests.swift` — 20 unit tests.
- `Tests/SigilTests/JourneyIntegrationTests.swift` — 5 integration tests.

## Verification

- `swift build` clean.
- `swift test` 136/136 (up from 111 at the Package 05 baseline).
