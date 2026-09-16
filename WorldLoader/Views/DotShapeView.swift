import SwiftUI

/// Draws a single map sample using the configured shape.
struct DotShapeView: View {
    let shape: DotShape
    let size: CGFloat
    let color: Color

    var body: some View {
        switch shape {
        case .circle:
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        case .square:
            RoundedRectangle(cornerRadius: size * 0.15, style: .continuous)
                .fill(color)
                .frame(width: size, height: size)
        case .triangle:
            Triangle()
                .fill(color)
                .frame(width: size * 1.15, height: size * 1.05)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
