import SwiftUI
import RFSigilPersonalCodex
import RFSigilPrivacySecurity

/// Read-only detail for a saved record opened from Home or Records.
public struct SigilSavedRecordDetailView: View {
    let record: SigilRecord
    let recordsStore: SigilRecordsStore

    @Environment(\.dismiss) private var dismiss
    @State private var sections: [SigilRecordSection] = []
    @State private var celestialName: String?
    @State private var isLoading = true
    @State private var errorMessage: String?

    public init(record: SigilRecord, recordsStore: SigilRecordsStore) {
        self.record = record
        self.recordsStore = recordsStore
    }

    public var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                ContentUnavailableView(
                    "Unable to open",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                List {
                    Section {
                        LabeledContent("Type", value: record.recordType.rawValue)
                        LabeledContent("Storage ID", value: record.storageID)
                    }
                    if let celestialName {
                        Section("Celestial name") {
                            Text(celestialName)
                                .font(.title3.weight(.semibold))
                        }
                    }
                    if !sections.isEmpty {
                        Section("PersonalCodex") {
                            ForEach(sections) { section in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(section.title)
                                        .font(.headline)
                                    Text(section.body)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Record")
        .sigilInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        guard record.recordType == .personalCodex else {
            errorMessage = nil
            sections = []
            celestialName = nil
            return
        }

        let result = await recordsStore.open(
            storageID: record.storageID,
            recordType: .personalCodex,
            as: SigilPersonalCodex.self
        )
        switch result {
        case .success(let loaded):
            celestialName = loaded.celestialName.celestialName
            sections = [
                .init(title: "Mortal incarnation", body: loaded.mortalIncarnation.prose),
                .init(title: "Numerology", body: loaded.numerologyProfile.prose),
                .init(title: "ASH identity", body: loaded.ashIdentity.prose),
                .init(title: "Plane attunement", body: loaded.planeAttunement.prose),
                .init(title: "Wolf balance", body: loaded.wolfBalance.prose),
                .init(title: "Sigil reading", body: loaded.sigilReading.prose)
            ]
            errorMessage = nil
        case .failure(let failure):
            errorMessage = failure.message
            sections = []
            celestialName = nil
        }
    }
}
