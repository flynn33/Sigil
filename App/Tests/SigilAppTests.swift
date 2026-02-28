import XCTest
import RFCoreModels
import RFSecurity
@testable import Sigil

final class SigilAppTests: XCTestCase {
    @MainActor
    func testCoordinatorStartsEmptySelection() {
        let coordinator = AppCoordinator()
        XCTAssertNil(coordinator.selectedProfile)
    }

    @MainActor
    func testGenerateSigilMarksExtensionUsageWhenEnabled() async {
        let coordinator = AppCoordinator()
        coordinator.selectedProfile = sampleProfile()

        await coordinator.generateSigil(options: SigilOptions(includeTraitExtensions: true))

        XCTAssertNotNil(coordinator.activeSigil)
        XCTAssertTrue(coordinator.activeSigilUsesExtensions)
    }

    @MainActor
    func testGenerateSigilMarksCanonicalUsageWhenExtensionsDisabled() async {
        let coordinator = AppCoordinator()
        coordinator.selectedProfile = sampleProfile()

        await coordinator.generateSigil(options: SigilOptions(includeTraitExtensions: false))

        XCTAssertNotNil(coordinator.activeSigil)
        XCTAssertFalse(coordinator.activeSigilUsesExtensions)
    }

    @MainActor
    func testAppLockInitializesWhenEnabled() {
        let coordinator = makeCoordinator(lockEnabled: true, authenticator: MockAppLockAuthenticator(results: [true]))
        coordinator.initializeAppLockState()
        XCTAssertTrue(coordinator.isAppLocked)
    }

    @MainActor
    func testUnlockAppClearsLockOnSuccess() async {
        let coordinator = makeCoordinator(lockEnabled: true, authenticator: MockAppLockAuthenticator(results: [true]))
        coordinator.initializeAppLockState()
        await coordinator.unlockApp()
        XCTAssertFalse(coordinator.isAppLocked)
    }

    @MainActor
    func testUnlockAppKeepsLockOnFailure() async {
        let coordinator = makeCoordinator(lockEnabled: true, authenticator: MockAppLockAuthenticator(results: [false]))
        coordinator.initializeAppLockState()
        await coordinator.unlockApp()
        XCTAssertTrue(coordinator.isAppLocked)
        XCTAssertNotNil(coordinator.errorMessage)
    }

    @MainActor
    func testDynamicFieldDeletionByIDRemovesOnlySelectedField() {
        let first = DynamicFieldDraft(key: "totem")
        let second = DynamicFieldDraft(key: "lineage")
        let model = ProfileFormModel()
        model.dynamicFields = [first, second]

        model.removeDynamicField(id: first.id)

        XCTAssertEqual(model.dynamicFields.count, 1)
        XCTAssertEqual(model.dynamicFields.first?.id, second.id)
    }

    @MainActor
    func testProfileFormBuildsBirthOrderTotals() throws {
        let model = ProfileFormModel()
        model.givenName = "Alicia"
        model.familyName = "Wolfsbane"
        model.birthOrder = "2"
        model.birthOrderTotal = "4"
        model.birthplaceName = "Seattle"
        model.latitude = "47.6062"
        model.longitude = "-122.3321"

        model.motherBirthOrder = "3"
        model.motherBirthOrderTotal = "5"
        model.motherHairColor = "Brown"
        model.motherEyeColor = "Hazel"

        model.fatherBirthOrder = "7"
        model.fatherBirthOrderTotal = "9"
        model.fatherHairColor = "Black"
        model.fatherEyeColor = "Blue"

        let profile = try model.buildProfile()
        XCTAssertEqual(profile.birthOrder, 2)
        XCTAssertEqual(profile.birthOrderTotal, 4)
        XCTAssertEqual(profile.mother.birthOrder, 3)
        XCTAssertEqual(profile.mother.birthOrderTotal, 5)
        XCTAssertEqual(profile.father.birthOrder, 7)
        XCTAssertEqual(profile.father.birthOrderTotal, 9)
    }

    @MainActor
    func testProfileFormRejectsBirthOrderPositionGreaterThanTotal() {
        let model = ProfileFormModel()
        model.givenName = "Alicia"
        model.familyName = "Wolfsbane"
        model.birthOrder = "5"
        model.birthOrderTotal = "4"
        model.birthplaceName = "Seattle"
        model.latitude = "47.6062"
        model.longitude = "-122.3321"
        model.motherBirthOrder = "1"
        model.fatherBirthOrder = "1"

        XCTAssertThrowsError(try model.buildProfile())
    }

    @MainActor
    func testProfileFormBuildsProfessionEntriesAndHobbies() throws {
        let model = ProfileFormModel()
        model.givenName = "Alicia"
        model.familyName = "Wolfsbane"
        model.birthOrder = "2"
        model.birthplaceName = "Seattle"
        model.latitude = "47.6062"
        model.longitude = "-122.3321"
        model.motherBirthOrder = "1"
        model.fatherBirthOrder = "1"
        model.hobbiesInterestsRaw = "Archery, Hiking, Astronomy"
        model.professions = [
            ProfessionDraft(
                profession: "Police Officer",
                titleOrPosition: "Detective Sergeant",
                yearsInProfession: "20",
                customItemLabel: "Badge Number",
                customItemValue: "4172"
            ),
            ProfessionDraft(
                profession: "IT",
                titleOrPosition: "Systems Engineer",
                yearsInProfession: "8",
                customItemLabel: "",
                customItemValue: ""
            )
        ]

        let profile = try model.buildProfile()
        XCTAssertEqual(profile.traits.professions.count, 2)
        XCTAssertEqual(profile.traits.professions[0].profession, "Police Officer")
        XCTAssertEqual(profile.traits.professions[0].yearsInProfession, 20)
        XCTAssertEqual(profile.traits.professions[0].customItemLabel, "Badge Number")
        XCTAssertEqual(profile.traits.professions[0].customItemValue, "4172")
        XCTAssertEqual(profile.traits.professions[1].profession, "IT")
        XCTAssertEqual(profile.traits.hobbiesInterests, ["Archery", "Hiking", "Astronomy"])
    }

    @MainActor
    func testProfileFormRejectsProfessionWithInvalidYears() {
        let model = ProfileFormModel()
        model.givenName = "Alicia"
        model.familyName = "Wolfsbane"
        model.birthOrder = "2"
        model.birthplaceName = "Seattle"
        model.latitude = "47.6062"
        model.longitude = "-122.3321"
        model.motherBirthOrder = "1"
        model.fatherBirthOrder = "1"
        model.professions = [
            ProfessionDraft(
                profession: "Police Officer",
                titleOrPosition: "Detective Sergeant",
                yearsInProfession: "twenty"
            )
        ]

        XCTAssertThrowsError(try model.buildProfile())
    }

    func testDiagnosticsWritesPersistentLogFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let diagnostics = AppDiagnostics(appSupportDirectoryURL: root)
        diagnostics.record("Intentional test error", level: .error, category: "tests")

        XCTAssertTrue(FileManager.default.fileExists(atPath: diagnostics.logFileURL.path))
        XCTAssertTrue(diagnostics.loadLog().contains("Intentional test error"))
    }

    func testDiagnosticsExportBundleContainsLogAndMetadata() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let diagnostics = AppDiagnostics(appSupportDirectoryURL: root)
        diagnostics.record("Bundle export marker", level: .warning, category: "tests")

        let metadata = AppDiagnostics.ExportMetadata(
            generatedAt: Date(),
            appVersion: "1.0",
            buildNumber: "100",
            engineDataVersion: RFConstants.engineDataVersion,
            pipelineVersion: RFConstants.pipelineVersion,
            geometrySchemaVersion: RFConstants.geometrySchemaVersion,
            lockEnabled: false,
            profileCount: 2,
            selectedProfileID: UUID().uuidString,
            activeSigilName: "Test Sigil"
        )

        let bundle = try diagnostics.createExportBundle(metadata: metadata)
        let logURL = bundle.appendingPathComponent("runtime.log")
        let metadataURL = bundle.appendingPathComponent("metadata.json")

        XCTAssertTrue(FileManager.default.fileExists(atPath: logURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: metadataURL.path))

        let logText = try String(contentsOf: logURL)
        XCTAssertTrue(logText.contains("Bundle export marker"))

        let metadataData = try Data(contentsOf: metadataURL)
        let metadataJSON = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any]
        XCTAssertEqual(metadataJSON?["pipelineVersion"] as? String, RFConstants.pipelineVersion)
    }

    func testDiagnosticsExportArchiveContainsLogAndMetadata() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let diagnostics = AppDiagnostics(appSupportDirectoryURL: root)
        diagnostics.record("Archive export marker", level: .warning, category: "tests")

        let metadata = AppDiagnostics.ExportMetadata(
            generatedAt: Date(),
            appVersion: "1.0",
            buildNumber: "101",
            engineDataVersion: RFConstants.engineDataVersion,
            pipelineVersion: RFConstants.pipelineVersion,
            geometrySchemaVersion: RFConstants.geometrySchemaVersion,
            lockEnabled: false,
            profileCount: 1,
            selectedProfileID: UUID().uuidString,
            activeSigilName: "Archive Sigil"
        )

        let archiveURL = try diagnostics.createExportArchive(metadata: metadata)
        XCTAssertEqual(archiveURL.pathExtension, "zip")
        XCTAssertTrue(FileManager.default.fileExists(atPath: archiveURL.path))

        let archiveData = try Data(contentsOf: archiveURL)
        let entries = try parseStoredZipEntries(from: archiveData)
        let logEntry = try XCTUnwrap(entries.first(where: { $0.key.hasSuffix("/runtime.log") })?.value)
        let metadataEntry = try XCTUnwrap(entries.first(where: { $0.key.hasSuffix("/metadata.json") })?.value)

        let logText = String(decoding: logEntry, as: UTF8.self)
        XCTAssertTrue(logText.contains("Archive export marker"))

        let metadataJSON = try JSONSerialization.jsonObject(with: metadataEntry) as? [String: Any]
        XCTAssertEqual(metadataJSON?["pipelineVersion"] as? String, RFConstants.pipelineVersion)
    }

    private func parseStoredZipEntries(from data: Data) throws -> [String: Data] {
        var entries: [String: Data] = [:]
        var offset = 0

        while offset + 4 <= data.count {
            let signature = try readUInt32(from: data, at: offset)
            if signature == 0x04034B50 {
                let method = try readUInt16(from: data, at: offset + 8)
                guard method == 0 else {
                    throw NSError(domain: "SigilTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected stored ZIP entries (method 0)."])
                }

                let compressedSize = Int(try readUInt32(from: data, at: offset + 18))
                let nameLength = Int(try readUInt16(from: data, at: offset + 26))
                let extraLength = Int(try readUInt16(from: data, at: offset + 28))

                let nameStart = offset + 30
                let nameEnd = nameStart + nameLength
                guard nameEnd <= data.count else {
                    throw NSError(domain: "SigilTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid ZIP file name length."])
                }

                let nameData = Data(data[nameStart..<nameEnd])
                guard let entryName = String(data: nameData, encoding: .utf8) else {
                    throw NSError(domain: "SigilTests", code: 3, userInfo: [NSLocalizedDescriptionKey: "ZIP file name is not valid UTF-8."])
                }

                let payloadStart = nameEnd + extraLength
                let payloadEnd = payloadStart + compressedSize
                guard payloadEnd <= data.count else {
                    throw NSError(domain: "SigilTests", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid ZIP payload size for entry '\(entryName)'."])
                }

                entries[entryName] = Data(data[payloadStart..<payloadEnd])
                offset = payloadEnd
                continue
            }

            if signature == 0x02014B50 || signature == 0x06054B50 {
                break
            }

            throw NSError(domain: "SigilTests", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unexpected ZIP signature 0x\(String(signature, radix: 16))."])
        }

        return entries
    }

    private func readUInt16(from data: Data, at offset: Int) throws -> UInt16 {
        guard offset + 2 <= data.count else {
            throw NSError(domain: "SigilTests", code: 6, userInfo: [NSLocalizedDescriptionKey: "Unexpected end of ZIP data while reading UInt16."])
        }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private func readUInt32(from data: Data, at offset: Int) throws -> UInt32 {
        guard offset + 4 <= data.count else {
            throw NSError(domain: "SigilTests", code: 7, userInfo: [NSLocalizedDescriptionKey: "Unexpected end of ZIP data while reading UInt32."])
        }
        return UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}

private actor MockAppLockAuthenticator: AppLockAuthenticating {
    private var results: [Bool]

    init(results: [Bool]) {
        self.results = results
    }

    func authenticate(reason: String) async -> Bool {
        guard !results.isEmpty else { return false }
        return results.removeFirst()
    }
}

private func sampleProfile() -> PersonProfile {
    var components = DateComponents()
    components.year = 1990
    components.month = 7
    components.day = 15
    components.hour = 12
    components.minute = 0

    let date = Calendar(identifier: .gregorian).date(from: components)!

    return PersonProfile(
        givenName: "Alicia",
        familyName: "Wolfsbane",
        birthDetails: BirthDetails(date: date, isTimeUnknown: false),
        birthOrder: 2,
        birthplaceName: "Seattle",
        birthplace: GeoPoint(latitude: 47.6062, longitude: -122.3321),
        mother: ParentTraits(birthOrder: 1, hairColor: "Brown", eyeColor: "Hazel"),
        father: ParentTraits(birthOrder: 3, hairColor: "Black", eyeColor: "Blue"),
        traits: TraitBundle(
            familyNames: ["Wolfsbane", "Dale"],
            heritage: ["Norse", "Celtic"],
            petNames: ["Fen", "Ash"],
            additionalTraits: [
                "lucky_number": "7",
                "childhood_symbol": "raven"
            ]
        )
    )
}

@MainActor
private func makeCoordinator(
    lockEnabled: Bool,
    authenticator: any AppLockAuthenticating
) -> AppCoordinator {
    var dependencies = AppDependencies.makeDefault()
    dependencies.lockStore.setBiometricLockEnabled(lockEnabled)
    dependencies = AppDependencies(
        engineData: dependencies.engineData,
        profileRepository: dependencies.profileRepository,
        sigilPipeline: dependencies.sigilPipeline,
        meaningService: dependencies.meaningService,
        geocoder: dependencies.geocoder,
        renderService: dependencies.renderService,
        exportService: dependencies.exportService,
        lockStore: dependencies.lockStore,
        appLockAuthenticator: authenticator,
        editorDocument: dependencies.editorDocument,
        mythosCatalog: dependencies.mythosCatalog,
        diagnostics: dependencies.diagnostics
    )
    return AppCoordinator(dependencies: dependencies)
}
