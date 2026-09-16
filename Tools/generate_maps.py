#!/usr/bin/env python3
"""
Generate normalized map rings from Natural Earth 110m Admin 0 countries.

Outputs JSON consumed by the WorldLoader iOS app:
  WorldLoader/Resources/Maps/*.json
"""

from __future__ import annotations

import json
import math
import os
from collections import defaultdict
from typing import Iterable

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC = os.path.join(ROOT, "Tools", "mapdata", "ne_110m_admin_0_countries.geojson")
OUT_DIR = os.path.join(ROOT, "WorldLoader", "Resources", "Maps")

# Douglas–Peucker tolerance in projected degrees (pre-fit). Higher = fewer points.
SIMPLIFY_EPS = {
    "continent": 0.35,
    "country": 0.18,
}

# Drop tiny islands below this fraction of the region's bbox area.
MIN_RING_AREA_FRAC = 0.0008
PADDING = 0.06
MAX_VERTICES_PER_RING = 280


def ring_area(ring: list[tuple[float, float]]) -> float:
    a = 0.0
    n = len(ring)
    for i in range(n):
        x1, y1 = ring[i]
        x2, y2 = ring[(i + 1) % n]
        a += x1 * y2 - x2 * y1
    return abs(a) * 0.5


def douglas_peucker(points: list[tuple[float, float]], eps: float) -> list[tuple[float, float]]:
    if len(points) < 3:
        return points

    def perp_dist(p, a, b):
        ax, ay = a
        bx, by = b
        px, py = p
        dx, dy = bx - ax, by - ay
        if dx == 0 and dy == 0:
            return math.hypot(px - ax, py - ay)
        t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
        t = max(0.0, min(1.0, t))
        return math.hypot(px - (ax + t * dx), py - (ay + t * dy))

    def rec(pts):
        if len(pts) < 3:
            return pts
        a, b = pts[0], pts[-1]
        idx, dmax = 0, 0.0
        for i in range(1, len(pts) - 1):
            d = perp_dist(pts[i], a, b)
            if d > dmax:
                idx, dmax = i, d
        if dmax > eps:
            left = rec(pts[: idx + 1])
            right = rec(pts[idx:])
            return left[:-1] + right
        return [a, b]

    # Keep closed rings closed
    closed = points[0] == points[-1]
    core = points[:-1] if closed else points
    simplified = rec(core)
    if closed:
        if simplified[0] != simplified[-1]:
            simplified = simplified + [simplified[0]]
    return simplified


def extract_rings(geom) -> list[list[tuple[float, float]]]:
    rings: list[list[tuple[float, float]]] = []
    gtype = geom["type"]
    coords = geom["coordinates"]
    if gtype == "Polygon":
        polys = [coords]
    elif gtype == "MultiPolygon":
        polys = coords
    else:
        return rings
    for poly in polys:
        if not poly:
            continue
        # Outer ring only (index 0); skip holes for dotted fill simplicity.
        outer = poly[0]
        ring = [(float(x), float(y)) for x, y in outer]
        if len(ring) >= 4:
            rings.append(ring)
    return rings


def project(lon: float, lat: float, mode: str = "equirect", center: tuple[float, float] | None = None) -> tuple[float, float]:
    if mode == "polar_stereo":
        # South-polar stereographic (Antarctica). Clamp away from the pole singularity.
        lat = max(lat, -89.5)
        lon_rad = math.radians(lon)
        rho = math.tan(math.pi / 4 - math.radians(lat) / 2)
        x = rho * math.sin(lon_rad)
        y = -rho * math.cos(lon_rad)
        return x, y

    if mode == "regional" and center is not None:
        clon, clat = center
        # Unwrap longitudes near the antimeridian relative to center.
        dlon = lon - clon
        while dlon > 180:
            dlon -= 360
        while dlon < -180:
            dlon += 360
        x = dlon * math.cos(math.radians(clat))
        y = -(lat - clat)
        return x, y

    return lon, -lat


def ring_centroid(rings: list[list[tuple[float, float]]]) -> tuple[float, float]:
    xs = [p[0] for r in rings for p in r]
    ys = [p[1] for r in rings for p in r]
    return (sum(xs) / len(xs), sum(ys) / len(ys))


def fit_rings(rings: list[list[tuple[float, float]]], padding: float = PADDING):
    xs = [p[0] for r in rings for p in r]
    ys = [p[1] for r in rings for p in r]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    w = max(max_x - min_x, 1e-6)
    h = max(max_y - min_y, 1e-6)
    side = max(w, h)
    ox = min_x - (side - w) / 2
    oy = min_y - (side - h) / 2
    usable = 1.0 - 2 * padding

    def norm(p):
        x = padding + (p[0] - ox) / side * usable
        y = padding + (p[1] - oy) / side * usable
        return (round(x, 5), round(y, 5))

    return [[norm(p) for p in r] for r in rings]


def prepare_rings(raw_rings: list[list[tuple[float, float]]], kind: str, map_id: str = ""):
    if not raw_rings:
        return []

    # Antarctica NE polygons include spokes to the south pole — clip those away.
    if map_id == "antarctica":
        clipped = []
        for ring in raw_rings:
            pts = [(lon, lat) for lon, lat in ring if lat >= -84.5]
            if len(pts) >= 4:
                if pts[0] != pts[-1]:
                    pts.append(pts[0])
                clipped.append(pts)
        raw_rings = clipped

    mode = "equirect"
    center = None
    if map_id == "antarctica":
        mode = "polar_stereo"
    elif kind == "country" or map_id in {"europe", "russia", "asia", "north-america"}:
        center = ring_centroid(raw_rings)
        mode = "regional"

    projected = [[project(x, y, mode=mode, center=center) for x, y in r] for r in raw_rings]
    areas = [ring_area(r) for r in projected]
    if not areas:
        return []
    max_a = max(areas)
    frac = MIN_RING_AREA_FRAC if kind == "continent" else MIN_RING_AREA_FRAC * 0.35
    kept = [r for r, a in zip(projected, areas) if a >= max_a * frac]
    eps = SIMPLIFY_EPS[kind]
    simplified = []
    for r in kept:
        s = douglas_peucker(r, eps)
        if len(s) > MAX_VERTICES_PER_RING:
            step = max(1, len(s) // MAX_VERTICES_PER_RING)
            s = s[::step]
            if s[0] != s[-1]:
                s.append(s[0])
        if len(s) >= 4:
            simplified.append(s)
    return fit_rings(simplified)


def to_json_rings(rings):
    return [[[p[0], p[1]] for p in r] for r in rings]


def main():
    with open(SRC) as f:
        geo = json.load(f)

    by_continent: dict[str, list] = defaultdict(list)
    by_name: dict[str, object] = {}

    for feat in geo["features"]:
        props = feat["properties"]
        name = props.get("ADMIN") or props.get("NAME")
        continent = props.get("CONTINENT")
        if continent and continent not in ("Seven seas (open ocean)",):
            by_continent[continent].extend(extract_rings(feat["geometry"]))
        if name:
            by_name[name] = feat

    os.makedirs(OUT_DIR, exist_ok=True)

    continent_map = {
        "africa": ("Africa", "Africa"),
        "asia": ("Asia", "Asia"),
        "europe": ("Europe", "Europe"),
        "north-america": ("North America", "North America"),
        "south-america": ("South America", "South America"),
        "australia": ("Australia", "Oceania"),  # continent view uses Oceania landmasses
        "antarctica": ("Antarctica", "Antarctica"),
    }

    catalog = {"continents": [], "countries": []}

    for mid, (display, key) in continent_map.items():
        rings = prepare_rings(by_continent.get(key, []), "continent", map_id=mid)
        path = os.path.join(OUT_DIR, f"{mid}.json")
        payload = {
            "id": mid,
            "name": display,
            "category": "continent",
            "source": "Natural Earth 110m Admin 0",
            "polygons": to_json_rings(rings),
        }
        with open(path, "w") as f:
            json.dump(payload, f, separators=(",", ":"))
        catalog["continents"].append({"id": mid, "name": display, "file": f"{mid}.json", "rings": len(rings), "points": sum(len(r) for r in rings)})
        print(f"continent {display}: {len(rings)} rings, {sum(len(r) for r in rings)} pts")

    # Top 5 by land area + India (featured in reference video)
    countries = [
        ("russia", "Russia", "Russia"),
        ("canada", "Canada", "Canada"),
        ("china", "China", "China"),
        ("united-states", "United States", "United States of America"),
        ("brazil", "Brazil", "Brazil"),
        ("india", "India", "India"),
        ("australia-country", "Australia", "Australia"),
    ]

    for mid, display, ne_name in countries:
        feat = by_name.get(ne_name)
        if not feat:
            print("MISSING", ne_name)
            continue
        rings = prepare_rings(extract_rings(feat["geometry"]), "country", map_id=mid)
        path = os.path.join(OUT_DIR, f"{mid}.json")
        payload = {
            "id": mid,
            "name": display,
            "category": "country",
            "source": "Natural Earth 110m Admin 0",
            "polygons": to_json_rings(rings),
        }
        with open(path, "w") as f:
            json.dump(payload, f, separators=(",", ":"))
        catalog["countries"].append({"id": mid, "name": display, "file": f"{mid}.json", "rings": len(rings), "points": sum(len(r) for r in rings)})
        print(f"country {display}: {len(rings)} rings, {sum(len(r) for r in rings)} pts")

    with open(os.path.join(OUT_DIR, "catalog.json"), "w") as f:
        json.dump(catalog, f, indent=2)
    print("Wrote", OUT_DIR)


if __name__ == "__main__":
    main()
