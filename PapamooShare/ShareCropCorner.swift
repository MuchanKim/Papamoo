import SwiftUI

enum ShareCropCorner: CaseIterable, Identifiable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    var id: Self { self }

    func position(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeading:
            CGPoint(x: rect.minX, y: rect.minY)
        case .topTrailing:
            CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeading:
            CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomTrailing:
            CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    var accessibilityLabel: LocalizedStringKey {
        switch self {
        case .topLeading:
            "Top-left selection handle"
        case .topTrailing:
            "Top-right selection handle"
        case .bottomLeading:
            "Bottom-left selection handle"
        case .bottomTrailing:
            "Bottom-right selection handle"
        }
    }
}
