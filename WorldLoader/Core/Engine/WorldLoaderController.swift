import CoreGraphics
import Foundation
import SwiftUI

/// Owns map sequence, morph timing, border glow, and touch state.
///
/// Particle frames are exposed via `renderParticles` for the Metal view to read
/// without triggering a SwiftUI body rebuild every frame.
@MainActor
public final class WorldLoaderController: ObservableObject {
    /// GPU-facing particle snapshot (not @Published — updated every display tick).
    public private(set) var renderParticles: [AnimatedDot] = []
    public private(set) var outlineRings: [[CGPoint]] = []
    public private(set) var morphProgress: Double = 0

    @Published public private(set) var activeMapName: String = ""
    @Published public var config: WorldLoaderConfig {
        didSet { rebuildFieldsIfNeeded(old: oldValue) }
    }

    public private(set) var maps: [MapDefinition]
    private var fields: [[MapDot]] = []
    private var mapIndex: Int = 0
    private var nextIndex: Int = 0
    private var phase: Phase = .holding
    private var phaseStartedAt: TimeInterval = Date().timeIntervalSinceReferenceDate
    private var rawTouch: CGPoint?
    private var smoothedTouch: CGPoint?
    private var touchIntensity: Double = 0
    private var lastTick: TimeInterval = Date().timeIntervalSinceReferenceDate
    private var cachedStatic: [AnimatedDot] = []

    private enum Phase {
        case holding
        case morphing
    }

    public init(
        maps: [MapDefinition] = MapCatalog.defaultSequence,
        config: WorldLoaderConfig = .default
    ) {
        let fallback = MapCatalog.defaultSequence.isEmpty ? Array(MapCatalog.all.prefix(1)) : MapCatalog.defaultSequence
        let limited = Array((maps.isEmpty ? fallback : maps).prefix(5))
        self.maps = limited
        self.config = config
        rebuildFields()
        if let first = self.maps.first {
            activeMapName = first.name
            outlineRings = DotFieldGenerator.outlineRings(from: first)
            cachedStatic = fields.first.map(MapMorpher.staticField(from:)) ?? []
            renderParticles = cachedStatic
        }
    }

    // MARK: - Public API

    public func setMaps(_ newMaps: [MapDefinition]) {
        let limited = Array(newMaps.prefix(5))
        guard !limited.isEmpty else { return }
        maps = limited
        mapIndex = 0
        nextIndex = min(1, limited.count - 1)
        phase = .holding
        phaseStartedAt = Date().timeIntervalSinceReferenceDate
        rebuildFields()
        activeMapName = maps[0].name
        outlineRings = DotFieldGenerator.outlineRings(from: maps[0])
        cachedStatic = MapMorpher.staticField(from: fields[0])
        renderParticles = cachedStatic
    }

    public func updateTouch(normalized point: CGPoint?) {
        rawTouch = point
    }

    public func jumpToMap(at index: Int) {
        guard maps.indices.contains(index) else { return }
        mapIndex = index
        nextIndex = (index + 1) % maps.count
        phase = .holding
        phaseStartedAt = Date().timeIntervalSinceReferenceDate
        activeMapName = maps[index].name
        outlineRings = DotFieldGenerator.outlineRings(from: maps[index])
        cachedStatic = MapMorpher.staticField(from: fields[index])
        renderParticles = cachedStatic
    }

    /// Advance simulation — called from the Metal display link.
    public func tick(at date: Date) {
        guard !maps.isEmpty, !fields.isEmpty else { return }

        let now = date.timeIntervalSinceReferenceDate
        let dt = max(0.001, min(0.05, now - lastTick))
        lastTick = now
        let elapsed = now - phaseStartedAt

        let blend = CGFloat(min(1, config.touchResponseSpeed * 12 * dt * 60))
        smoothedTouch = TouchResponseEngine.smoothTouch(
            current: smoothedTouch,
            target: rawTouch,
            amount: max(0.06, blend)
        )
        let targetIntensity: Double = rawTouch == nil ? 0 : 1
        touchIntensity += (targetIntensity - touchIntensity) * min(1, config.touchResponseSpeed * 10 * dt * 60)

        var dots: [AnimatedDot]
        switch phase {
        case .holding:
            morphProgress = 0
            dots = cachedStatic
            if activeMapName != maps[mapIndex].name {
                activeMapName = maps[mapIndex].name
            }
            outlineRings = DotFieldGenerator.outlineRings(from: maps[mapIndex])
            if config.autoMorph, maps.count > 1, elapsed >= config.morphHoldDuration {
                beginMorph(at: now)
            }
        case .morphing:
            let progress = min(1, elapsed / max(config.morphDuration, 0.01))
            morphProgress = progress
            outlineRings = DotFieldGenerator.outlineRings(
                from: progress < 0.5 ? maps[mapIndex] : maps[nextIndex]
            )
            dots = MapMorpher.morph(
                from: fields[mapIndex],
                to: fields[nextIndex],
                progress: progress
            )
            if progress >= 1 {
                mapIndex = nextIndex
                nextIndex = (mapIndex + 1) % maps.count
                phase = .holding
                phaseStartedAt = now
                activeMapName = maps[mapIndex].name
                outlineRings = DotFieldGenerator.outlineRings(from: maps[mapIndex])
                cachedStatic = MapMorpher.staticField(from: fields[mapIndex])
                dots = cachedStatic
            }
        }

        for i in dots.indices {
            let borderBoost = BorderGlowAnimator.brightness(
                forPhase: dots[i].borderPhase,
                time: now,
                duration: config.borderGlowDuration,
                isBorder: dots[i].isBorder
            )
            dots[i].brightness *= borderBoost
        }

        TouchResponseEngine.apply(
            to: &dots,
            touch: smoothedTouch,
            radius: config.touchInfluenceRadius,
            intensity: touchIntensity
        )

        renderParticles = dots
    }

    private func beginMorph(at now: TimeInterval) {
        nextIndex = (mapIndex + 1) % maps.count
        phase = .morphing
        phaseStartedAt = now
    }

    private func rebuildFields() {
        fields = maps.map {
            DotFieldGenerator.generate(from: $0, density: config.dotDensity, maxDots: 1600)
        }
        if maps.indices.contains(mapIndex), fields.indices.contains(mapIndex) {
            cachedStatic = MapMorpher.staticField(from: fields[mapIndex])
            renderParticles = cachedStatic
            outlineRings = DotFieldGenerator.outlineRings(from: maps[mapIndex])
        }
    }

    private func rebuildFieldsIfNeeded(old: WorldLoaderConfig) {
        if old.dotDensity != config.dotDensity {
            rebuildFields()
        }
    }
}
