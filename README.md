# World Loader

SwiftUI iOS demo of a dotted continent/country loader with touch response, border glow, and particle morphing.

Maps are generated from **Natural Earth 110m Admin 0** (public domain), not hand-drawn shapes.

## Open

```bash
open WorldLoader.xcodeproj
```

Requires **Xcode 15+** / **iOS 17+**.

## Accuracy + morph

- Coastlines from Natural Earth GeoJSON → `WorldLoader/Resources/Maps/*.json`
- Continuous glowing outline + interior dot grid (reference-video look)
- Particle **scatter → reform** morph with curved mid-paths
- Soft bloom, starfield, white-on-black defaults
- Demo sequence: India → Australia → Africa → United States → Brazil

## Regenerate maps

```bash
# Source: Tools/mapdata/ne_110m_admin_0_countries.geojson
python3 Tools/generate_maps.py
python3 scripts/generate_pbxproj.py   # if new JSON files were added
```

## Usage

```swift
let controller = WorldLoaderController(
    maps: [
        MapCatalog.map(id: "india")!,
        MapCatalog.map(id: "australia-country")!,
        MapCatalog.map(id: "africa")!
    ],
    config: .default
)

WorldLoaderView(controller: controller, presentation: .container)
```

## Included maps

**Continents:** Africa, Asia, Europe, North America, South America, Australia (Oceania), Antarctica

**Countries:** Russia, Canada, China, United States, Brazil, India, Australia

## Data sources

| Resource | Link |
| --- | --- |
| Natural Earth | https://www.naturalearthdata.com/ |
| NE vector (GeoJSON) | https://github.com/nvkelso/natural-earth-vector |
| world-atlas | https://github.com/topojson/world-atlas |
| geojson-countries | https://github.com/matsmiersen/geojson-countries |

See in-app **Resources** and `MapResources.swift`.
