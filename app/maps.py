import json
import logging
import math
import os
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from fastapi import HTTPException


logger = logging.getLogger(__name__)
GEOAPIFY = "https://api.geoapify.com/v1/"


def valid_point(lat, lon):
    return -90 <= lat <= 90 and -180 <= lon <= 180


def geoapify(path, **params):
    key = os.getenv("GEOAPIFY_SERVER_KEY")
    if not key:
        raise HTTPException(503, "Map service is not configured.")
    url = GEOAPIFY + path + "?" + urlencode({**params, "apiKey": key})
    try:
        with urlopen(Request(url, headers={"User-Agent": "UMTRideShare/1.0"}), timeout=8) as response:
            return json.load(response)
    except (HTTPError, URLError, TimeoutError, ValueError) as exc:
        logger.warning("Geoapify request failed: %s", type(exc).__name__)
        raise HTTPException(502, "Map service is temporarily unavailable.") from exc


def driving_route(pickup_lat, pickup_lon, dropoff_lat, dropoff_lon):
    if not valid_point(pickup_lat, pickup_lon) or not valid_point(dropoff_lat, dropoff_lon):
        raise HTTPException(400, "Invalid map location.")
    if pickup_lat == dropoff_lat and pickup_lon == dropoff_lon:
        raise HTTPException(400, "Pickup and destination must be different.")
    data = geoapify("routing", waypoints=f"{pickup_lat},{pickup_lon}|{dropoff_lat},{dropoff_lon}", mode="drive")
    try:
        geometry = data["features"][0]["geometry"]
        if geometry["type"] not in ("LineString", "MultiLineString") or not geometry["coordinates"]:
            raise ValueError("No road route")
        return geometry
    except (KeyError, IndexError, TypeError, ValueError) as exc:
        raise HTTPException(422, "No driving route was found between these points.") from exc


def route_match(geometry, pickup, dropoff, radius_km=1):
    if not geometry:
        return False
    lines = geometry.get("coordinates", [])
    if geometry.get("type") == "LineString":
        lines = [lines]
    elif geometry.get("type") != "MultiLineString":
        return False
    points = [point for line in lines for point in line]
    if len(points) < 2:
        return False

    def candidates(target):
        matches = []
        distance_along = 0.0
        for a, b in zip(points, points[1:]):
            latitude = math.radians((a[1] + b[1] + target[0]) / 3)
            scale_x = 111.2 * math.cos(latitude)
            ax, ay = a[0] * scale_x, a[1] * 111.2
            bx, by = b[0] * scale_x, b[1] * 111.2
            px, py = target[1] * scale_x, target[0] * 111.2
            length_sq = (bx - ax) ** 2 + (by - ay) ** 2
            fraction = max(0, min(1, ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / length_sq)) if length_sq else 0
            distance = math.hypot(px - ax - fraction * (bx - ax), py - ay - fraction * (by - ay))
            segment_length = math.sqrt(length_sq)
            if distance <= radius_km:
                matches.append((distance_along + fraction * segment_length, distance))
            distance_along += segment_length
        return matches

    # shortcut: scan route segments in Python for campus-sized ride lists; add a spatial index when volume grows.
    starts, ends = candidates(pickup), candidates(dropoff)
    return any(end_at > start_at + 0.1 for start_at, _ in starts for end_at, _ in ends)
