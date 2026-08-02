import Foundation

nonisolated struct SubscriptionImportInbox: Sendable {

    enum InboxError: LocalizedError {
        case appGroupUnavailable

        var errorDescription: String? {
            switch self {
            case .appGroupUnavailable:
                "공유 저장 공간에 접근할 수 없습니다."
            }
        }
    }

    struct Entry: Sendable {
        let fileURL: URL
        let payload: PendingSubscriptionImport
    }

    // MARK: - Properties

    private let directoryURL: URL?

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL
    }

    // MARK: - Methods

    func enqueue(_ payload: PendingSubscriptionImport) throws {
        let directory = try resolvedDirectoryURL()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let data = try PropertyListEncoder().encode(payload)
        let destination = directory.appending(
            path: "\(payload.id.uuidString).import",
            directoryHint: .notDirectory
        )
        try data.write(to: destination, options: [.atomic, .completeFileProtectionUnlessOpen])
    }

    func entries() throws -> [Entry] {
        let directory = try resolvedDirectoryURL()
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }

        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "import" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        return try fileURLs.map { fileURL in
            let data = try Data(contentsOf: fileURL)
            let payload = try PropertyListDecoder().decode(PendingSubscriptionImport.self, from: data)
            return Entry(fileURL: fileURL, payload: payload)
        }
    }

    func remove(_ entries: [Entry]) throws {
        for entry in entries {
            try FileManager.default.removeItem(at: entry.fileURL)
        }
    }

    // MARK: - Private Methods

    private func resolvedDirectoryURL() throws -> URL {
        if let directoryURL {
            return directoryURL
        }
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroup.identifier
        ) else {
            throw InboxError.appGroupUnavailable
        }
        return containerURL.appending(path: "PendingSubscriptionImports", directoryHint: .isDirectory)
    }
}
