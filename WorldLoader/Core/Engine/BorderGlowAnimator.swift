import Foundation

/// Travelling highlight along border-phase samples.
public enum BorderGlowAnimator {
    public static func brightness(
        forPhase phase: Double,
        time: Double,
        duration: Double,
        isBorder: Bool
    ) -> Double {
        guard isBorder, duration > 0.01 else { return 1 }
        let cycle = (time / duration).truncatingRemainder(dividingBy: 1)
        var delta = abs(phase - cycle)
        if delta > 0.5 { delta = 1 - delta }

        // Soft travelling arc along the circumference.
        let band = max(0, 1 - delta / 0.12)
        return 1 + band * 1.6
    }
}
