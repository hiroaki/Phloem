# Phloem

Phloem is a standalone Rails API-only service that acts as a thin, normalized routing facade in front of routing providers such as GraphHopper, with future support planned for OSRM-compatible and Valhalla-style backends.

## Current scope

- `POST /route`
- GraphHopper as the active provider
- provider-neutral request validation
- normalized GeoJSON route response
- stable error envelope for validation and upstream failures

## Requirements

- Ruby 3.4.9 via `rbenv`
- Bundler 4+
- A reachable GraphHopper instance

## Configuration

Environment variables used by the current MVP:

- `ROUTING_PROVIDER` defaults to `graphhopper`
- `GRAPH_HOPPER_BASE_URL` defaults to `http://localhost:8989`
- `GRAPH_HOPPER_API_KEY` optional
- `GRAPH_HOPPER_TIMEOUT_SECONDS` defaults to `5`
- `PHLOEM_API_KEY` optional; when set, `POST /route` requires `Authorization: Bearer <key>` or `X-API-Key: <key>`

GraphHopper itself is configured separately from Rails. The local GraphHopper tool lives under `tools/routing/graphhopper`.

Recommended adjustments before first import:

- set `graphhopper.datareader.file` to your `.osm.pbf`
- keep `profiles` limited to the modes Phloem actually exposes
- keep `profiles_ch` enabled for `car` so API latency stays low
- review `graph.elevation.*` if you do not want SRTM downloads or elevation-aware routing

## API

Request:

```json
{
	"profile": "car",
	"points": [
		{ "lat": 35.68, "lon": 139.76 },
		{ "lat": 35.69, "lon": 139.77 }
	],
	"options": {}
}
```

Response:

```json
{
	"route": {
		"geometry": {
			"type": "LineString",
			"coordinates": [
				[139.76, 35.68],
				[139.77, 35.69]
			]
		},
		"distance_meters": 1234.5,
		"duration_seconds": 456.7,
		"provider": "graphhopper",
		"warnings": []
	}
}
```

Error envelope:

```json
{
	"error": {
		"code": "validation_error",
		"message": "Request validation failed",
		"details": {
			"points": [
				"must contain at least two points"
			]
		}
	}
}
```

## Setup

```sh
bundle install
bundle exec rspec
bin/rails server
```

## GraphHopper setup

Use the isolated tool directory at `tools/routing/graphhopper`.

Files in that directory are intentionally self-contained so other routing servers can later live alongside it under `tools/routing/`.

Place the downloaded `graphhopper-web-*.jar` in `tools/routing/graphhopper`, put your region PBF under `tools/routing/graphhopper/data`, and point `tools/routing/graphhopper/data/region.osm.pbf` at it.

Example runtime expectations for the checked-in tool:

- PBF input under `tools/routing/graphhopper/data`
- imported graph cache under `tools/routing/graphhopper/graph-cache`
- SRTM cache under `tools/routing/graphhopper/srtm`
- logs under `tools/routing/graphhopper/logs`

From `tools/routing/graphhopper`, start GraphHopper with Docker Compose:

```sh
cd tools/routing/graphhopper
docker compose -f compose.yml up --build
```

The checked-in Compose file builds a local image from the downloaded GraphHopper JAR and mounts the local `data`, `graph-cache`, `srtm`, and `logs` directories into the container, so the tool can be started from its own directory without touching the Rails app layout.

If you switch `region.osm.pbf` to a different source PBF, clear `tools/routing/graphhopper/graph-cache` before restart so GraphHopper rebuilds the import.

## Manual smoke test

With GraphHopper available locally and the Rails server running, execute:

```sh
./scripts/route_smoke_test.sh
```

Optional environment overrides:

```sh
PHLOEM_URL=http://localhost:3000/route PROFILE=car FROM_LAT=35.68 FROM_LON=139.76 TO_LAT=35.69 TO_LON=139.77 ./scripts/route_smoke_test.sh
```

If API key auth is enabled, pass the same key to the smoke test and to your client requests. The Rails health endpoint remains available at `GET /up` without this header.

```sh
PHLOEM_API_KEY=your-shared-key ./scripts/route_smoke_test.sh
```

## Notes

- The project remains intentionally stateless.
- The public API avoids GraphHopper-specific response fields.
- See `docs/DEVELOPMENT.md` and `docs/DEVELOPMENT.ja.md` for project status and the next milestone plan.
