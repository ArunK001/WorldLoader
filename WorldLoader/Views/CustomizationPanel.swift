import SwiftUI

struct CustomizationPanel: View {
    @Binding var config: WorldLoaderConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Customize")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            colorRow
            shapePicker

            slider("Dot size", value: $config.dotSize, range: 1.5...7)
            slider("Map size", value: $config.mapScale, range: 0.45...1)
            slider("Density", value: $config.dotDensity, range: 0.45...1.6)
            slider("Touch radius", value: $config.touchInfluenceRadius, range: 0.08...0.45)
            doubleSlider("Touch speed", value: $config.touchResponseSpeed, range: 0.05...0.45)
            doubleSlider("Border glow", value: $config.borderGlowDuration, range: 1.5...8)
            doubleSlider("Morph duration", value: $config.morphDuration, range: 0.6...3.5)
            doubleSlider("Morph hold", value: $config.morphHoldDuration, range: 0.8...5)

            Toggle("Auto morph maps", isOn: $config.autoMorph)
                .tint(config.dotColor)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var colorRow: some View {
        HStack(spacing: 14) {
            colorChip("Dots", $config.dotColor)
            colorChip("Glow", $config.glowColor)
            colorChip("Fade", $config.fadedColor)
            colorChip("BG", $config.backgroundColor)
        }
    }

    private func colorChip(_ title: String, _ color: Binding<Color>) -> some View {
        VStack(spacing: 6) {
            ColorPicker(title, selection: color, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 36, height: 36)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var shapePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dot shape")
                .font(.subheadline.weight(.medium))
            Picker("Shape", selection: $config.dotShape) {
                ForEach(DotShape.allCases) { shape in
                    Text(shape.displayName).tag(shape)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func slider(
        _ title: String,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.subheadline)
            Slider(value: value, in: range)
                .tint(config.dotColor)
        }
    }

    private func doubleSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.subheadline)
            Slider(value: value, in: range)
                .tint(config.dotColor)
        }
    }
}
