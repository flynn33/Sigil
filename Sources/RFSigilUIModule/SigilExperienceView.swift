import SwiftUI
import RFSigilCoreModels
import RFSigilPersonalCodex
import RFSigilPrivacySecurity
import RFSigilVisibleGlyph

// MARK: - Records list (CRUD over the real secure store)

public struct SigilRecord: Identifiable, Equatable, Sendable {
    public let storageID: String
    public let recordType: SigilRecordType
    public let createdAt: Date

    /// Unique across record types that share a storage ID.
    public var id: String { "\(recordType.rawValue)::\(storageID)" }

    public init(storageID: String, recordType: SigilRecordType, createdAt: Date = Date()) {
        self.storageID = storageID
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
            records = identities.map { SigilRecord(storageID: $0.storageID, recordType: $0.recordType) }
        case .failure(let failure):
            errorMessage = failure.message
        }
    }

    public func delete(_ record: SigilRecord) async {
        switch await recordsStore.delete(storageID: record.storageID, recordType: record.recordType) {
        case .success:
            records.removeAll { $0.storageID == record.storageID && $0.recordType == record.recordType }
        case .failure(let failure):
            errorMessage = failure.message
        }
    }
}

// MARK: - Records list view

public struct SigilRecordsListView: View {
    @ObservedObject var viewModel: SigilRecordsListViewModel
    var onOpen: ((SigilRecord) -> Void)? = nil
    var onCreate: (() -> Void)? = nil
    @State private var pendingDelete: SigilDeleteConfirmState?

    public init(
        viewModel: SigilRecordsListViewModel,
        onOpen: ((SigilRecord) -> Void)? = nil,
        onCreate: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onOpen = onOpen
        self.onCreate = onCreate
    }

    public var body: some View {
        Group {
            if viewModel.records.isEmpty && !viewModel.isLoading {
                ContentUnavailableView {
                    Label("No records", systemImage: "tray")
                } description: {
                    Text("Saved Sigils appear here. Everything stays encrypted on this device.")
                } actions: {
                    if let onCreate {
                        Button("Create a Sigil", action: onCreate)
                            .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                List {
                    ForEach(viewModel.records) { record in
                        Button {
                            onOpen?(record)
                        } label: {
                            SigilRecordSummaryRow(record: record)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                pendingDelete = SigilDeleteConfirmState(record: record)
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Records")
        .toolbar {
            if let onCreate {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onCreate) {
                        Label("New", systemImage: "plus")
                    }
                }
            }
        }
        .task { await viewModel.refresh() }
        .refreshable { await viewModel.refresh() }
        .alert(
            "Delete record?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let pending = pendingDelete {
                    pendingDelete = nil
                    Task { await viewModel.delete(pending.record) }
                }
            }
        } message: {
            Text("This will permanently remove the record from this device.")
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
// Navigation: Dashboard -> Create (form) -> Result (glyph + record) -> Flare/Export.
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
    @Published var currentFlareStyle: SigilFlareStyle?

    public private(set) var storageID: String
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

    /// Resets draft and journey state for a new Create task presentation.
    public func beginNewCreation() {
        storageID = UUID().uuidString
        draft = SigilProfileDraft(storageID: storageID)
        fieldErrors = []
        showResult = false
        showFlare = false
        showExport = false
        currentFlareStyle = nil
        pendingDelete = nil
        journeyViewModel.reset()
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
        guard case .success(_, let artifact, let record) = journeyViewModel.state else { return }
        // Save the profile draft as a .profile record.
        let profile = SigilProfileDraftSerializer.serialize(draft)
        _ = await recordsListViewModel.recordsStore.upsert(
            profile,
            storageID: storageID,
            recordType: .profile
        )
        // Save the PersonalCodex record.
        _ = await recordsListViewModel.recordsStore.upsert(
            record,
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

    /// The dependencies needed to build the Flare editor. Returns nil when
    /// no successful artifact is available.
    var flareEditorDependencies: (VisibleCanonicalSigil, SigilVisibleGlyphService)? {
        guard case .success(_, let artifact, _) = journeyViewModel.state else { return nil }
        return (artifact.visibleSigil, journeyViewModel.glyphServiceRef)
    }

    public func saveFlare(_ presentation: SigilFlarePresentation) async {
        currentFlareStyle = presentation.style
        _ = await recordsListViewModel.recordsStore.upsert(
            presentation,
            storageID: storageID,
            recordType: .flare
        )
        await recordsListViewModel.refresh()
    }

    /// The dependencies needed to build the export view. Returns nil when
    /// no successful artifact is available.
    var exportDependencies: (SigilVisibleGlyphArtifact, SigilPersonalCodex, SigilVisibleGlyphService)? {
        guard case .success(_, let artifact, let record) = journeyViewModel.state else { return nil }
        return (artifact, record, journeyViewModel.glyphServiceRef)
    }

    public func openRecord(_ record: SigilRecord) async {
        // Load the PersonalCodex for this record and display it.
        guard record.recordType == .personalCodex else { return }
        let result = await recordsListViewModel.recordsStore.open(
            storageID: record.storageID,
            recordType: .personalCodex,
            as: SigilPersonalCodex.self
        )
        if case .success(let record) = result {
            // Re-generate the glyph for this profile to display alongside.
            // (In production, we would load the saved profile and re-run the
            //  pipeline. For the MVP, we display the record only.)
            _ = record
        }
    }
}

// MARK: - Main experience view

public struct SigilExperienceView: View {
    @ObservedObject var viewModel: SigilExperienceViewModel
    var onDismiss: (() -> Void)?

    public init(viewModel: SigilExperienceViewModel, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.journeyViewModel.state {
                case .idle, .cancelled:
                    SigilProfileFormView(
                        draft: $viewModel.draft,
                        fieldErrors: viewModel.fieldErrors,
                        onGenerate: { viewModel.generate() }
                    )
                    .navigationTitle("Create")
                case .failure(_, let reason):
                    SigilProfileFormView(
                        draft: $viewModel.draft,
                        fieldErrors: viewModel.fieldErrors,
                        onGenerate: { viewModel.generate() }
                    )
                    .safeAreaInset(edge: .top) {
                        Text(reason)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.red.opacity(0.08))
                    }
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
                        record: SigilPersonalRecordDisplay(
                            celestialName: extractCelestialName(from: viewModel.journeyViewModel.state),
                            sections: extractCodexSections(from: viewModel.journeyViewModel.state)
                        ),
                        onSave: {
                            Task {
                                await viewModel.saveResult()
                                onDismiss?()
                            }
                        },
                        onExport: { viewModel.showExport = true },
                        onFlare: { viewModel.showFlare = true }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.cancelGeneration()
                        viewModel.journeyViewModel.reset()
                        onDismiss?()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showFlare) {
                if let (sigil, glyphService) = viewModel.flareEditorDependencies {
                    NavigationStack {
                        SigilFlareEditorView(
                            viewModel: SigilFlareEditorViewModel(
                                visibleSigil: sigil,
                                glyphService: glyphService
                            ),
                            onSave: { presentation in
                                Task {
                                    await viewModel.saveFlare(presentation)
                                }
                            },
                            onDismiss: {
                                viewModel.showFlare = false
                            }
                        )
                    }
                }
            }
            .sheet(isPresented: $viewModel.showExport) {
                if let (artifact, record, glyphService) = viewModel.exportDependencies {
                    SigilExportView(
                        viewModel: SigilExportViewModel(
                            artifact: artifact,
                            record: record,
                            glyphService: glyphService,
                            flareStyle: viewModel.currentFlareStyle
                        ),
                        onDismiss: {
                            viewModel.showExport = false
                        }
                    )
                }
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
        guard case .success(_, _, let record) = state else { return nil }
        return record.celestialName.celestialName
    }

    private func extractCodexSections(from state: SigilGenerationJourneyState) -> [SigilRecordSection] {
        guard case .success(_, _, let record) = state else { return [] }
        var sections: [SigilRecordSection] = []
        sections.append(.init(title: "Mortal incarnation", body: record.mortalIncarnation.prose))
        sections.append(.init(title: "Numerology", body: record.numerologyProfile.prose))
        sections.append(.init(title: "ASH identity", body: record.ashIdentity.prose))
        sections.append(.init(title: "Plane attunement", body: record.planeAttunement.prose))
        sections.append(.init(title: "Wolf balance", body: record.wolfBalance.prose))
        sections.append(.init(title: "Sigil reading", body: record.sigilReading.prose))
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
