import RFSigilCanon
import RFSigilPersonalCodex
import RFSigilPrivacySecurity
import RFSigilRuntime
import RFSigilUIModule
import RFSigilVisibleGlyph
import SwiftUI

@main
struct SigilApp: App {
    @StateObject private var dashboardViewModel: SigilDashboardViewModel
    @StateObject private var experienceViewModel: SigilExperienceViewModel
    @StateObject private var recordsListViewModel: SigilRecordsListViewModel

    init() {
        let assembly = SigilRuntimeAssembly()
        let dashboardVM = SigilDashboardViewModel(status: assembly.dashboardStatus())

        // Build the real services for the experience.
        let glyphService = assembly.visibleGlyphService
        let codexService: SigilPersonalCodexService
        if let existing = assembly.personalCodexService {
            codexService = existing
        } else {
            // Fail closed at composition: the PersonalCodex path requires the
            // integrity-verified canon resource shipped in RFSigilCanon.
            let canon = try! SigilCanonLoader().load()
            codexService = SigilPersonalCodexService(
                visibleGlyph: glyphService,
                canon: canon
            )
        }

        // Build the real secure persistence service.
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let sigilDir = appSupport.appendingPathComponent("Sigil", isDirectory: true)
        let recordsDir = sigilDir.appendingPathComponent("Records", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordsDir, withIntermediateDirectories: true)
        let keyStore = SigilKeychainKeyStore()
        let recordStore = SigilSecureRecordStore(
            directoryURL: recordsDir,
            keyStore: keyStore,
            keyID: "sigil-default"
        )
        let persistence = SigilSecurePersistenceService(
            store: recordStore,
            diagnostics: assembly.diagnostics
        )
        let recordsStore = SigilRecordsStore(persistence: persistence)

        let journeyVM = SigilGenerationJourneyViewModel(
            storageID: UUID().uuidString,
            glyphService: glyphService,
            codexService: codexService
        )
        let recordsListVM = SigilRecordsListViewModel(recordsStore: recordsStore)
        let experienceVM = SigilExperienceViewModel(
            journeyViewModel: journeyVM,
            recordsListViewModel: recordsListVM
        )

        _dashboardViewModel = StateObject(wrappedValue: dashboardVM)
        _experienceViewModel = StateObject(wrappedValue: experienceVM)
        _recordsListViewModel = StateObject(wrappedValue: recordsListVM)
    }

    var body: some Scene {
        WindowGroup {
            SigilRootTabView(
                dashboardViewModel: dashboardViewModel,
                experienceViewModel: experienceViewModel,
                recordsListViewModel: recordsListViewModel
            )
        }
    }
}
