# Secure Local Storage (Encrypted At Rest)

Product-owned design decisions for the real, local-only encrypted persistence
delivered in Package 03. This is the implementation that the Phase 1 privacy
posture previously only *modeled*. It is a design record, not a promise of
device-level data protection: OS keychain/data-protection behavior is an owner
qualification, not something a host unit test proves (see "Verification and
limits").

## Scope and non-goals

Sensitive Sigil records (profiles, identity records, the PersonalCodex, canonical
geometry, and Flare records) persist only through this protected, local route.
The record kinds are `SigilRecordType` (`.profile`, `.identity`,
`.personalCodex`, `.canonicalGeometry`, `.flare`); the PersonalCodex kind exists
as a storage identity and is not populated by Package 03 (that is Package 04).

Non-goals: there is no CloudKit, no sync service, no background upload, and no
network path. This storage does not reintroduce the removed personal-data
embedding requirement: it stores records the product already owns, encrypted,
on the device; it does not make the glyph a recoverable personal payload.

## Storage identity is separate from mathematical identity

A record's storage key is `SigilRecordIdentity` (an opaque, storage-scoped
`storageID` plus a `SigilRecordType`). A profile's `profileHash` or any other
mathematical identity is **not** used as a storage key. Keeping the two apart
means the on-disk identity never leaks the mathematical identity, and later
features (Package 04/05) can choose their own mathematical identity without
re-encrypting existing records.

## The record store

`SigilSecureRecordStore` is a serialized actor that owns transactional
save/load/delete under a single directory partition. Serialization gives the
store linearizable coordination (no torn concurrent writes) without external
locks.

Each record is a versioned `SigilSecureEnvelope`:

- `version` — envelope format version (currently `1`); an unsupported version
  fails closed on read.
- `keyID` — which key sealed it (see key management).
- `recordType`, `storageID` — the storage identity.
- `recordDigest` — a SHA-256 hex digest of the plaintext, used as an integrity
  marker on read. A hash, explicitly **not** the encryption.
- `ciphertext` — the AES-GCM *combined* buffer: nonce || ciphertext || tag.
- `createdAt`.

Crypto is Apple-native: CryptoKit `AES.GCM.seal(_:using:)` produces a fresh
random nonce and returns a `SealedBox`; `SealedBox.combined` is the
nonce||ciphertext||tag bytes stored in the envelope. Read is the inverse:
`AES.GCM.SealedBox(combined:)` then `AES.GCM.open(_:using:)`. No custom
algorithm is invented and a hash is never substituted for encryption.

## Key management

`SigilEncryptionKeyProviding` abstracts key storage so the native logic is testable
independently of the OS keychain:

- `SigilKeychainKeyStore` (production): 256-bit AES-GCM keys in the platform
  keychain with the most restrictive local-only accessibility
  (`kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`).
- `SigilInMemoryKeyStore` (host tests / ephemeral): keys held in process memory
  behind a lock.

The load-bearing invariant: **keys are stored separately from ciphertext and
never beside it.** The envelope stores only `keyID` (an identifier), not the key.

## Atomic replacement and failure semantics

A save writes the serialized envelope to a temporary file in the same directory,
then swaps it into place with `FileManager.replaceItemAt(_:withItemAt:)`. Because
the swap is atomic and only runs after a complete, valid temp file exists:

- an interrupted or failed write never leaves a half-written record;
- the last-verified record is always preserved when a replacement fails;
- a key-creation failure, an unavailable key, a failed write, a decrypt failure,
  an unsupported envelope version, or a digest mismatch each surfaces as a typed
  `SigilSecureStorageError` (fail-closed). On read, a digest mismatch after a
  successful decrypt is treated as `corruptRecord`, never silently accepted.

There is no "regenerate a key and silently abandon old encrypted content" path:
a retrieval failure is a retrieval failure, surfaced to the caller.

## The runtime service

`SigilSecurePersistenceService` is the thin, truthful runtime facade over a
`SigilSecureRecordStore`:

- `save(_:id:)` returns a `SigilSaveOutcome { success, recordCount,
  failureCategory }`. A failed save is **never** reported as success: it returns
  `success == false` with a coarse `failureCategory`
  (`.keyUnavailable`, `.writeFailed`, `.notFound`, `.decryptionFailed`,
  `.corruptRecord`, `.unsupportedVersion`, `.unknown`) and leaves the record
  count unchanged.
- `load(_:id:)` rethrows the store's typed storage error (fail-closed).
- `readiness()` is pure (no I/O) so the dashboard can call it safely at
  assembly time; it drives the `secure-persistence` dashboard card.

Diagnostics are **redacted by construction**: the service hands the
`SigilDiagnosticCollector` only `recordType`, `failureCategory`, and
`recordCount` (plus operation name and outcome). It never records the record
payload, key material, the storage path, or the record identifier. This is
verified by `SecurePersistenceIntegrationTests` with a self-contained capturing
collector, independent of any production collector's own redaction.

## Local-only boundary

No network client, CloudKit container, sync service, or upload path is present
in this module. Temporary files are written only in the same partition directory
as the target record and are removed on write failure; there is no diagnostic
spill, exported copy, or backup of record ciphertext outside that directory.

## Verification and limits

Host tests (`SecureStorageTests`, 14) prove the native crypto, storage, and
atomic-replacement **logic** with an injected key: round-trip, no-plaintext-leak
in stored bytes, keys-not-beside-ciphertext, atomic update, failed replacement
preserves last-verified, wrong/missing key, tampered ciphertext, corrupt record,
unsupported version, not-found, list/delete, concurrent writes, and
storage-vs-math identity. `ArtifactHealthTests` (10) cover the companion
artifact-health validator; `SecurePersistenceIntegrationTests` (4) cover the
truthful runtime outcomes and redaction.

What a host unit test does **not** prove: the OS keychain's own access control
and data-protection behavior on a device or simulator. That is an owner
qualification and is recorded as such, not claimed by the host suite.

## Source references

- `Sources/RFSigilPrivacySecurity/SigilSecureRecordStore.swift`
- `Sources/RFSigilPrivacySecurity/SigilEncryptionKeyStore.swift`
- `Sources/RFSigilPrivacySecurity/SigilSecureStorageTypes.swift`
- `Sources/RFSigilPrivacySecurity/SigilSecurePersistenceService.swift`
- `Sources/RFSigilAeostaraIntegration/SigilArtifactHealthValidator.swift`
- `Tests/SigilTests/SecureStorageTests.swift`, `Tests/SigilTests/ArtifactHealthTests.swift`, `Tests/SigilTests/SecurePersistenceIntegrationTests.swift`
- Apple references: [CryptoKit](https://developer.apple.com/documentation/cryptokit), [Using the Keychain](https://developer.apple.com/documentation/security/using-the-keychain-to-manage-user-secrets), and the current Apple Platform Security keychain/data-protection guidance.
