import Foundation
import RFEditor
import RFEngineData
import RFExport
import RFMythosCatalog
import RFGeocoding
import RFMeaning
import RFRendering
import RFSecurity
import RFSigilPipeline
import RFStorage

struct AppDependencies {
    let engineData: EngineDataStore
    let profileRepository: CoreDataProfileRepository
    let sigilPipeline: any SigilPipelineService
    let meaningService: DefaultMeaningService
    let geocoder: AppleMapsBirthplaceResolver
    let renderService: DefaultSigilRenderService
    let exportService: DefaultExportService
    let lockStore: LockConfigurationStore
    let appLockAuthenticator: any AppLockAuthenticating
    let editorDocument: EditorDocument
    let mythosCatalog: DefaultMythosCatalogService
    let diagnostics: AppDiagnostics

    static func makeDefault() -> AppDependencies {
        let engineData = EngineDataStore()
        let appSupport = AppDependencies.applicationSupportURL()
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let storeURL = appSupport.appendingPathComponent("sigil.sqlite")
        let diagnostics = AppDiagnostics(appSupportDirectoryURL: appSupport)

        let lockStore = LockConfigurationStore()
        let encryption = EncryptionService(lockProvider: lockStore)

        return AppDependencies(
            engineData: engineData,
            profileRepository: CoreDataProfileRepository(storeURL: storeURL, encryption: encryption),
            sigilPipeline: DefaultSigilPipelineService(engineData: engineData),
            meaningService: DefaultMeaningService(),
            geocoder: AppleMapsBirthplaceResolver(),
            renderService: DefaultSigilRenderService(),
            exportService: DefaultExportService(),
            lockStore: lockStore,
            appLockAuthenticator: LocalDeviceAuthenticator(),
            editorDocument: EditorDocument(),
            mythosCatalog: DefaultMythosCatalogService(),
            diagnostics: diagnostics
        )
    }

    static func applicationSupportURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Sigil", isDirectory: true)
    }
}

final class AppDiagnostics {
    enum DiagnosticsError: LocalizedError {
        case fileTooLarge(String)
        case fileNameTooLong(String)
        case tooManyFiles(Int)
        case archiveTooLarge

        var errorDescription: String? {
            switch self {
            case .fileTooLarge(let name):
                "File '\(name)' is too large for ZIP32 export."
            case .fileNameTooLong(let name):
                "File name '\(name)' is too long for ZIP export."
            case .tooManyFiles(let count):
                "ZIP export supports up to 65,535 files. Found \(count)."
            case .archiveTooLarge:
                "Archive exceeds ZIP32 size limits."
            }
        }
    }

    enum Level: String, CaseIterable, Codable {
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        case fault = "FAULT"

        var displayName: String {
            rawValue
        }
    }

    struct LogEntry: Identifiable, Hashable {
        let id: UUID
        let timestamp: Date?
        let timestampText: String
        let level: Level
        let category: String
        let message: String
        let rawLine: String

        init(
            id: UUID = UUID(),
            timestamp: Date?,
            timestampText: String,
            level: Level,
            category: String,
            message: String,
            rawLine: String
        ) {
            self.id = id
            self.timestamp = timestamp
            self.timestampText = timestampText
            self.level = level
            self.category = category
            self.message = message
            self.rawLine = rawLine
        }
    }

    struct ExportMetadata: Codable {
        let generatedAt: Date
        let appVersion: String
        let buildNumber: String
        let engineDataVersion: String
        let pipelineVersion: String
        let geometrySchemaVersion: String
        let lockEnabled: Bool
        let profileCount: Int
        let selectedProfileID: String?
        let activeSigilName: String?
    }

    let logFileURL: URL
    private let sessionMarkerURL: URL
    private let queue = DispatchQueue(label: "Sigil.Diagnostics")
    private var didInstallExceptionHandler = false

    init(appSupportDirectoryURL: URL) {
        let logsDirectory = appSupportDirectoryURL.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        self.logFileURL = logsDirectory.appendingPathComponent("runtime.log")
        self.sessionMarkerURL = logsDirectory.appendingPathComponent(".session_active")
        ensureLogFileExists()
    }

    var logFilePath: String {
        logFileURL.path
    }

    func installCrashLoggingIfNeeded() {
        queue.sync {
            guard !didInstallExceptionHandler else { return }
            didInstallExceptionHandler = true
            diagnosticsExceptionSink = self
            NSSetUncaughtExceptionHandler { exception in
                diagnosticsExceptionSink?.record(
                    "Uncaught exception '\(exception.name.rawValue)': \(exception.reason ?? "No reason provided")",
                    level: .fault,
                    category: "crash"
                )
            }
            appendLine("Installed uncaught exception handler.", level: .info, category: "diagnostics")
        }
    }

    func recordAppLaunch() {
        queue.sync {
            ensureLogFileExists()
            if FileManager.default.fileExists(atPath: sessionMarkerURL.path) {
                appendLine(
                    "Previous session ended unexpectedly. Possible crash or forced termination.",
                    level: .fault,
                    category: "crash"
                )
            }
            createSessionMarker()
            appendLine("Application launched.", level: .info, category: "lifecycle")
        }
    }

    func recordAppDidBecomeActive() {
        queue.sync {
            createSessionMarker()
            appendLine("Application became active.", level: .info, category: "lifecycle")
        }
    }

    func recordAppDidEnterBackground() {
        queue.sync {
            removeSessionMarker()
            appendLine("Application entered background.", level: .info, category: "lifecycle")
        }
    }

    func record(_ message: String, level: Level = .info, category: String = "app") {
        queue.sync {
            appendLine(message, level: level, category: category)
        }
    }

    func loadLog(maxBytes: Int = 120_000) -> String {
        queue.sync {
            loadLogLocked(maxBytes: maxBytes)
        }
    }

    func clearLog() {
        queue.sync {
            try? Data().write(to: logFileURL, options: [.atomic])
            setFileProtection(at: logFileURL)
            appendLine("Log file cleared.", level: .info, category: "diagnostics")
        }
    }

    func loadEntries(maxBytes: Int = 250_000) -> [LogEntry] {
        queue.sync {
            let logText = loadLogLocked(maxBytes: maxBytes)
            let lines = logText
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

            return lines.reversed().map(parseLine)
        }
    }

    func createExportBundle(metadata: ExportMetadata, maxLogBytes: Int = 500_000) throws -> URL {
        try queue.sync {
            let directoryName = "SigilDiagnostics-\(safeFileTimestamp(Date()))"
            let bundleDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(directoryName, isDirectory: true)

            if FileManager.default.fileExists(atPath: bundleDirectory.path) {
                try FileManager.default.removeItem(at: bundleDirectory)
            }
            try FileManager.default.createDirectory(at: bundleDirectory, withIntermediateDirectories: true)

            let logData = (try? Data(contentsOf: logFileURL)) ?? Data()
            let boundedLogData = logData.count > maxLogBytes ? logData.suffix(maxLogBytes) : logData
            try Data(boundedLogData).write(to: bundleDirectory.appendingPathComponent("runtime.log"), options: [.atomic])

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let metadataData = try encoder.encode(metadata)
            try metadataData.write(to: bundleDirectory.appendingPathComponent("metadata.json"), options: [.atomic])

            return bundleDirectory
        }
    }

    func createExportArchive(metadata: ExportMetadata, maxLogBytes: Int = 500_000) throws -> URL {
        let bundleDirectory = try createExportBundle(metadata: metadata, maxLogBytes: maxLogBytes)
        let archiveURL = bundleDirectory.appendingPathExtension("zip")

        if FileManager.default.fileExists(atPath: archiveURL.path) {
            try FileManager.default.removeItem(at: archiveURL)
        }

        let archiveData = try makeStoredZipArchive(from: bundleDirectory)
        try archiveData.write(to: archiveURL, options: [.atomic])
        try? FileManager.default.removeItem(at: bundleDirectory)
        return archiveURL
    }

    private func ensureLogFileExists() {
        guard !FileManager.default.fileExists(atPath: logFileURL.path) else { return }
        FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        setFileProtection(at: logFileURL)
    }

    private func appendLine(_ message: String, level: Level, category: String) {
        ensureLogFileExists()
        let line = "[\(timestamp())] [\(level.rawValue)] [\(category)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if let handle = try? FileHandle(forWritingTo: logFileURL) {
            defer { try? handle.close() }
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                return
            } catch {
                // Fall through to safe rewrite path below.
            }
        }

        var existing = (try? Data(contentsOf: logFileURL)) ?? Data()
        existing.append(data)
        try? existing.write(to: logFileURL, options: [.atomic])
        setFileProtection(at: logFileURL)
    }

    private func createSessionMarker() {
        FileManager.default.createFile(atPath: sessionMarkerURL.path, contents: Data())
        setFileProtection(at: sessionMarkerURL)
    }

    private func removeSessionMarker() {
        guard FileManager.default.fileExists(atPath: sessionMarkerURL.path) else { return }
        try? FileManager.default.removeItem(at: sessionMarkerURL)
    }

    private func setFileProtection(at url: URL) {
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
    }

    private func loadLogLocked(maxBytes: Int) -> String {
        guard let data = try? Data(contentsOf: logFileURL), !data.isEmpty else {
            return "Log file is empty."
        }

        let dataToDecode: Data
        if data.count > maxBytes {
            dataToDecode = data.suffix(maxBytes)
        } else {
            dataToDecode = data
        }
        return String(decoding: dataToDecode, as: UTF8.self)
    }

    private func parseLine(_ line: String) -> LogEntry {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("["),
              let firstClose = trimmed.firstIndex(of: "]"),
              firstClose < trimmed.endIndex
        else {
            return LogEntry(
                timestamp: nil,
                timestampText: "",
                level: .info,
                category: "raw",
                message: trimmed,
                rawLine: line
            )
        }

        let timestampText = String(trimmed[trimmed.index(after: trimmed.startIndex)..<firstClose])
        var cursor = trimmed.index(after: firstClose)

        func readBracketSegment() -> String? {
            guard cursor < trimmed.endIndex,
                  trimmed[cursor] == " " else { return nil }
            cursor = trimmed.index(after: cursor)
            guard cursor < trimmed.endIndex,
                  trimmed[cursor] == "[" else { return nil }
            let start = trimmed.index(after: cursor)
            guard let close = trimmed[start...].firstIndex(of: "]") else { return nil }
            let segment = String(trimmed[start..<close])
            cursor = trimmed.index(after: close)
            return segment
        }

        let levelText = readBracketSegment() ?? Level.info.rawValue
        let category = readBracketSegment() ?? "app"
        let messageStart = cursor < trimmed.endIndex && trimmed[cursor] == " "
            ? trimmed.index(after: cursor)
            : cursor
        let message = messageStart < trimmed.endIndex ? String(trimmed[messageStart...]) : ""
        let parsedDate = AppDiagnostics.iso8601WithFractionalSeconds.date(from: timestampText)
            ?? AppDiagnostics.iso8601Basic.date(from: timestampText)

        return LogEntry(
            timestamp: parsedDate,
            timestampText: timestampText,
            level: Level(rawValue: levelText) ?? .info,
            category: category,
            message: message,
            rawLine: line
        )
    }

    private func timestamp() -> String {
        AppDiagnostics.iso8601WithFractionalSeconds.string(from: Date())
    }

    private func safeFileTimestamp(_ date: Date) -> String {
        AppDiagnostics.bundleTimestampFormatter.string(from: date)
    }

    private func makeStoredZipArchive(from directoryURL: URL) throws -> Data {
        let fileManager = FileManager.default
        let parentName = directoryURL.lastPathComponent

        let subpaths = try fileManager.subpathsOfDirectory(atPath: directoryURL.path).sorted()
        let fileURLs: [URL] = subpaths.compactMap { subpath in
            let url = directoryURL.appendingPathComponent(subpath)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                return nil
            }
            return url
        }

        if fileURLs.count > Int(UInt16.max) {
            throw DiagnosticsError.tooManyFiles(fileURLs.count)
        }

        var archive = Data()
        var centralDirectory = Data()
        var entryCount: UInt16 = 0

        for fileURL in fileURLs {
            let relativeSubpath = fileURL.path.replacingOccurrences(of: directoryURL.path + "/", with: "")
            let entryName = "\(parentName)/\(relativeSubpath.replacingOccurrences(of: "\\", with: "/"))"
            let fileData = try Data(contentsOf: fileURL)

            guard let uncompressedSize = UInt32(exactly: fileData.count) else {
                throw DiagnosticsError.fileTooLarge(entryName)
            }
            guard let fileNameData = entryName.data(using: .utf8),
                  let fileNameLength = UInt16(exactly: fileNameData.count) else {
                throw DiagnosticsError.fileNameTooLong(entryName)
            }
            guard let localHeaderOffset = UInt32(exactly: archive.count) else {
                throw DiagnosticsError.archiveTooLarge
            }

            let checksum = crc32(fileData)
            let localHeader = makeLocalFileHeader(
                fileNameLength: fileNameLength,
                checksum: checksum,
                size: uncompressedSize
            )
            archive.append(localHeader)
            archive.append(fileNameData)
            archive.append(fileData)

            let centralHeader = makeCentralDirectoryHeader(
                fileNameLength: fileNameLength,
                checksum: checksum,
                size: uncompressedSize,
                localHeaderOffset: localHeaderOffset
            )
            centralDirectory.append(centralHeader)
            centralDirectory.append(fileNameData)
            entryCount &+= 1
        }

        guard let centralDirectoryOffset = UInt32(exactly: archive.count),
              let centralDirectorySize = UInt32(exactly: centralDirectory.count)
        else {
            throw DiagnosticsError.archiveTooLarge
        }

        archive.append(centralDirectory)
        archive.append(
            makeEndOfCentralDirectoryRecord(
                entryCount: entryCount,
                centralDirectorySize: centralDirectorySize,
                centralDirectoryOffset: centralDirectoryOffset
            )
        )

        return archive
    }

    private func makeLocalFileHeader(fileNameLength: UInt16, checksum: UInt32, size: UInt32) -> Data {
        var data = Data()
        data.appendUInt32LE(0x04034B50)
        data.appendUInt16LE(20)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt32LE(checksum)
        data.appendUInt32LE(size)
        data.appendUInt32LE(size)
        data.appendUInt16LE(fileNameLength)
        data.appendUInt16LE(0)
        return data
    }

    private func makeCentralDirectoryHeader(
        fileNameLength: UInt16,
        checksum: UInt32,
        size: UInt32,
        localHeaderOffset: UInt32
    ) -> Data {
        var data = Data()
        data.appendUInt32LE(0x02014B50)
        data.appendUInt16LE(20)
        data.appendUInt16LE(20)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt32LE(checksum)
        data.appendUInt32LE(size)
        data.appendUInt32LE(size)
        data.appendUInt16LE(fileNameLength)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt32LE(0)
        data.appendUInt32LE(localHeaderOffset)
        return data
    }

    private func makeEndOfCentralDirectoryRecord(
        entryCount: UInt16,
        centralDirectorySize: UInt32,
        centralDirectoryOffset: UInt32
    ) -> Data {
        var data = Data()
        data.appendUInt32LE(0x06054B50)
        data.appendUInt16LE(0)
        data.appendUInt16LE(0)
        data.appendUInt16LE(entryCount)
        data.appendUInt16LE(entryCount)
        data.appendUInt32LE(centralDirectorySize)
        data.appendUInt32LE(centralDirectoryOffset)
        data.appendUInt16LE(0)
        return data
    }

    private func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ AppDiagnostics.crc32Table[index]
        }
        return ~crc
    }

    nonisolated(unsafe) private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let iso8601Basic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let bundleTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    private static let crc32Table: [UInt32] = {
        (0..<256).map { value in
            var crc = UInt32(value)
            for _ in 0..<8 {
                if (crc & 1) == 1 {
                    crc = (crc >> 1) ^ 0xEDB8_8320
                } else {
                    crc >>= 1
                }
            }
            return crc
        }
    }()
}

nonisolated(unsafe) private var diagnosticsExceptionSink: AppDiagnostics?

private extension Data {
    mutating func appendUInt16LE(_ value: UInt16) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { bytes in
            append(contentsOf: bytes)
        }
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { bytes in
            append(contentsOf: bytes)
        }
    }
}
