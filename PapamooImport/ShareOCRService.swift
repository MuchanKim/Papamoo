import Foundation
import ImageIO
import Vision

actor ShareOCRService {
    func recognizeText(in imageData: Data, normalizedRegion: CGRect?) throws -> [String] {
        try Task.checkCancellation()

        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ShareImportError.imageDecodeFailed
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        if let normalizedRegion {
            request.regionOfInterest = CGRect(
                x: normalizedRegion.minX,
                y: 1 - normalizedRegion.maxY,
                width: normalizedRegion.width,
                height: normalizedRegion.height
            )
        }

        let orientation = imageOrientation(from: source)
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
        try handler.perform([request])
        try Task.checkCancellation()

        return (request.results ?? []).compactMap { observation in
            observation.topCandidates(1).first?.string
        }
    }

    private func imageOrientation(from source: CGImageSource) -> CGImagePropertyOrientation {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let rawValue = properties[kCGImagePropertyOrientation] as? UInt32,
              let orientation = CGImagePropertyOrientation(rawValue: rawValue)
        else {
            return .up
        }
        return orientation
    }
}
