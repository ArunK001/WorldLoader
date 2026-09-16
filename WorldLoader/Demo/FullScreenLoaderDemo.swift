import SwiftUI

struct FullScreenLoaderDemo: View {
    @StateObject private var controller: WorldLoaderController
    @Environment(\.dismiss) private var dismiss

    init(maps: [MapDefinition], config: WorldLoaderConfig) {
        _controller = StateObject(wrappedValue: WorldLoaderController(maps: maps, config: config))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WorldLoaderView(
                controller: controller,
                presentation: .fullScreen,
                showsLabel: true
            )
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(20)
            }
            .accessibilityLabel("Close")
        }
    }
}
