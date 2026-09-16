import CoreGraphics
import Foundation

enum MapLayout {
    /// Square map frame fitted into the view.
    /// Full-screen uses near edge-to-edge sizing.
    static func frame(
        in size: CGSize,
        mapScale: CGFloat,
        presentation: LoaderPresentationStyle
    ) -> (origin: CGPoint, side: CGFloat) {
        let scale: CGFloat
        switch presentation {
        case .fullScreen:
            scale = max(mapScale, 0.98)
        case .container, .refreshControl:
            scale = mapScale
        }

        let side = min(size.width, size.height) * scale
        let origin = CGPoint(
            x: (size.width - side) * 0.5,
            y: (size.height - side) * 0.5
        )
        return (origin, max(side, 1))
    }
}
