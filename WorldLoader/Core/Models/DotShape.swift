import SwiftUI

/// Visual shape used to render each map sample point.
public enum DotShape: String, CaseIterable, Identifiable, Sendable {
    case circle
    case square
    case triangle

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .square: return "Square"
        case .triangle: return "Triangle"
        }
    }
}
