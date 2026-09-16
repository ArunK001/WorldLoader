import Foundation

/// How `WorldLoaderView` is embedded in a host UI.
public enum LoaderPresentationStyle: String, CaseIterable, Identifiable, Sendable {
    case fullScreen
    case container
    case refreshControl

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fullScreen: return "Full Screen"
        case .container: return "Container"
        case .refreshControl: return "Refresh Control"
        }
    }

    public var detail: String {
        switch self {
        case .fullScreen:
            return "Covers the entire screen while content loads."
        case .container:
            return "Lives inside any sized parent view or card."
        case .refreshControl:
            return "Acts as a pull-to-refresh indicator."
        }
    }
}
