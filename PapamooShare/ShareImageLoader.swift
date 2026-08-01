import UniformTypeIdentifiers
import UIKit

@MainActor
enum ShareImageLoader {
    static func loadData(from extensionContext: NSExtensionContext) async throws -> Data {
        let extensionItems = extensionContext.inputItems.compactMap { $0 as? NSExtensionItem }
        let providers = extensionItems.flatMap { $0.attachments ?? [] }

        guard let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
        }) else {
            throw ShareImportError.missingInput
        }

        return try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                if let data {
                    continuation.resume(returning: data)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: ShareImportError.unsupportedImage)
                }
            }
        }
    }
}
