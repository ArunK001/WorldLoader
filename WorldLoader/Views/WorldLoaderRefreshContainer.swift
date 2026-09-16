import SwiftUI
import UIKit

/// Pull-to-refresh style wrapper that shows `WorldLoaderView` while refreshing.
public struct WorldLoaderRefreshContainer<Content: View>: View {
    @Binding var isRefreshing: Bool
    let maps: [MapDefinition]
    let config: WorldLoaderConfig
    let content: Content
    let onRefresh: () async -> Void

    @StateObject private var controller: WorldLoaderController

    public init(
        isRefreshing: Binding<Bool>,
        maps: [MapDefinition] = MapCatalog.defaultSequence,
        config: WorldLoaderConfig = .default,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self._isRefreshing = isRefreshing
        self.maps = Array(maps.prefix(5))
        self.config = config
        self.onRefresh = onRefresh
        self.content = content()
        _controller = StateObject(
            wrappedValue: WorldLoaderController(maps: Array(maps.prefix(5)), config: config)
        )
    }

    public var body: some View {
        List {
            if isRefreshing {
                WorldLoaderView(
                    controller: controller,
                    presentation: .refreshControl,
                    showsLabel: true
                )
                .frame(height: 140)
                .listRowInsets(EdgeInsets())
                .listRowBackground(config.backgroundColor)
                .listRowSeparator(.hidden)
            }

            content
        }
        .listStyle(.plain)
        .refreshable {
            isRefreshing = true
            await onRefresh()
            isRefreshing = false
        }
        .onChange(of: config) { _, newValue in
            controller.config = newValue
        }
    }
}
