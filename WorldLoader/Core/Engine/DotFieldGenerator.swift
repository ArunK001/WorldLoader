import CoreGraphics
import Foundation

/// Builds a dotted field (fill + border) from polygon rings.
public enum DotFieldGenerator {
    public static func generate(
        from map: MapDefinition,
        density: CGFloat = 1.0,
        maxDots: Int = 1600
    ) -> [MapDot] {
        let spacing = max(0.012, 0.026 / max(density, 0.35))

        // Tiny islands were producing border/fill dots across the whole canvas.
        // Keep only the largest landmasses for sampling.
        let rings = significantRings(map.polygons, limit: map.category == .continent ? 8 : 6)
        guard !rings.isEmpty else { return [] }

        let paths = rings.map(makePath(from:))
        let bounds = combinedBounds(of: rings)

        var fill: [CGPoint] = []
        fill.reserveCapacity(maxDots)

        var y = bounds.minY + spacing * 0.5
        while y <= bounds.maxY {
            var x = bounds.minX + spacing * 0.5
            while x <= bounds.maxX {
                let point = CGPoint(x: x, y: y)
                if paths.contains(where: { $0.contains(point, using: .winding, transform: .identity) }) {
                    fill.append(point)
                }
                x += spacing
            }
            y += spacing
        }

        // Uniformly thin fill if over budget (keeps shape coverage, avoids top-left bias).
        let borderBudget = min(420, maxDots / 3)
        let fillBudget = max(0, maxDots - borderBudget)
        if fill.count > fillBudget, fillBudget > 0 {
            let step = Double(fill.count) / Double(fillBudget)
            var thinned: [CGPoint] = []
            thinned.reserveCapacity(fillBudget)
            var cursor = 0.0
            while thinned.count < fillBudget, Int(cursor) < fill.count {
                thinned.append(fill[Int(cursor)])
                cursor += step
            }
            fill = thinned
        }

        var border: [CGPoint] = []
        for ring in rings {
            border.append(contentsOf: sampleBorder(ring: ring, spacing: spacing * 0.55))
        }
        if border.count > borderBudget, borderBudget > 0 {
            let step = Double(border.count) / Double(borderBudget)
            var thinned: [CGPoint] = []
            var cursor = 0.0
            while thinned.count < borderBudget, Int(cursor) < border.count {
                thinned.append(border[Int(cursor)])
                cursor += step
            }
            border = thinned
        }

        var dots: [MapDot] = []
        dots.reserveCapacity(fill.count + border.count)

        for (index, point) in fill.enumerated() {
            dots.append(MapDot(id: index, position: point, isBorder: false, borderPhase: 0))
        }

        let borderStart = dots.count
        let borderCount = max(border.count, 1)
        for (offset, point) in border.enumerated() {
            dots.append(
                MapDot(
                    id: borderStart + offset,
                    position: point,
                    isBorder: true,
                    borderPhase: Double(offset) / Double(borderCount)
                )
            )
        }

        return dots
    }

    /// Rings used for coastline stroke (shared with the controller).
    public static func outlineRings(from map: MapDefinition, limit: Int = 8) -> [[CGPoint]] {
        significantRings(map.polygons, limit: limit)
    }

    // MARK: - Geometry

    private static func significantRings(_ rings: [[CGPoint]], limit: Int) -> [[CGPoint]] {
        let cleaned = rings
            .map(sanitizeRing)
            .filter { $0.count >= 4 }

        let scored = cleaned.map { ring -> (CGFloat, [CGPoint]) in
            (approxArea(ring), ring)
        }
        .sorted { $0.0 > $1.0 }

        guard let largest = scored.first?.0, largest > 0 else {
            return Array(cleaned.prefix(limit))
        }

        // Drop scraps smaller than ~0.4% of the main landmass.
        let kept = scored.filter { $0.0 >= largest * 0.004 }.prefix(limit)
        return kept.map(\.1)
    }

    private static func sanitizeRing(_ ring: [CGPoint]) -> [CGPoint] {
        var result: [CGPoint] = []
        result.reserveCapacity(ring.count)
        for point in ring {
            if let last = result.last, hypot(last.x - point.x, last.y - point.y) < 0.00015 {
                continue
            }
            result.append(point)
        }
        if let first = result.first, let last = result.last, first != last {
            result.append(first)
        }
        return result
    }

    private static func approxArea(_ ring: [CGPoint]) -> CGFloat {
        guard ring.count >= 3 else { return 0 }
        var sum: CGFloat = 0
        for i in 0..<(ring.count - 1) {
            let a = ring[i]
            let b = ring[i + 1]
            sum += a.x * b.y - b.x * a.y
        }
        return abs(sum) * 0.5
    }

    private static func makePath(from ring: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard let first = ring.first else { return path }
        path.move(to: first)
        for point in ring.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    private static func combinedBounds(of rings: [[CGPoint]]) -> CGRect {
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        for ring in rings {
            for p in ring {
                minX = min(minX, p.x)
                minY = min(minY, p.y)
                maxX = max(maxX, p.x)
                maxY = max(maxY, p.y)
            }
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private static func sampleBorder(ring: [CGPoint], spacing: CGFloat) -> [CGPoint] {
        guard ring.count >= 2 else { return ring }
        var samples: [CGPoint] = []
        for i in 0..<(ring.count - 1) {
            let a = ring[i]
            let b = ring[i + 1]
            let dx = b.x - a.x
            let dy = b.y - a.y
            let length = hypot(dx, dy)
            let steps = max(1, Int(ceil(length / spacing)))
            for step in 0..<steps {
                let t = CGFloat(step) / CGFloat(steps)
                samples.append(CGPoint(x: a.x + dx * t, y: a.y + dy * t))
            }
        }
        return samples
    }
}
