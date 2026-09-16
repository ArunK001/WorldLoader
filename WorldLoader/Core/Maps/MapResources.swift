import Foundation

/// Curated sources for regenerating map geometry.
public enum MapResources {
    public static let notes = """
    Map geometry (this build)
    =========================

    Silhouettes are generated from Natural Earth 110m Admin 0 Countries
    (public domain) via Tools/generate_maps.py:

      https://www.naturalearthdata.com/
      https://github.com/nvkelso/natural-earth-vector

    Pipeline
    --------
    1. Download ne_110m_admin_0_countries.geojson
    2. Group features by CONTINENT / ADMIN name
    3. Project (regional equirectangular, polar stereo for Antarctica)
    4. Douglas–Peucker simplify + fit to unit square
    5. Write WorldLoader/Resources/Maps/*.json
    6. DotFieldGenerator samples fill + border dots at runtime

    Regenerate after updating source data:

      python3 Tools/generate_maps.py

    Higher detail (optional)
    -----------------------
    - Natural Earth 50m / 10m cultural vectors
    - world-atlas TopoJSON: https://github.com/topojson/world-atlas
    - geojson-countries: https://github.com/matsmiersen/geojson-countries
    - SVG World Map: https://github.com/raphaellepuschitz/SVG-World-Map

    Transform animation reference
    -----------------------------
    Particle scatter → reform morph matches the attached reference video:
    curved mid-path burst, soft bloom, coastline stroke, starfield.
    """
}
