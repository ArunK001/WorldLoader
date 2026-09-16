import SwiftUI

struct ContainerLoaderDemo: View {
    @ObservedObject var controller: WorldLoaderController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Container mode")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            Text("The loader adapts to any parent size — cards, sheets, or inline panels.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            WorldLoaderView(
                controller: controller,
                presentation: .container,
                showsLabel: true
            )
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )

            Text("Touch or swipe the map — nearby dots brighten while distant ones soften.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}
