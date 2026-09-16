import SwiftUI

struct RefreshLoaderDemo: View {
    @State private var isRefreshing = false
    @State private var items: [String] = [
        "Aurora over Greenland",
        "Monsoon over India",
        "Trade winds Atlantic",
        "Pacific swell report",
        "Sahara dust plume"
    ]

    let maps: [MapDefinition]
    let config: WorldLoaderConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Refresh control mode")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text("Pull down the list to refresh with the dotted world loader.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            WorldLoaderRefreshContainer(
                isRefreshing: $isRefreshing,
                maps: maps,
                config: config,
                onRefresh: {
                    try? await Task.sleep(nanoseconds: 2_400_000_000)
                    items.shuffle()
                }
            ) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .padding(.vertical, 6)
                }
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}
