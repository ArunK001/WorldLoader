import SwiftUI

/// Primary dotted world loader (Metal-backed particles).
///
/// Supports full-screen, in-container, and refresh-control embeddings.
public struct WorldLoaderView: View {
    @ObservedObject private var controller: WorldLoaderController
    private let showsLabel: Bool
    private let presentation: LoaderPresentationStyle

    public init(
        controller: WorldLoaderController,
        presentation: LoaderPresentationStyle = .container,
        showsLabel: Bool = true
    ) {
        self.controller = controller
        self.presentation = presentation
        self.showsLabel = showsLabel
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                controller.config.backgroundColor

                MetalDotView(
                    controller: controller,
                    presentation: presentation
                )
                .allowsHitTesting(true)

                if showsLabel {
                    VStack {
                        Spacer()
                        labelStack
                            .padding(.bottom, presentation == .refreshControl ? 10 : (presentation == .fullScreen ? 48 : 28))
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(controller.config.backgroundColor)
        .modifier(SafeAreaIgnorer(enabled: presentation == .fullScreen))
    }

    private var labelStack: some View {
        VStack(spacing: 6) {
            Text(controller.activeMapName)
                .font(.system(size: presentation == .refreshControl ? 12 : 15, weight: .medium, design: .rounded))
                .foregroundStyle(controller.config.glowColor.opacity(0.9))
        }
    }
}

private struct SafeAreaIgnorer: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content.ignoresSafeArea()
        } else {
            content
        }
    }
}

// MARK: - Convenience factories

public extension WorldLoaderView {
    static func fullScreen(
        maps: [MapDefinition] = MapCatalog.defaultSequence,
        config: WorldLoaderConfig = .default
    ) -> some View {
        WorldLoaderHost(
            maps: maps,
            config: config,
            presentation: .fullScreen,
            showsLabel: true
        )
    }

    static func container(
        maps: [MapDefinition] = MapCatalog.defaultSequence,
        config: WorldLoaderConfig = .default
    ) -> some View {
        WorldLoaderHost(
            maps: maps,
            config: config,
            presentation: .container,
            showsLabel: true
        )
    }
}

private struct WorldLoaderHost: View {
    @StateObject private var controller: WorldLoaderController
    let presentation: LoaderPresentationStyle
    let showsLabel: Bool

    init(
        maps: [MapDefinition],
        config: WorldLoaderConfig,
        presentation: LoaderPresentationStyle,
        showsLabel: Bool
    ) {
        _controller = StateObject(wrappedValue: WorldLoaderController(maps: maps, config: config))
        self.presentation = presentation
        self.showsLabel = showsLabel
    }

    var body: some View {
        WorldLoaderView(
            controller: controller,
            presentation: presentation,
            showsLabel: showsLabel
        )
    }
}
