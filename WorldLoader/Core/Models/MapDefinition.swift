import CoreGraphics
import Foundation

/// A named geographic silhouette used by the loader.
public struct MapDefinition: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let category: MapCategory
    /// Closed polygon rings in normalized 0...1 coordinates (outer ring first).
    public let polygons: [[CGPoint]]
    public let source: String

    public init(
        id: String,
        name: String,
        category: MapCategory,
        polygons: [[CGPoint]],
        source: String = "Natural Earth 110m"
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.polygons = polygons
        self.source = source
    }
}

public enum MapCategory: String, CaseIterable, Sendable {
    case continent
    case country
}

// MARK: - Bundle JSON

struct MapJSONDTO: Decodable {
    let id: String
    let name: String
    let category: String
    let source: String?
    let polygons: [[[Double]]]

    func toDefinition() -> MapDefinition {
        let rings: [[CGPoint]] = polygons.map { ring in
            ring.compactMap { pair in
                guard pair.count >= 2 else { return nil }
                return CGPoint(x: pair[0], y: pair[1])
            }
        }.filter { $0.count >= 3 }

        return MapDefinition(
            id: id,
            name: name,
            category: MapCategory(rawValue: category) ?? .country,
            polygons: rings,
            source: source ?? "Natural Earth 110m"
        )
    }
}
