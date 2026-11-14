import SwiftUI

/// End-user tab chrome: Home · Records · Settings. Create is a full-screen task.
public struct SigilRootTabView: View {
    @ObservedObject var dashboardViewModel: SigilDashboardViewModel
    @ObservedObject var experienceViewModel: SigilExperienceViewModel
    @ObservedObject var recordsListViewModel: SigilRecordsListViewModel

    @State private var showCreate = false
    @State private var openedRecord: SigilOpenedRecordSheet?

    public init(
        dashboardViewModel: SigilDashboardViewModel,
        experienceViewModel: SigilExperienceViewModel,
        recordsListViewModel: SigilRecordsListViewModel
    ) {
        self.dashboardViewModel = dashboardViewModel
        self.experienceViewModel = experienceViewModel
        self.recordsListViewModel = recordsListViewModel
    }

    public var body: some View {
        // iOS 17-compatible tab chrome (the iOS 18 `Tab` API requires a higher
        // deployment target than this project's IPHONEOS_DEPLOYMENT_TARGET).
        TabView {
            NavigationStack {
                SigilHomeView(
                    recordsListViewModel: recordsListViewModel,
                    onCreate: beginCreate,
                    onOpenRecord: { openedRecord = SigilOpenedRecordSheet(record: $0) }
                )
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                SigilRecordsListView(
                    viewModel: recordsListViewModel,
                    onOpen: { openedRecord = SigilOpenedRecordSheet(record: $0) },
                    onCreate: beginCreate
                )
            }
            .tabItem {
                Label("Records", systemImage: "tray.full")
            }

            NavigationStack {
                SigilSettingsView(dashboardViewModel: dashboardViewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .sigilTaskCover(isPresented: $showCreate) {
            SigilExperienceView(
                viewModel: experienceViewModel,
                onDismiss: { showCreate = false }
            )
        }
        .sheet(item: $openedRecord) { wrapper in
            NavigationStack {
                SigilSavedRecordDetailView(
                    record: wrapper.record,
                    recordsStore: recordsListViewModel.recordsStore
                )
            }
        }
    }

    private func beginCreate() {
        experienceViewModel.beginNewCreation()
        showCreate = true
    }
}

/// Sheet identity that stays unique across record types sharing a storage ID.
struct SigilOpenedRecordSheet: Identifiable {
    let record: SigilRecord
    var id: String { record.id }
}
