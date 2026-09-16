import SwiftUI

/// Tunable appearance and motion for `WorldLoaderView`.
public struct WorldLoaderConfig: Equatable, Sendable {
    public var dotColor: Color
    public var glowColor: Color
    public var backgroundColor: Color
    public var fadedColor: Color

    public var dotSize: CGFloat
    public var mapScale: CGFloat
    public var dotDensity: CGFloat
    public var dotShape: DotShape

    /// Radius (normalized 0...1) around the finger that brightens.
    public var touchInfluenceRadius: CGFloat
    /// How quickly touch brightness eases in/out.
    public var touchResponseSpeed: Double
    /// Ambient border glow travel duration in seconds.
    public var borderGlowDuration: Double
    /// Duration of map-to-map morph in seconds.
    public var morphDuration: Double
    /// Pause between morphs when auto-cycling.
    public var morphHoldDuration: Double
    /// Whether maps auto-cycle through the configured sequence.
    public var autoMorph: Bool

    public init(
        dotColor: Color = Color.white,
        glowColor: Color = Color.white,
        backgroundColor: Color = Color.black,
        fadedColor: Color = Color(white: 0.45),
        dotSize: CGFloat = 2.2,
        mapScale: CGFloat = 1.0,
        dotDensity: CGFloat = 1.25,
        dotShape: DotShape = .circle,
        touchInfluenceRadius: CGFloat = 0.22,
        touchResponseSpeed: Double = 0.16,
        borderGlowDuration: Double = 4.2,
        morphDuration: Double = 2.2,
        morphHoldDuration: Double = 2.0,
        autoMorph: Bool = true
    ) {
        self.dotColor = dotColor
        self.glowColor = glowColor
        self.backgroundColor = backgroundColor
        self.fadedColor = fadedColor
        self.dotSize = dotSize
        self.mapScale = mapScale
        self.dotDensity = dotDensity
        self.dotShape = dotShape
        self.touchInfluenceRadius = touchInfluenceRadius
        self.touchResponseSpeed = touchResponseSpeed
        self.borderGlowDuration = borderGlowDuration
        self.morphDuration = morphDuration
        self.morphHoldDuration = morphHoldDuration
        self.autoMorph = autoMorph
    }

    public static let `default` = WorldLoaderConfig()
}
