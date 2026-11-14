import ForsettiCore
import RFSigilCoreModels
import SwiftUI

@MainActor
public final class SigilDashboardViewModel: ObservableObject {
    @Published public private(set) var status: RFSigilDashboardStatus

    public init(status: RFSigilDashboardStatus) {
        self.status = status
    }

    public func update(status: RFSigilDashboardStatus) {
        self.status = status
    }
}

public struct SigilPhase1DashboardView: View {
    @ObservedObject private var viewModel: SigilDashboardViewModel

    public init(viewModel: SigilDashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 260), spacing: 14)],
                spacing: 14
            ) {
                ForEach(viewModel.status.cards) { card in
                    SigilStatusCard(card: card)
                }
            }
            .padding(16)
        }
        .background(Color.gray.opacity(0.08))
        .navigationTitle(viewModel.status.title)
        .sigilInlineNavigationTitle()
    }
}

private struct SigilStatusCard: View {
    let card: RFSigilDashboardCard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: card.symbolName)
                    .font(.title3)
                    .foregroundStyle(card.status.tint)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(card.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(card.status.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(card.status.tint)
                }
            }

            Text(card.summary)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 172, alignment: .topLeading)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.gray.opacity(0.28), lineWidth: 0.5)
        )
    }
}

private extension RFSigilStatusKind {
    var tint: Color {
        switch self {
        case .pass:
            return .green
        case .passWithAllowedBlocker:
            return .orange
        case .blocked:
            return .yellow
        case .fail:
            return .red
        }
    }
}

public final class SigilUIModule: ForsettiUIModule {
    public let descriptor: ModuleDescriptor
    public let manifest: ModuleManifest

    public var uiContributions: UIContributions {
        UIContributions(
            viewInjections: [
                ViewInjectionDescriptor(
                    injectionID: "sigil.phase1.dashboard.injection",
                    slot: "sigil.primary",
                    viewID: "sigil.phase1.dashboard",
                    priority: 100
                )
            ]
        )
    }

    public init(descriptor: ModuleDescriptor, manifest: ModuleManifest) {
        self.descriptor = descriptor
        self.manifest = manifest
    }

    public func start(context: any ForsettiModuleContext) throws {
        context.publishEvent(type: "sigil.ui.started", payload: ["moduleID": descriptor.moduleID])
    }

    public func stop(context: any ForsettiModuleContext) {
        context.publishEvent(type: "sigil.ui.stopped", payload: ["moduleID": descriptor.moduleID])
    }
}
