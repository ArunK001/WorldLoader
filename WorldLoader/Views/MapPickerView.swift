import SwiftUI

struct MapPickerView: View {
    let available: [MapDefinition]
    @Binding var selectedIDs: [String]
    let accent: Color

    private let maxMaps = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Maps in loader")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(selectedIDs.count)/\(maxMaps)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text("Pick up to 5 maps. Order is morph order (map1 → map2 → …).")
                .font(.footnote)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(available) { map in
                    mapChip(map)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func mapChip(_ map: MapDefinition) -> some View {
        let selected = selectedIDs.contains(map.id)
        let index = selectedIDs.firstIndex(of: map.id)

        return Button {
            toggle(map.id)
        } label: {
            HStack(spacing: 8) {
                if let index {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(accent.opacity(0.9)))
                        .foregroundStyle(.black)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(map.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(map.category.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? accent.opacity(0.18) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(selected ? accent.opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ id: String) {
        if let index = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: index)
        } else if selectedIDs.count < maxMaps {
            selectedIDs.append(id)
        }
    }
}
