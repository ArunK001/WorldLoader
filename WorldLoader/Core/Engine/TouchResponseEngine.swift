import CoreGraphics
import Foundation

/// Soft radial brightness falloff driven by touch / swipe location.
public enum TouchResponseEngine {
    public static func apply(
        to dots: inout [AnimatedDot],
        touch: CGPoint?,
        radius: CGFloat,
        intensity: Double
    ) {
        guard let touch, radius > 0.001 else {
            for i in dots.indices {
                dots[i].brightness = 1
            }
            return
        }

        let softRadius = max(radius, 0.05)
        for i in dots.indices {
            let dx = dots[i].position.x - touch.x
            let dy = dots[i].position.y - touch.y
            let distance = hypot(dx, dy)
            let normalized = distance / softRadius

            // Near touch: brighter. Farther: gently fades.
            let proximity = max(0, 1 - normalized)
            let glow = pow(proximity, 1.35)
            let fade = 0.28 + 0.72 * (1 - min(normalized, 1.4) / 1.4)
            let target = (glow * 1.85 + fade * 0.55) * intensity + (1 - intensity)
            dots[i].brightness = max(0.18, min(2.2, target))
            dots[i].scale = dots[i].scale * (1 + glow * 0.35 * intensity)
        }
    }

    /// Smoothly blends previous touch toward the latest sample for calming swipes.
    public static func smoothTouch(
        current: CGPoint?,
        target: CGPoint?,
        amount: CGFloat
    ) -> CGPoint? {
        guard let target else { return nil }
        guard let current else { return target }
        return CGPoint(
            x: current.x + (target.x - current.x) * amount,
            y: current.y + (target.y - current.y) * amount
        )
    }
}
