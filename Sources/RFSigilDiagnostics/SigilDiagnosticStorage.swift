import Foundation

/// Bounded protected local storage for diagnostic bundles.
///
/// Bundles are retained as `sigil-diag-<bundleID>.json`, `.md`, and
/// `.manifest.json` files. Retention applies an age cutoff, a bundle-count
/// rotation, and a disk quota, oldest first. On iOS the storage directory
/// receives best-effort complete-until-first-user-authentication file
/// protection; a protection failure is non-fatal, because the bounded local
/// store is the core requirement.
struct SigilDiagnosticStorage {
    static let bundleFilePrefix = "sigil-diag-"

    let directory: URL

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = (try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? FileManager.default.temporaryDirectory
            self.directory = base.appendingPathComponent("SigilDiagnostics", isDirectory: true)
        }
    }

    func makeDirectory() throws {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory)
        if exists && !isDirectory.boolValue {
            throw SigilDiagnosticExportError.storageUnavailable(
                "storage path exists and is not a directory: \(directory.lastPathComponent)"
            )
        }
        if !exists {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                throw SigilDiagnosticExportError.storageUnavailable(
                    "cannot create storage directory: \(error.localizedDescription)"
                )
            }
        }
        #if os(iOS)
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: directory.path
        )
        #endif
    }

    func writeAtomic(_ data: Data, to url: URL) throws {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw SigilDiagnosticExportError.partWriteFailed(
                "write failed for \(url.lastPathComponent): \(error.localizedDescription)"
            )
        }
    }

    func removePart(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    /// Applies the retention window, bundle-count rotation, and disk quota,
    /// removing oldest bundle files first. Cleanup failures are best-effort;
    /// the caller's subsequent write is still enforced by the size guard.
    func applyQuotaAndRetention(
        maxDiskBytes: Int,
        maxRetainedBundles: Int,
        retentionSeconds: Int,
        now: Date
    ) {
        let cutoff = now.addingTimeInterval(TimeInterval(-retentionSeconds))
        var files = Self.listBundleFiles(in: directory)

        for file in files where file.modified <= cutoff {
            try? FileManager.default.removeItem(at: file.url)
        }
        files.removeAll { $0.modified <= cutoff }

        var byStem: [String: [BundleFile]] = [:]
        for file in files {
            byStem[Self.stem(of: file.url), default: []].append(file)
        }
        var stems = byStem.keys.sorted { left, right in
            let oldestLeft = byStem[left]?.map(\.modified).min() ?? .distantPast
            let oldestRight = byStem[right]?.map(\.modified).min() ?? .distantPast
            return oldestLeft < oldestRight
        }
        while stems.count > maxRetainedBundles {
            let oldest = stems.removeFirst()
            for file in byStem[oldest] ?? [] {
                try? FileManager.default.removeItem(at: file.url)
            }
        }

        while true {
            let remaining = Self.listBundleFiles(in: directory)
            let total = remaining.reduce(Int64(0)) { $0 + Int64($1.size) }
            guard Int(total) > maxDiskBytes,
                  let oldest = remaining.min(by: { $0.modified < $1.modified }) else {
                break
            }
            try? FileManager.default.removeItem(at: oldest.url)
        }
    }

    struct BundleFile {
        let url: URL
        let modified: Date
        let size: Int
    }

    static func listBundleFiles(in directory: URL) -> [BundleFile] {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else {
            return []
        }
        var result: [BundleFile] = []
        for entry in entries where entry.lastPathComponent.hasPrefix(bundleFilePrefix) {
            let values = try? entry.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            result.append(BundleFile(
                url: entry,
                modified: values?.contentModificationDate ?? .distantPast,
                size: values?.fileSize ?? 0
            ))
        }
        return result
    }

    /// Groups a bundle's part files (json, md, manifest) under one stem.
    /// Bundle IDs are UUIDs and contain no dots, so two extension
    /// deletions normalize every part name.
    static func stem(of url: URL) -> String {
        guard url.lastPathComponent.hasPrefix(bundleFilePrefix) else {
            return url.lastPathComponent
        }
        return url.deletingPathExtension().deletingPathExtension().lastPathComponent
    }
}
