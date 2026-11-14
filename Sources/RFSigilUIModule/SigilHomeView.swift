import SwiftUI

/// Content-first landing: brand hero, Create CTA, and recent records.
public struct SigilHomeView: View {
    @ObservedObject var recordsListViewModel: SigilRecordsListViewModel
    var onCreate: () -> Void
    var onOpenRecord: ((SigilRecord) -> Void)?

    public init(
        recordsListViewModel: SigilRecordsListViewModel,
        onCreate: @escaping () -> Void,
        onOpenRecord: ((SigilRecord) -> Void)? = nil
    ) {
        self.recordsListViewModel = recordsListViewModel
        self.onCreate = onCreate
        self.onOpenRecord = onOpenRecord
    }

    private var recentRecords: [SigilRecord] {
        let preferred = recordsListViewModel.records.filter { $0.recordType == .personalCodex }
        let source = preferred.isEmpty ? recordsListViewModel.records : preferred
        var seen = Set<String>()
        return source.filter { seen.insert($0.storageID).inserted }.prefix(5).map { $0 }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SigilVisualTheme.spacingSection) {
                hero
                createCallToAction
                if recentRecords.isEmpty {
                    emptyRecent
                } else {
                    recentSection
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background { SigilVisualTheme.atmosphere }
        .sigilInlineNavigationTitle()
        .task { await recordsListViewModel.refresh() }
        .refreshable { await recordsListViewModel.refresh() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: SigilVisualTheme.spacingStack) {
            Image(systemName: SigilVisualTheme.heroSymbolName)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            Text(SigilVisualTheme.brandName)
                .font(.largeTitle.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text(SigilVisualTheme.supportingLine)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private var createCallToAction: some View {
        Button(action: onCreate) {
            Label("Create a Sigil", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityHint("Opens the profile form to generate a new Sigil")
    }

    private var emptyRecent: some View {
        ContentUnavailableView {
            Label("No records yet", systemImage: "tray")
        } description: {
            Text("Created Sigils are stored only on this device. Use Create a Sigil to begin.")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.title3.weight(.semibold))

            VStack(spacing: 0) {
                ForEach(Array(recentRecords.enumerated()), id: \.element.id) { index, record in
                    if index > 0 {
                        Divider()
                    }
                    Button {
                        onOpenRecord?(record)
                    } label: {
                        SigilRecordSummaryRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: SigilVisualTheme.cornerRadius, style: .continuous))
        }
    }
}

struct SigilRecordSummaryRow: View {
    let record: SigilRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(shortID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayTitle), \(shortID)")
    }

    private var displayTitle: String {
        switch record.recordType {
        case .personalCodex: return "PersonalCodex"
        case .profile: return "Profile"
        case .flare: return "Flare"
        case .identity: return "Identity"
        case .canonicalGeometry: return "Geometry"
        }
    }

    private var shortID: String {
        let id = record.storageID
        if id.count <= 12 { return id }
        return String(id.prefix(12)) + "…"
    }

    private var symbolName: String {
        switch record.recordType {
        case .personalCodex: return "book.closed"
        case .profile: return "person.crop.circle"
        case .flare: return "sparkles"
        case .identity: return "finger.point"
        case .canonicalGeometry: return "point.3.connected.trianglepath.dotted"
        }
    }
}
