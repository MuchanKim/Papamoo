import CoreGraphics

enum ShareCropLayout {

    // MARK: - Methods

    static func aspectFitRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: (containerSize.width - size.width) / 2,
            y: (containerSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    static func displayRect(for normalizedRect: CGRect, in imageRect: CGRect) -> CGRect {
        CGRect(
            x: imageRect.minX + normalizedRect.minX * imageRect.width,
            y: imageRect.minY + normalizedRect.minY * imageRect.height,
            width: normalizedRect.width * imageRect.width,
            height: normalizedRect.height * imageRect.height
        )
    }

    static func moved(_ rect: CGRect, translation: CGSize, in imageRect: CGRect) -> CGRect {
        guard imageRect.width > 0, imageRect.height > 0 else { return rect }
        var result = rect.offsetBy(
            dx: translation.width / imageRect.width,
            dy: translation.height / imageRect.height
        )
        result.origin.x = min(max(0, result.origin.x), 1 - result.width)
        result.origin.y = min(max(0, result.origin.y), 1 - result.height)
        return result
    }

    static func scaled(_ rect: CGRect, magnification: CGFloat) -> CGRect {
        let minimumSize: CGFloat = 0.2
        let newWidth = min(max(minimumSize, rect.width * magnification), 1)
        let newHeight = min(max(minimumSize, rect.height * magnification), 1)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let origin = CGPoint(
            x: min(max(0, center.x - newWidth / 2), 1 - newWidth),
            y: min(max(0, center.y - newHeight / 2), 1 - newHeight)
        )
        return CGRect(origin: origin, size: CGSize(width: newWidth, height: newHeight))
    }

    static func resized(
        _ rect: CGRect,
        dragging corner: ShareCropCorner,
        translation: CGSize,
        in imageRect: CGRect
    ) -> CGRect {
        guard imageRect.width > 0, imageRect.height > 0 else { return rect }

        let minimumDisplayLength: CGFloat = 64
        let minimumWidth = min(1, minimumDisplayLength / imageRect.width)
        let minimumHeight = min(1, minimumDisplayLength / imageRect.height)
        let dx = translation.width / imageRect.width
        let dy = translation.height / imageRect.height

        var minX = rect.minX
        var maxX = rect.maxX
        var minY = rect.minY
        var maxY = rect.maxY

        switch corner {
        case .topLeading:
            minX = clamp(rect.minX + dx, lowerBound: 0, upperBound: rect.maxX - minimumWidth)
            minY = clamp(rect.minY + dy, lowerBound: 0, upperBound: rect.maxY - minimumHeight)
        case .topTrailing:
            maxX = clamp(rect.maxX + dx, lowerBound: rect.minX + minimumWidth, upperBound: 1)
            minY = clamp(rect.minY + dy, lowerBound: 0, upperBound: rect.maxY - minimumHeight)
        case .bottomLeading:
            minX = clamp(rect.minX + dx, lowerBound: 0, upperBound: rect.maxX - minimumWidth)
            maxY = clamp(rect.maxY + dy, lowerBound: rect.minY + minimumHeight, upperBound: 1)
        case .bottomTrailing:
            maxX = clamp(rect.maxX + dx, lowerBound: rect.minX + minimumWidth, upperBound: 1)
            maxY = clamp(rect.maxY + dy, lowerBound: rect.minY + minimumHeight, upperBound: 1)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Private Methods

    private static func clamp(_ value: CGFloat, lowerBound: CGFloat, upperBound: CGFloat) -> CGFloat {
        min(max(value, lowerBound), upperBound)
    }
}
