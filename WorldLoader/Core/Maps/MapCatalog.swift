import Foundation

/// Catalog of Natural Earth–derived maps shipped with the demo.
public enum MapCatalog {
    public static let allContinents: [MapDefinition] = loadMany([
        "africa", "asia", "europe", "north-america",
        "south-america", "australia", "antarctica"
    ])

    /// Top countries by land area, plus India (featured in the reference animation).
    public static let topCountries: [MapDefinition] = loadMany([
        "russia", "canada", "china", "united-states",
        "brazil", "india", "australia-country"
    ])

    public static let all: [MapDefinition] = allContinents + topCountries

    public static func map(id: String) -> MapDefinition? {
        all.first { $0.id == id }
    }

    /// Default demo sequence — mirrors the reference video's country morph feel.
    public static let defaultSequence: [MapDefinition] = [
        map(id: "india"),
        map(id: "australia-country"),
        map(id: "africa"),
        map(id: "united-states"),
        map(id: "brazil")
    ].compactMap { $0 }

    // MARK: - Loading

    private static func loadMany(_ ids: [String]) -> [MapDefinition] {
        ids.compactMap { load(id: $0) }
    }

    private static func load(id: String) -> MapDefinition? {
        let url =
            Bundle.main.url(forResource: id, withExtension: "json", subdirectory: "Maps")
            ?? Bundle.main.url(forResource: id, withExtension: "json", subdirectory: "Resources/Maps")
            ?? Bundle.main.url(forResource: id, withExtension: "json")

        guard let url else {
            assertionFailure("Missing map JSON for \(id)")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(MapJSONDTO.self, from: data).toDefinition()
        } catch {
            assertionFailure("Failed to decode \(id): \(error)")
            return nil
        }
    }
}
