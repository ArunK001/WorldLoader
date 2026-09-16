import CoreGraphics
import Foundation

/// Interpolates one dotted map into another with calm, spatially-matched particle motion.
public enum MapMorpher {
    public static func morph(
        from source: [MapDot],
        to destination: [MapDot],
        progress: Double
    ) -> [AnimatedDot] {
        let t = clamp(progress)
        let eased = easeInOut(t)
        guard !source.isEmpty || !destination.isEmpty else { return [] }

        let pairs = paired(from: source, to: destination)
        let scatter = sin(t * .pi)
        var result: [AnimatedDot] = []
        result.reserveCapacity(pairs.count)

        for (index, pair) in pairs.enumerated() {
            let seed = Double((index * 2654435761) & 0xFFFF) / Double(0xFFFF)
            let arc = curved(
                from: pair.from.position,
                to: pair.to.position,
                t: eased,
                seed: seed,
                scatter: scatter * 0.55
            )

            let opacity = pair.opacity(at: eased) * (0.7 + 0.3 * (1 - scatter * 0.25))
            let isBorder = t < 0.5 ? pair.from.isBorder : pair.to.isBorder
            let phase = lerp(pair.from.borderPhase, pair.to.borderPhase, eased)
            let scale = 0.92 + 0.18 * scatter

            result.append(
                AnimatedDot(
                    id: index,
                    position: arc,
                    brightness: 1 + scatter * 0.28,
                    opacity: opacity,
                    isBorder: isBorder,
                    borderPhase: phase,
                    scale: scale
                )
            )
        }

        return result
    }

    public static func staticField(from dots: [MapDot]) -> [AnimatedDot] {
        dots.map {
            AnimatedDot(
                id: $0.id,
                position: $0.position,
                brightness: 1,
                opacity: 1,
                isBorder: $0.isBorder,
                borderPhase: $0.borderPhase,
                scale: 1
            )
        }
    }

    // MARK: - Pairing

    private struct Pair {
        let from: MapDot
        let to: MapDot
        let born: Bool
        let dying: Bool

        func opacity(at t: Double) -> Double {
            if dying { return 1 - t }
            if born { return t }
            return 1
        }
    }

    /// Match by normalized grid order so neighbors move coherently.
    private static func paired(from source: [MapDot], to destination: [MapDot]) -> [Pair] {
        let src = source.sorted(by: spatialSort)
        let dst = destination.sorted(by: spatialSort)
        let count = max(src.count, dst.count)
        guard count > 0 else { return [] }

        var pairs: [Pair] = []
        pairs.reserveCapacity(count)

        for i in 0..<count {
            if i < src.count, i < dst.count {
                pairs.append(Pair(from: src[i], to: dst[i], born: false, dying: false))
            } else if i < src.count {
                let target = dst.isEmpty ? src[i] : dst[i % dst.count]
                pairs.append(Pair(from: src[i], to: target, born: false, dying: true))
            } else {
                let origin = src.isEmpty ? dst[i] : src[i % src.count]
                pairs.append(Pair(from: origin, to: dst[i], born: true, dying: false))
            }
        }
        return pairs
    }

    private static func spatialSort(_ a: MapDot, _ b: MapDot) -> Bool {
        // Morton-ish: sort by coarse row then column for coherent flocks.
        let ay = Int(a.position.y * 64)
        let by = Int(b.position.y * 64)
        if ay != by { return ay < by }
        return a.position.x < b.position.x
    }

    // MARK: - Motion

    private static func curved(
        from: CGPoint,
        to: CGPoint,
        t: Double,
        seed: Double,
        scatter: Double
    ) -> CGPoint {
        let mx = (from.x + to.x) / 2
        let my = (from.y + to.y) / 2
        let dx = to.x - from.x
        let dy = to.y - from.y
        let len = max(0.001, hypot(dx, dy))
        let px = -dy / len
        let py = dx / len
        let wobble = CGFloat(0.04 + 0.10 * scatter) * CGFloat(seed * 2 - 1)

        let control = CGPoint(
            x: mx + px * wobble,
            y: my + py * wobble
        )

        let u = 1 - t
        return CGPoint(
            x: u * u * from.x + 2 * u * t * control.x + t * t * to.x,
            y: u * u * from.y + 2 * u * t * control.y + t * t * to.y
        )
    }

    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private static func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
}
