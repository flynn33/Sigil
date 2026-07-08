# Visible Glyph Source Reading Evidence

## Source Package

- Visible-glyph instruction package v2 was read in full from the local working package folder.
- Files read: 37 regular files.
- JSON files parsed: 24.
- JSON parse errors: 0.
- Golden fixture count: 4.

## Requirements Locked

- Preserve hidden canonical geometry separately from visible vector output.
- Link hidden and visible artifacts by stable digests.
- Use canonical JSON with sorted keys for digestable payloads.
- Generate deterministic visible vector paths without raw point plotting or unbounded random traces.
- Keep visible segment count within 10...14 before renderer expansion.
- Keep major crossings at 3 or fewer.
- Produce distinct visible signatures and path signatures for the four golden profiles.
- Keep presentation styling separate from canonical identity and vector paths.
- Fail closed on digest or quality mismatch.
- Keep all processing local; add no network, analytics, backend upload, or remote logging path.
- Commit locally only and hold for explicit PR authorization.
