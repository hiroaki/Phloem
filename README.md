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

## Manual smoke test

With GraphHopper available locally and the Rails server running, execute:

```sh
./scripts/route_smoke_test.sh
```

Optional environment overrides:

```sh
PHLOEM_URL=http://localhost:3000/route PROFILE=car FROM_LAT=35.68 FROM_LON=139.76 TO_LAT=35.69 TO_LON=139.77 ./scripts/route_smoke_test.sh
```

## Notes

- The project remains intentionally stateless.
- The public API avoids GraphHopper-specific response fields.
- See `HANDOFF.md` and `docs/DEVELOPMENT-PLAN.md` for the broader roadmap.
