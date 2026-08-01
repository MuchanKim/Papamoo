import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated enum ShareImageProcessor {
    @concurrent
    static func previewData(from data: Data, maxPixelSize: Int = 2_400) async throws -> Data {
        try Task.checkCancellation()
        let image = try downsampledImage(from: data, maxPixelSize: maxPixelSize)
        try Task.checkCancellation()
        return try jpegData(from: image)
    }

    @concurrent
    static func croppedPreviewData(
        from previewData: Data,
        normalizedRegion: CGRect
    ) async throws -> Data {
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithData(previewData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ShareImportError.imageDecodeFailed
        }

        let unitRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let region = normalizedRegion.standardized.intersection(unitRect)
        guard region.isNull == false, region.width > 0, region.height > 0 else {
            throw ShareImportError.imageDecodeFailed
        }

        let pixelRect = CGRect(
            x: region.minX * CGFloat(image.width),
            y: (1 - region.maxY) * CGFloat(image.height),
            width: region.width * CGFloat(image.width),
            height: region.height * CGFloat(image.height)
        ).integral

        guard let croppedImage = image.cropping(to: pixelRect) else {
            throw ShareImportError.imageDecodeFailed
        }

        try Task.checkCancellation()
        return try jpegData(from: croppedImage)
    }

    private static func downsampledImage(from data: Data, maxPixelSize: Int) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ShareImportError.imageDecodeFailed
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true,
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ShareImportError.imageDecodeFailed
        }
        return image
    }

    private static func jpegData(from image: CGImage) throws -> Data {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ShareImportError.imageDecodeFailed
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.92,
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ShareImportError.imageDecodeFailed
        }
        return output as Data
    }
}
