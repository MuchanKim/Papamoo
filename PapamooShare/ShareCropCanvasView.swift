import SwiftUI

struct ShareCropCanvasView: View {
    let image: UIImage
    @Binding var selection: CGRect

    @State private var moveStart: CGRect?
    @State private var magnifyStart: CGRect?
    @State private var resizeStart: CGRect?
    @State private var activeCorner: ShareCropCorner?

    var body: some View {
        GeometryReader { proxy in
            let imageRect = ShareCropLayout.aspectFitRect(
                imageSize: image.size,
                containerSize: proxy.size
            )
            let selectionRect = ShareCropLayout.displayRect(for: selection, in: imageRect)

            ZStack {
                ShareColor.background

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageRect.width, height: imageRect.height)
                    .position(x: imageRect.midX, y: imageRect.midY)

                Canvas { context, _ in
                    var dimmedArea = Path()
                    dimmedArea.addRect(imageRect)
                    dimmedArea.addRect(selectionRect)
                    context.fill(dimmedArea, with: .color(.black.opacity(0.58)), style: .init(eoFill: true))

                    context.stroke(
                        Path(selectionRect),
                        with: .color(ShareColor.accent),
                        lineWidth: 2
                    )
                }
                .allowsHitTesting(false)

                Rectangle()
                    .fill(.clear)
                    .frame(width: selectionRect.width, height: selectionRect.height)
                    .position(x: selectionRect.midX, y: selectionRect.midY)
                    .contentShape(Rectangle())
                    .gesture(moveGesture(in: imageRect))
                    .simultaneousGesture(scaleGesture)

                ForEach(ShareCropCorner.allCases) { corner in
                    ShareCropHandleView(corner: corner)
                        .position(corner.position(in: selectionRect))
                        .highPriorityGesture(resizeGesture(corner, in: imageRect))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Payment information selection")
        .accessibilityHint("Move the selection or drag a corner to resize it.")
    }

    private func moveGesture(in imageRect: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if moveStart == nil {
                    moveStart = selection
                }
                guard let moveStart else { return }
                selection = ShareCropLayout.moved(moveStart, translation: value.translation, in: imageRect)
            }
            .onEnded { _ in
                moveStart = nil
            }
    }

    private func resizeGesture(_ corner: ShareCropCorner, in imageRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if activeCorner != corner {
                    activeCorner = corner
                    resizeStart = selection
                }
                guard let resizeStart else { return }
                selection = ShareCropLayout.resized(
                    resizeStart,
                    dragging: corner,
                    translation: value.translation,
                    in: imageRect
                )
            }
            .onEnded { _ in
                activeCorner = nil
                resizeStart = nil
            }
    }

    private var scaleGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if magnifyStart == nil {
                    magnifyStart = selection
                }
                guard let magnifyStart else { return }
                selection = ShareCropLayout.scaled(magnifyStart, magnification: value.magnification)
            }
            .onEnded { _ in
                magnifyStart = nil
            }
    }
}
