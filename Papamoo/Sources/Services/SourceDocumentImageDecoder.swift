import CoreGraphics
import Foundation
import ImageIO

nonisolated enum SourceDocumentImageDecoder {
    @concurrent
    static func decode(_ data: Data) async -> CGImage? {
        guard Task.isCancelled == false,
              let source = CGImageSourceCreateWithData(data as CFData, nil)
        else { return nil }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
