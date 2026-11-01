# Version Policy

Sigil uses the repository version format `STAGE.major.feature.patch`.

Stages:

- `PA`: pre-alpha
- `A`: alpha
- `R`: release

The current stage is `PA`.

Version increments:

- Major version: increments the second segment and resets feature and patch to zero.
- Feature update or release: increments the third segment and resets patch to zero.
- Patch or hotfix: increments the fourth segment.

`VERSION` is the repository source of truth. The SigilApp marketing version (`MARKETING_VERSION`) and `CFBundleShortVersionString` track the repository `VERSION`; `CFBundleVersion` and `CURRENT_PROJECT_VERSION` remain the platform build number. Remaining Apple bundle version fields stay platform build metadata unless release packaging policy changes.

Every material repository change must update `CHANGELOG.md`. Each released version must have a changelog heading matching the value in `VERSION`.
