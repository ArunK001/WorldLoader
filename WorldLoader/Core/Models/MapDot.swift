import CoreGraphics
import Foundation

/// A single sample point in a dotted map field.
public struct MapDot: Identifiable, Hashable, Sendable {
    public let id: Int
    /// Normalized coordinates in 0...1 map space.
    public var position: CGPoint
    /// True when the point sits on (or very near) the silhouette border.
    public var isBorder: Bool
    /// Phase offset used by the border glow animation.
    public var borderPhase: Double

    public init(
        id: Int,
        position: CGPoint,
        isBorder: Bool = false,
        borderPhase: Double = 0
    ) {
        self.id = id
        self.position = position
        self.isBorder = isBorder
        self.borderPhase = borderPhase
    }
}

/// A rendered/interpolated dot used during morph and touch response.
public struct AnimatedDot: Identifiable, Sendable {
    public let id: Int
    public var position: CGPoint
    public var brightness: Double
    public var opacity: Double
    public var isBorder: Bool
    public var borderPhase: Double
    public var scale: Double

    public init(
        id: Int,
        position: CGPoint,
        brightness: Double = 1,
        opacity: Double = 1,
        isBorder: Bool = false,
        borderPhase: Double = 0,
        scale: Double = 1
    ) {
        self.id = id
        self.position = position
        self.brightness = brightness
        self.opacity = opacity
        self.isBorder = isBorder
        self.borderPhase = borderPhase
        self.scale = scale
    }
}
