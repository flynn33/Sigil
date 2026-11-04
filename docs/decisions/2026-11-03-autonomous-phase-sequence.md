# Decision: Autonomous Development of the Remaining Sequence

**Decision ID:** `SIGIL-DEC-2026-11-03-AUTONOMOUS-SEQUENCE`
**Recorded date:** 2026-11-03
**Authority:** Flynn, project owner
**Status:** Decided; execution authorized for the remaining development sequence
**Related records:** `SIGIL-DEC-2026-10-09-ASH-TRACE` (completed 2026-11-02), `SIGIL-DEC-2026-10-10-NO-EMBEDDING`

## Exact owner decision (summary)

The owner authorizes the remaining development sequence for Sigil, delivered as the seven package work order supplied in the external instruction bundle (revision 1.0, 2026-11-02): 01 remediation and source alignment; 02 identity pipeline; 03 artifact health and local storage; 04 canon and PersonalCodex; 05 ASH-derived glyph; 06 native experience and export; 07 integration and owner handover.

Included in the authorization: necessary in-scope remediation, implementation, testing, debugging, documentation, and version alignment. The packages are guides; the hard development rules are the adopted Raven Forge Development policy (0.8.0 binding). Ordinary in-scope engineering problem solving is delegated; routine approval stops between phases are removed.

Publication per completed phase: commit locally and push the source and current buildable Xcode project to `flynn33/Sigil` as the owner (`flynn33`), without model or tool attribution. The owner's existing admin bypass may be used for the authorized integration where available and policy permits it. If GitHub is inaccessible or publication fails, keep the local commit, record the pending push, continue the next eligible work, and retry later without discarding or rewriting unrelated work.

## What this decision changes

This decision authorizes implementation of the remaining roadmap workstreams, which the earlier records describe as "separate, unstarted assignment(s)" gated on the ASH-TRACE owner decisions. That historical boundary is preserved as history: the completed trace itself never authorized implementation. This new decision is the authorization.

The four topics recorded in the ASH-TRACE findings (state formalization, profile-to-state mapping, master-number policy, input treatment rules) are to be resolved in the Package 01 planning pass as documented **product-owned design decisions**, labeled product policy rather than upstream mathematics, following the source-reconciliation direction of the remediation brief (coordinate convention, the 512-state universe versus the image/video integrity subset, and the separation of semantic topology from rendering grammar). Any genuine remaining upstream source conflict stays specific, visible, and isolated; it is not resolved by calling it a workaround and does not block independent eligible work.

## What this decision does not change

- The personal-data embedding requirement remains **removed, not deferred** (`SIGIL-DEC-2026-10-10-NO-EMBEDDING`). No mandatory hidden payload, metadata carrier, sidecar, encoder/decoder milestone, or embedded-record recovery gate may be reintroduced.
- Source authority, local-first privacy, no analytics or application backend, canonical/Flare separation, and deterministic generation remain in force.
- The development-policy binding stays Raven Forge Development 0.8.0. This decision does not adopt a new playbook revision, change repository protections or permissions, or alter upstream repositories, ASH canon, or account permissions.
- No new third-party runtime dependency is authorized by this decision; the observed dependency pins are preserved unless a separately justified change is actually within the approved record.
- Candidate/distribution builds, archives/installers, distribution signing, notarization, releases, deployment, shipping, and physical-device qualification remain the owner's work. Development builds and host/simulator checks are the coding agent's.
- No framework rewrite, macOS consumer milestone, new online service, automatic upload/sync, or unrelated security expansion is authorized.

## Effect on the records

The project plan's "Current execution boundary" and the roadmap's "currently approved next engineering investigation" language describe the bounded documentation/trace assignments of 2026-10-10 through 2026-11-02. They remain true for those historical assignments and are superseded as the current execution boundary by this decision, which is recorded here and linked from the project plan, roadmap, and ASH-TRACE handoff.

See the [current project plan](../project-plan.md), [roadmap](../roadmap.md), and [ASH-TRACE handoff](../handoffs/ash-trace.md).
