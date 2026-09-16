import Metal
import MetalKit
import QuartzCore
import SwiftUI
import UIKit

// MARK: - GPU particle structs (must match ParticleShaders.metal)

struct MetalParticle {
    var position: SIMD2<Float>
    var brightness: Float
    var opacity: Float
    var scale: Float
    var shape: Float
}

struct MetalUniforms {
    var viewport: SIMD2<Float>
    var origin: SIMD2<Float>
    var side: Float
    var dotSize: Float
    var dotColor: SIMD4<Float>
    var glowColor: SIMD4<Float>
    var fadedColor: SIMD4<Float>
    var background: SIMD4<Float>
    var time: Float
}

struct MetalLineVertex {
    var position: SIMD2<Float>
}

// MARK: - SwiftUI wrapper

struct MetalDotView: UIViewRepresentable {
    @ObservedObject var controller: WorldLoaderController
    let presentation: LoaderPresentationStyle

    func makeUIView(context: Context) -> MetalDotMTKView {
        let view = MetalDotMTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.controller = controller
        view.presentation = presentation
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        view.framebufferOnly = true
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.delegate = context.coordinator
        context.coordinator.attach(view: view)
        return view
    }

    func updateUIView(_ uiView: MetalDotMTKView, context: Context) {
        uiView.controller = controller
        uiView.presentation = presentation
        context.coordinator.applyClearColor(from: controller.config)
    }

    func makeCoordinator() -> MetalDotRenderer {
        MetalDotRenderer()
    }
}

final class MetalDotMTKView: MTKView {
    weak var controller: WorldLoaderController?
    var presentation: LoaderPresentationStyle = .container

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        isMultipleTouchEnabled = true
        isOpaque = true
        backgroundColor = .black
        colorPixelFormat = .bgra8Unorm
        sampleCount = 1
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func normalizedTouch(at location: CGPoint) -> CGPoint? {
        guard let controller else { return nil }
        let layout = MapLayout.frame(
            in: bounds.size,
            mapScale: controller.config.mapScale,
            presentation: presentation
        )
        guard layout.side > 0 else { return nil }
        return CGPoint(
            x: (location.x - layout.origin.x) / layout.side,
            y: (location.y - layout.origin.y) / layout.side
        )
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first.map({ normalizedTouch(at: $0.location(in: self)) }) ?? nil {
            controller?.updateTouch(normalized: point)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first.map({ normalizedTouch(at: $0.location(in: self)) }) ?? nil {
            controller?.updateTouch(normalized: point)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        controller?.updateTouch(normalized: nil)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        controller?.updateTouch(normalized: nil)
    }
}

// MARK: - Renderer

final class MetalDotRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice!
    private var queue: MTLCommandQueue!
    private var particlePipeline: MTLRenderPipelineState!
    private var linePipeline: MTLRenderPipelineState!
    private var particleBuffer: MTLBuffer?
    private var lineBuffer: MTLBuffer?
    private var particleCount = 0
    private var particleAlloc = 0
    private var lineCount = 0
    private var lineAlloc = 0
    private weak var view: MetalDotMTKView?

    func attach(view: MetalDotMTKView) {
        self.view = view
        guard let device = view.device else { return }
        self.device = device
        queue = device.makeCommandQueue()
        buildPipelines(view: view)
    }

    func applyClearColor(from config: WorldLoaderConfig) {
        guard let view else { return }
        let c = UIColor(config.backgroundColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        view.clearColor = MTLClearColor(red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
    }

    private func buildPipelines(view: MTKView) {
        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: ParticleShaderSource.code, options: nil)
        } catch {
            assertionFailure("Metal runtime compile failed: \(error)")
            return
        }

        let particleDesc = MTLRenderPipelineDescriptor()
        particleDesc.vertexFunction = library.makeFunction(name: "particle_vertex")
        particleDesc.fragmentFunction = library.makeFunction(name: "particle_fragment")
        particleDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        particleDesc.colorAttachments[0].isBlendingEnabled = true
        particleDesc.colorAttachments[0].rgbBlendOperation = .add
        particleDesc.colorAttachments[0].alphaBlendOperation = .add
        particleDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        particleDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        particleDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        particleDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        let lineDesc = MTLRenderPipelineDescriptor()
        lineDesc.vertexFunction = library.makeFunction(name: "line_vertex")
        lineDesc.fragmentFunction = library.makeFunction(name: "line_fragment")
        lineDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        lineDesc.colorAttachments[0].isBlendingEnabled = true
        lineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        lineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        lineDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        lineDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            particlePipeline = try device.makeRenderPipelineState(descriptor: particleDesc)
            linePipeline = try device.makeRenderPipelineState(descriptor: lineDesc)
        } catch {
            assertionFailure("Metal pipeline error: \(error)")
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let metalView = view as? MetalDotMTKView,
            let controller = metalView.controller,
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = queue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
            particlePipeline != nil
        else { return }

        // Drive simulation on the display link (Metal frame), not SwiftUI TimelineView.
        controller.tick(at: Date())

        let size = view.drawableSize
        // drawableSize is in pixels; touch/layout uses points — convert.
        let scale = view.contentScaleFactor
        let pointSize = CGSize(width: size.width / scale, height: size.height / scale)
        let layout = MapLayout.frame(
            in: pointSize,
            mapScale: controller.config.mapScale,
            presentation: metalView.presentation
        )

        var uniforms = makeUniforms(
            config: controller.config,
            viewportPixels: size,
            originPoints: layout.origin,
            sidePoints: layout.side,
            scale: Float(scale)
        )

        uploadParticles(controller.renderParticles, shape: controller.config.dotShape)
        uploadOutline(controller.outlineRings, morphProgress: controller.morphProgress)

        encoder.setRenderPipelineState(linePipeline)
        if let lineBuffer, lineCount > 0 {
            encoder.setVertexBuffer(lineBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: lineCount)
        }

        encoder.setRenderPipelineState(particlePipeline)
        if let particleBuffer, particleCount > 0 {
            encoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func makeUniforms(
        config: WorldLoaderConfig,
        viewportPixels: CGSize,
        originPoints: CGPoint,
        sidePoints: CGFloat,
        scale: Float
    ) -> MetalUniforms {
        MetalUniforms(
            viewport: SIMD2(Float(viewportPixels.width), Float(viewportPixels.height)),
            origin: SIMD2(Float(originPoints.x) * scale, Float(originPoints.y) * scale),
            side: Float(sidePoints) * scale,
            dotSize: Float(config.dotSize) * scale,
            dotColor: simdColor(config.dotColor),
            glowColor: simdColor(config.glowColor),
            fadedColor: simdColor(config.fadedColor),
            background: simdColor(config.backgroundColor),
            time: Float(CACurrentMediaTime())
        )
    }

    private func simdColor(_ color: Color) -> SIMD4<Float> {
        let c = UIColor(color)
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD4(Float(r), Float(g), Float(b), Float(a))
    }

    private func uploadParticles(_ dots: [AnimatedDot], shape: DotShape) {
        let shapeValue: Float
        switch shape {
        case .circle: shapeValue = 0
        case .square: shapeValue = 1
        case .triangle: shapeValue = 2
        }

        let count = dots.count
        if particleBuffer == nil || particleAlloc < count {
            particleAlloc = max(count, 64)
            particleBuffer = device.makeBuffer(
                length: MemoryLayout<MetalParticle>.stride * particleAlloc,
                options: .storageModeShared
            )
        }
        guard let particleBuffer else {
            particleCount = 0
            return
        }
        let ptr = particleBuffer.contents().bindMemory(to: MetalParticle.self, capacity: particleAlloc)
        for i in 0..<count {
            let d = dots[i]
            ptr[i] = MetalParticle(
                position: SIMD2(Float(d.position.x), Float(d.position.y)),
                brightness: Float(d.brightness),
                opacity: Float(d.opacity),
                scale: Float(d.scale),
                shape: shapeValue
            )
        }
        particleCount = count
    }

    private func uploadOutline(_ rings: [[CGPoint]], morphProgress: Double) {
        let opacity = max(0, 1 - morphProgress * 1.4)
        guard opacity > 0.05 else {
            lineCount = 0
            return
        }

        var vertices: [MetalLineVertex] = []
        for ring in rings {
            guard ring.count >= 2 else { continue }
            for i in 0..<(ring.count - 1) {
                let a = ring[i]
                let b = ring[i + 1]
                vertices.append(MetalLineVertex(position: SIMD2(Float(a.x), Float(a.y))))
                vertices.append(MetalLineVertex(position: SIMD2(Float(b.x), Float(b.y))))
            }
        }

        let count = vertices.count
        if lineBuffer == nil || lineAlloc < count {
            lineAlloc = max(count, 64)
            lineBuffer = device.makeBuffer(
                length: MemoryLayout<MetalLineVertex>.stride * lineAlloc,
                options: .storageModeShared
            )
        }
        guard let lineBuffer, count > 0 else {
            lineCount = 0
            return
        }
        let ptr = lineBuffer.contents().bindMemory(to: MetalLineVertex.self, capacity: lineAlloc)
        for i in 0..<count {
            ptr[i] = vertices[i]
        }
        lineCount = count

        // Bake outline opacity into a side channel by scaling via uniforms.dotColor alpha at draw time —
        // already handled by morph fade of rings selection. Keep lines fully opaque while visible.
        _ = opacity
    }
}