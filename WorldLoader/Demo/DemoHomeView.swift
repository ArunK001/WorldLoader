import SwiftUI

struct DemoHomeView: View {
    @StateObject private var controller = WorldLoaderController(
        maps: MapCatalog.defaultSequence,
        config: .default
    )
    @State private var config = WorldLoaderConfig.default
    @State private var selectedMapIDs: [String] = MapCatalog.defaultSequence.map(\.id)
    @State private var showFullScreen = false
    @State private var showResources = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero

                    ContainerLoaderDemo(controller: controller)

                    presentationButtons

                    MapPickerView(
                        available: MapCatalog.all,
                        selectedIDs: $selectedMapIDs,
                        accent: config.dotColor
                    )

                    CustomizationPanel(config: $config)

                    RefreshLoaderDemo(
                        maps: selectedMaps,
                        config: config
                    )

                    resourcesCard
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(atmosphere.ignoresSafeArea())
            .navigationTitle("World Loader")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Resources") { showResources = true }
                }
            }
            .sheet(isPresented: $showResources) {
                NavigationStack {
                    ScrollView {
                        Text(MapResources.notes)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .navigationTitle("Map Resources")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showResources = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenLoaderDemo(maps: selectedMaps, config: config)
            }
            .onChange(of: config) { _, newValue in
                controller.config = newValue
            }
            .onChange(of: selectedMapIDs) { _, _ in
                applySelectedMaps()
            }
            .onAppear {
                controller.config = config
                applySelectedMaps()
            }
        }
    }

    private var selectedMaps: [MapDefinition] {
        selectedMapIDs.compactMap(MapCatalog.map(id:))
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dotted continents that respond to touch")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Morph up to five maps, tune colors and shapes, and embed as full screen, container, or refresh control.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var presentationButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presentation styles")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            ForEach(LoaderPresentationStyle.allCases) { style in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon(for: style))
                        .font(.title3)
                        .foregroundStyle(config.dotColor)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(style.displayName)
                            .font(.subheadline.weight(.semibold))
                        Text(style.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if style == .fullScreen {
                        Button("Open") { showFullScreen = true }
                            .buttonStyle(.borderedProminent)
                            .tint(config.dotColor)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var resourcesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exact map geometry")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text("This demo uses simplified silhouettes. Swap in Natural Earth / GeoJSON rings for cartographic accuracy — see Resources.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("View map data sources") { showResources = true }
                .buttonStyle(.bordered)
                .tint(config.dotColor)
                .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var atmosphere: some View {
        Color.black
    }

    private func icon(for style: LoaderPresentationStyle) -> String {
        switch style {
        case .fullScreen: return "rectangle.fill"
        case .container: return "rectangle.inset.filled"
        case .refreshControl: return "arrow.clockwise.circle"
        }
    }

    private func applySelectedMaps() {
        let maps = selectedMaps
        guard !maps.isEmpty else { return }
        controller.setMaps(maps)
    }
}

#Preview {
    DemoHomeView()
        .preferredColorScheme(.dark)
}
