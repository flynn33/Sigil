import Foundation
import RFCoreModels
import RFMeaning
import RFSigilPipeline
import RFStorage

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var profiles: [StoredProfileSummary] = []
    @Published var selectedProfile: PersonProfile?
    @Published var studioPresets: [StoredStudioPresetSummary] = []
    @Published var activeSigil: SigilResult?
    @Published var activeSigilUsesExtensions = false
    @Published var activeMeaning: MeaningNarrative?
    @Published var errorMessage: String? {
        didSet {
            guard let errorMessage, errorMessage != oldValue else { return }
            dependencies.diagnostics.record(errorMessage, level: .error, category: "ui")
        }
    }
    @Published var isAppLocked = false
    @Published var isAppUnlockInProgress = false

    let dependencies: AppDependencies
    private var hasBootstrappedDiagnostics = false

    init(dependencies: AppDependencies = .makeDefault()) {
        self.dependencies = dependencies
    }

    func bootstrapDiagnosticsIfNeeded() {
        guard !hasBootstrappedDiagnostics else { return }
        hasBootstrappedDiagnostics = true
        dependencies.diagnostics.installCrashLoggingIfNeeded()
        dependencies.diagnostics.recordAppLaunch()
    }

    func prepareDiagnosticsArchive() throws -> URL {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = (info["CFBundleShortVersionString"] as? String) ?? "unknown"
        let build = (info["CFBundleVersion"] as? String) ?? "unknown"
        let metadata = AppDiagnostics.ExportMetadata(
            generatedAt: Date(),
            appVersion: version,
            buildNumber: build,
            engineDataVersion: RFConstants.engineDataVersion,
            pipelineVersion: RFConstants.pipelineVersion,
            geometrySchemaVersion: RFConstants.geometrySchemaVersion,
            lockEnabled: dependencies.lockStore.isBiometricLockEnabled,
            profileCount: profiles.count,
            selectedProfileID: selectedProfile?.id.uuidString,
            activeSigilName: activeSigil?.celestialName
        )
        return try dependencies.diagnostics.createExportArchive(metadata: metadata)
    }

    func loadProfiles() async {
        do {
            profiles = try await dependencies.profileRepository.listProfiles()
        } catch {
            errorMessage = "Failed to load profiles: \(error.localizedDescription)"
        }
    }

    func createOrUpdateProfile(_ profile: PersonProfile) async {
        do {
            try await dependencies.profileRepository.upsert(profile)
            selectedProfile = profile
            await loadProfiles()
            await loadStudioPresets()
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
    }

    func openProfile(_ summary: StoredProfileSummary) async {
        do {
            selectedProfile = try await dependencies.profileRepository.loadProfile(id: summary.id)
            await loadStudioPresets()
        } catch {
            errorMessage = "Failed to open profile: \(error.localizedDescription)"
        }
    }

    func deleteProfile(_ summary: StoredProfileSummary) async {
        do {
            try await dependencies.profileRepository.deleteProfile(id: summary.id)
            if selectedProfile?.id == summary.id {
                selectedProfile = nil
                studioPresets = []
                activeSigil = nil
                activeSigilUsesExtensions = false
                activeMeaning = nil
            }
            await loadProfiles()
        } catch {
            errorMessage = "Failed to delete profile: \(error.localizedDescription)"
        }
    }

    func generateSigil(options: SigilOptions = SigilOptions()) async {
        guard let selectedProfile else {
            errorMessage = "Select a profile first."
            return
        }

        do {
            let pipeline = dependencies.sigilPipeline
            let engineData = dependencies.engineData
            let meaningService = dependencies.meaningService

            dependencies.diagnostics.record(
                "Starting sigil generation for profile \(selectedProfile.id.uuidString).",
                level: .info,
                category: "sigil"
            )

            let outcome = try await Task.detached(priority: .userInitiated) {
                let result = try pipeline.generate(profile: selectedProfile, options: options)
                let loreData = try engineData.loadLoreDataset()
                let meaning = meaningService.composeMeaning(from: result, loreData: loreData)
                return (result, meaning)
            }.value

            activeSigil = outcome.0
            activeSigilUsesExtensions = options.includeTraitExtensions
            activeMeaning = outcome.1
            dependencies.diagnostics.record(
                "Completed sigil generation for profile \(selectedProfile.id.uuidString).",
                level: .info,
                category: "sigil"
            )
        } catch {
            errorMessage = "Failed to generate sigil: \(error.localizedDescription)"
        }
    }

    func loadStudioPresets() async {
        guard let profileID = selectedProfile?.id else {
            studioPresets = []
            return
        }

        do {
            studioPresets = try await dependencies.profileRepository.listStudioPresets(profileID: profileID)
        } catch {
            errorMessage = "Failed to load studio presets: \(error.localizedDescription)"
        }
    }

    func saveStudioPreset(
        name: String,
        layers: [DecorLayer],
        existingPresetID: UUID?,
        isFavorite: Bool? = nil
    ) async -> UUID? {
        guard let profileID = selectedProfile?.id else {
            errorMessage = "Select a profile first."
            return nil
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Preset name is required."
            return nil
        }

        do {
            let now = Date()
            let preservedCreatedAt: Date
            let preservedFavorite: Bool
            if let existingPresetID,
               let existing = try await dependencies.profileRepository.loadStudioPreset(id: existingPresetID) {
                preservedCreatedAt = existing.createdAt
                preservedFavorite = existing.isFavorite
            } else {
                preservedCreatedAt = now
                preservedFavorite = false
            }

            let preset = StudioLayerPreset(
                id: existingPresetID ?? UUID(),
                profileID: profileID,
                name: trimmed,
                isFavorite: isFavorite ?? preservedFavorite,
                layers: layers,
                createdAt: preservedCreatedAt,
                updatedAt: now
            )

            try await dependencies.profileRepository.upsertStudioPreset(preset)
            await loadStudioPresets()
            return preset.id
        } catch {
            errorMessage = "Failed to save studio preset: \(error.localizedDescription)"
            return nil
        }
    }

    func renameStudioPreset(id: UUID, newName: String) async -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Preset name is required."
            return false
        }

        guard let existing = await loadStudioPreset(id: id) else {
            return false
        }

        let saved = await saveStudioPreset(
            name: trimmed,
            layers: existing.layers,
            existingPresetID: id,
            isFavorite: existing.isFavorite
        )
        return saved != nil
    }

    func duplicateStudioPreset(id: UUID, newName: String) async -> UUID? {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Preset name is required."
            return nil
        }

        guard let existing = await loadStudioPreset(id: id) else {
            return nil
        }

        return await saveStudioPreset(
            name: trimmed,
            layers: existing.layers,
            existingPresetID: nil,
            isFavorite: false
        )
    }

    func toggleStudioPresetFavorite(id: UUID) async {
        guard let existing = await loadStudioPreset(id: id) else {
            return
        }

        _ = await saveStudioPreset(
            name: existing.name,
            layers: existing.layers,
            existingPresetID: id,
            isFavorite: !existing.isFavorite
        )
    }

    func loadStudioPreset(id: UUID) async -> StudioLayerPreset? {
        do {
            return try await dependencies.profileRepository.loadStudioPreset(id: id)
        } catch {
            errorMessage = "Failed to load studio preset: \(error.localizedDescription)"
            return nil
        }
    }

    func deleteStudioPreset(id: UUID) async {
        do {
            try await dependencies.profileRepository.deleteStudioPreset(id: id)
            await loadStudioPresets()
        } catch {
            errorMessage = "Failed to delete studio preset: \(error.localizedDescription)"
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func initializeAppLockState() {
        isAppLocked = dependencies.lockStore.isBiometricLockEnabled
    }

    func setBiometricLockEnabled(_ enabled: Bool) {
        dependencies.lockStore.setBiometricLockEnabled(enabled)
        if !enabled {
            isAppLocked = false
            return
        }
        isAppLocked = true
    }

    func lockAppForBackground() {
        if dependencies.lockStore.isBiometricLockEnabled {
            isAppLocked = true
        }
    }

    func handleAppBecameActive() {
        if !dependencies.lockStore.isBiometricLockEnabled {
            isAppLocked = false
        }
    }

    func unlockApp() async {
        guard dependencies.lockStore.isBiometricLockEnabled else {
            isAppLocked = false
            return
        }

        guard !isAppUnlockInProgress else {
            return
        }

        isAppUnlockInProgress = true
        defer { isAppUnlockInProgress = false }

        let success = await dependencies.appLockAuthenticator.authenticate(reason: "Unlock Sigil")
        if success {
            isAppLocked = false
        } else {
            isAppLocked = true
            errorMessage = "Authentication failed. Unlock is required to continue."
        }
    }
}
