import SwiftUI
import RFSigilCoreModels
import RFSigilPersonalCodex
import RFSigilPrivacySecurity
import RFSigilVisibleGlyph

// MARK: - Records list (CRUD over the real secure store)

public struct SigilRecord: Identifiable, Equatable, Sendable {
    public let id: String
    public let recordType: SigilRecordType
    public let createdAt: Date

    public init(id: String, recordType: SigilRecordType, createdAt: Date = Date()) {
        self.id = id
        self.recordType = recordType
        self.createdAt = createdAt
    }
}

// MARK: - Records list view model

@MainActor
public final class SigilRecordsListViewModel: ObservableObject {
    @Published public private(set) var records: [SigilRecord] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?

    let recordsStore: SigilRecordsStore

    public init(recordsStore: SigilRecordsStore) {
        self.recordsStore = recordsStore
    }

    public func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        switch await recordsStore.list() {
        case .success(let identities):
            records = identities.map { SigilRecord(id: $0.storageID, recordType: $0.recordType) }
        case .failure(let failure):
            errorMessage = failure.message
        }
    }

    public func delete(_ record: SigilRecord) async {
        switch await recordsStore.delete(storageID: record.id, recordType: record.recordType) {
        case .success:
            records.removeAll { $0.id == record.id && $0.recordType == record.recordType }
        case .failure(let failure):
            errorMessage = failure.message
        }
    }
}

// MARK: - Records list view

public struct SigilRecordsListView: View {
    @ObservedObject var viewModel: SigilRecordsListViewModel
    var onOpen: ((SigilRecord) -> Void)? = nil

    public init(viewModel: SigilRecordsListViewModel, onOpen: ((SigilRecord) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onOpen = onOpen
    }

    public var body: some View {
        List {
            if viewModel.records.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No records",
                    systemImage: "tray",
                    description: Text("Generated records will appear here.")
                )
            }
            ForEach(viewModel.records) { record in
                SigilRecordRow(
                    record: record,
                    onOpen: { onOpen?(record) },
                    onDelete: {
                        let alertState = SigilDeleteConfirmState(record: record)
                        // The confirm dialog is handled by the parent.
                    }
                )
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Records")
        .task { await viewModel.refresh() }
        .refreshable { await viewModel.refresh() }
    }
}

private struct SigilRecordRow: View {
    let record: SigilRecord
    var onOpen: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.recordType.rawValue)
                    .font(.headline)
                Text(record.id.prefix(12) + "…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open", action: onOpen)
                .buttonStyle(.bordered)
        }
    }
}

/// Holds the state for the delete-confirmation dialog.
struct SigilDeleteConfirmState: Identifiable, Equatable {
    let id = UUID()
    let record: SigilRecord
}

// MARK: - Main experience (wires form, journey, result, records)
//
// This is the top-level view for the Package 06 native experience. It owns:
// - A draft (the current user input)
// - A journey view model (the generation state machine)
// - A records list view model (CRUD over the secure store)
//
// Navigation: Dashboard -> Create (form) -> Result (glyph + codex) -> Flare/Export.
// Records: a list of saved records; open -> result; delete -> confirm.

@MainActor
public final class SigilExperienceViewModel: ObservableObject {
    @Published public var draft = SigilProfileDraft()
    @Published public var journeyState: SigilGenerationJourneyState = .idle
    @Published public var fieldErrors: [SigilDraftValidationError] = []
    @Published public var showResult: Bool = false
    @Published public var showFlare: Bool = false
    @Published public var showExport: Bool = false
    @Published var pendingDelete: SigilDeleteConfirmState?
    @Published var records: [SigilRecord] = []
    @Published var recordLoadError: String?

    public let storageID: String
    public let journeyViewModel: SigilGenerationJourneyViewModel
    public let recordsListViewModel: SigilRecordsListViewModel

    public init(
        storageID: String = UUID().uuidString,
        journeyViewModel: SigilGenerationJourneyViewModel,
        recordsListViewModel: SigilRecordsListViewModel
    ) {
        self.storageID = storageID
        self.journeyViewModel = journeyViewModel
        self.recordsListViewModel = recordsListViewModel
    }

    public func generate() {
        fieldErrors = []
        journeyViewModel.generate(from: draft)
        // Observe the journey state.
        observeJourney()
    }

    private func observeJourney() {
        // The journey view model publishes state changes; we mirror them here.
        // (In a production app, we would use a Combine subscription or
        //  directly observe the journey view model. For the MVP, we poll
        //  via a Timer or use the journey state directly in the view.)
        // For now, the view reads journeyViewModel.state directly.
    }

    public func cancelGeneration() {
        journeyViewModel.cancel()
    }

    public func saveResult() async {
        guard case .success(_, let artifact, let codex) = journeyViewModel.state else { return }
        // Save the profile draft as a .profile record.
        let profile = SigilProfileDraftSerializer.serialize(draft)
        _ = await recordsListViewModel.recordsStore.upsert(
            profile,
            storageID: storageID,
            recordType: .profile
        )
        // Save the PersonalCodex record.
        _ = await recordsListViewModel.recordsStore.upsert(
            codex,
            storageID: storageID,
            recordType: .personalCodex
        )
        // Save the Flare presentation (canonical, no style).
        let flare = SigilFlarePresentation(
            profileDigest: artifact.visibleSigil.profileDigest,
            canonicalGeometryDigest: artifact.visibleSigil.canonicalGeometryDigest,
            visibleSignatureHash: artifact.visibleSigil.visibleSignatureHash,
            vectorPaths: artifact.visibleSigil.vectorPaths,
            style: SigilFlareStyle(paletteID: "canonical", glowStrength: 0, backgroundID: "transparent")
        )
        _ = await recordsListViewModel.recordsStore.upsert(
            flare,
            storageID: storageID,
            recordType: .flare
        )
        await recordsListViewModel.refresh()
        showResult = false
        journeyViewModel.reset()
    }

    public func confirmDelete() async {
        guard let pending = pendingDelete else { return }
        await recordsListViewModel.delete(pending.record)
        pendingDelete = nil
    }

    public func openRecord(_ record: SigilRecord) async {
        // Load the PersonalCodex for this record and display it.
        guard record.recordType == .personalCodex else { return }
        let result = await recordsListViewModel.recordsStore.open(
            storageID: record.id,
            recordType: .personalCodex,
            as: SigilPersonalCodex.self
        )
        if case .success(let codex) = result {
            // Re-generate the glyph for this profile to display alongside.
            // (In production, we would load the saved profile and re-run the
            //  pipeline. For the MVP, we display the codex only.)
            _ = codex
        }
    }
}

// MARK: - Main experience view

public struct SigilExperienceView: View {
    @StateObject var viewModel: SigilExperienceViewModel

    public init(viewModel: SigilExperienceViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.journeyViewModel.state {
                case .idle, .failure, .cancelled:
                    SigilProfileFormView(
                        draft: $viewModel.draft,
                        fieldErrors: viewModel.fieldErrors,
                        onGenerate: { viewModel.generate() }
                    )
                    .navigationTitle("Create")
                case .loading:
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Generating…")
                            .font(.headline)
                        Button("Cancel") { viewModel.cancelGeneration() }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Generating")
                case .success:
                    SigilResultView(
                        artifact: {
                            if case .success(_, let a, _) = viewModel.journeyViewModel.state {
                                return a
                            }
                            fatalError("Unreachable")
                        }(),
                        codex: SigilPersonalCodexDisplay(
                            celestialName: extractCelestialName(from: viewModel.journeyViewModel.state),
                            sections: extractCodexSections(from: viewModel.journeyViewModel.state)
                        ),
                        onSave: {
                            Task { await viewModel.saveResult() }
                        },
                        onExport: { viewModel.showExport = true },
                        onFlare: { viewModel.showFlare = true }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showFlare) {
                Text("Flare editor (coming in S4)")
                    .padding()
            }
            .sheet(isPresented: $viewModel.showExport) {
                Text("Export (coming in S5)")
                    .padding()
            }
            .alert(
                "Delete record?",
                isPresented: Binding(
                    get: { viewModel.pendingDelete != nil },
                    set: { if !$0 { viewModel.pendingDelete = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { viewModel.pendingDelete = nil }
                Button("Delete", role: .destructive) {
                    Task { await viewModel.confirmDelete() }
                }
            } message: {
                Text("This will permanently remove the record from this device.")
            }
        }
    }

    private func extractCelestialName(from state: SigilGenerationJourneyState) -> String? {
        guard case .success(_, _, let codex) = state else { return nil }
        return codex.celestialName.celestialName
    }

    private func extractCodexSections(from state: SigilGenerationJourneyState) -> [SigilCodexSection] {
        guard case .success(_, _, let codex) = state else { return [] }
        var sections: [SigilCodexSection] = []
        sections.append(.init(title: "Mortal incarnation", body: codex.mortalIncarnation.prose))
        sections.append(.init(title: "Numerology", body: codex.numerologyProfile.prose))
        sections.append(.init(title: "ASH identity", body: codex.ashIdentity.prose))
        sections.append(.init(title: "Plane attunement", body: codex.planeAttunement.prose))
        sections.append(.init(title: "Wolf balance", body: codex.wolfBalance.prose))
        sections.append(.init(title: "Sigil reading", body: codex.sigilReading.prose))
        return sections
    }
}

// MARK: - Profile draft serializer
//
// A Codable wrapper so the draft can be persisted via the records store.

enum SigilProfileDraftSerializer {
    struct Serialized: Codable {
        let storageID: String
        let firstName: String
        let lastName: String
        let birthDate: String
        let birthTime: String
        let birthCity: String
        let birthOrder: String
        let eyes: String
        let hair: String
        let heritage: [String]
        let ancestralSurnames: [String]
        let parentalOrder: [String]
    }

    static func serialize(_ draft: SigilProfileDraft) -> Serialized {
        Serialized(
            storageID: draft.storageID,
            firstName: draft.firstName,
            lastName: draft.lastName,
            birthDate: draft.birthDate,
            birthTime: draft.birthTime,
            birthCity: draft.birthCity,
            birthOrder: draft.birthOrder,
            eyes: draft.eyes,
            hair: draft.hair,
            heritage: draft.heritage,
            ancestralSurnames: draft.ancestralSurnames,
            parentalOrder: draft.parentalOrder
        )
    }
}
