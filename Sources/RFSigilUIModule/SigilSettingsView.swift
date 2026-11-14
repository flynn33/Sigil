import SwiftUI

/// Infrequent app-wide destinations: privacy, system status, about.
public struct SigilSettingsView: View {
    @ObservedObject var dashboardViewModel: SigilDashboardViewModel

    public init(dashboardViewModel: SigilDashboardViewModel) {
        self.dashboardViewModel = dashboardViewModel
    }

    public var body: some View {
        List {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local only")
                        Text("Records stay on this device. No analytics or backend sync.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield")
                }
                .accessibilityElement(children: .combine)
            } header: {
                Text("Privacy")
            }

            Section("System") {
                NavigationLink {
                    SigilPhase1DashboardView(viewModel: dashboardViewModel)
                } label: {
                    Label("System status", systemImage: "gauge")
                }
            }

            Section("Sigil") {
                NavigationLink {
                    SigilAboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
