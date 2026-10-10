# Decision: Remove Personal-Data Embedding from Sigils

**Decision ID:** `SIGIL-DEC-2026-10-10-NO-EMBEDDING`
**Recorded date:** 2026-10-10
**Authority:** Flynn, project owner
**Status:** Decided; removed from requirements, not deferred
**Related approval:** `SIGIL-DEC-2026-10-09-ASH-TRACE`

## Exact owner decision

> I have decided we are going to remove embedding information into the Sigils as a requirement.  It's more important that Sigil uses the cosmological math, adding a layer of embedding data is too much.

The subsequent instruction requests comparison with the current repository, removal of personal-data embedding from the plan/roadmap, and a repository-update handoff. This entry is the repository-facing record of that requirement change; it does not claim an external Project Record was updated.

## Changed requirement

Sigil must derive its form from the governing ASH cosmological mathematics. An additional layer that encodes a user's personal input, identity record, PersonalCodex, or another recoverable payload into the Sigil is no longer required.

Remove added payload-carrier work, encoder/decoder work, scan-to-record obligations, payload-capacity work, and acceptance gates whose sole purpose is embedded-payload recovery. Do not defer them to a later release or reinstate them through mandatory metadata, hidden geometry, or a sidecar.

This changes requirements. It does not establish that those mechanisms exist in the current source or that code/tests have been deleted.

## Retained requirements

Personal input, the standard numerology bridge, ASH mathematics and cosmology, applicable canonical data and binary artifacts, APS resolution, Aeostara validation/containment/safe failure, WRW interpretation, PersonalCodex, deterministic generation, local security, and canonical/Flare separation remain in scope.

Keep internal mathematical state and geometry where needed for generation, validation, rendering, or reproducibility. Preserve reversible mathematical operations inherent in ASH. Keep valid local-artifact recovery, schema checks, digest integrity, and editing undo. None of those is automatically an added personal-payload encoder.

The decision does not select a replacement algorithm, storage/export format, uniqueness policy, dependency, or architecture. It does not guarantee that an input-derived Sigil cannot reveal information.

## Effect on the approved next engineering action

Continue the read-only trace from `SigilVisibleGlyphService.makeHiddenGeometry(for:)`, through its producers and consumers, to the governing ASH sources. Distinguish verified mathematical generation, temporary substitutions, unresolved evidence, and any embedding-only responsibilities actually found. Define the smallest supported implementation change and the remaining conformance/determinism/quality/privacy/safety tests. Embedded-record recovery is not a completion gate.

## Permissions and history

The earlier approval remains unchanged except for the superseded embedding/recovery requirement. Repository-documentation execution and publication permissions are recorded separately in the bounded handoff. This decision alone does not authorize arbitrary code deletion, framework changes, a new playbook revision, signing, distribution, or release.

Historical discussions describing a reversible personal-data carrier are superseded only on that point. The original decision IDs and dates are preserved; no old proposal becomes approved merely because it appears in a historical note.

See the [current project plan](../project-plan.md) and [roadmap](../roadmap.md).
