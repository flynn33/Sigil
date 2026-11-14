# Sigil UI information architecture

## Summary

The native app chrome is organized for end users per Apple Human Interface Guidelines: peer destinations in a tab bar, Create as a multi-step task, and infrequent options under Settings.

## Top-level tabs

| Tab | Role |
| --- | --- |
| **Home** | Content-first landing: brand, Create CTA, recent records |
| **Records** | Local encrypted record list; toolbar New opens Create |
| **Settings** | Privacy posture, System status (module dashboard), About |

## Create journey

Presented as a full-screen cover from Home or Records (not a tab). Flow: profile form → generating → result → optional Flare/Export sheets → Save dismisses and refreshes Records.

## Relocated surfaces

- Former **Dashboard** tab → Settings → **System status** (`SigilPhase1DashboardView`)
- **About** → Settings → About (version, privacy, license)

## Visual approach

Quiet ritual branding on Home and Result (glyph-forward, restrained atmosphere). Forms and Settings use standard SwiftUI `Form` / `List` materials.

## Primary files

- `Sources/RFSigilUIModule/SigilRootTabView.swift`
- `Sources/RFSigilUIModule/SigilHomeView.swift`
- `Sources/RFSigilUIModule/SigilSettingsView.swift`
- `Sources/RFSigilUIModule/SigilAboutView.swift`
- `Sources/SigilApp/SigilApp.swift`

## Version

Published with product version `PA.0.7.0` / Apple build `10`.
