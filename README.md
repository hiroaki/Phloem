# Phloem

Phloem is a standalone Rails API-only service that acts as a thin, normalized routing facade in front of routing providers such as GraphHopper, with future support planned for OSRM-compatible and Valhalla-style backends.

## Current scope

- `POST /route`
- `GET /provider_usage`
- GraphHopper as the active provider
- provider-neutral request validation
- normalized GeoJSON route response
- stable error envelope for validation and upstream failures

## Quick Start (Docker)

To try Phloem without installing Ruby or hosting GraphHopper, obtain a GraphHopper API key from the GraphHopper service and run the container below.

```sh
export GRAPH_HOPPER_API_KEY=<Your GraphHopper API key>

docker run --rm \
  -p 3000:3000 \
  -e ROUTING_PROVIDER=graphhopper \
  -e GRAPH_HOPPER_BASE_URL=https://graphhopper.com/api/1 \
  -e GRAPH_HOPPER_API_KEY \
  -e SECRET_KEY_BASE_DUMMY=1 \
  ghcr.io/hiroaki/phloem:latest
```

Verify the server is running with the health endpoint:

```sh
curl http://localhost:3000/up
```

Then try a route request:

```sh
curl -X POST http://localhost:3000/route \
  -H "Content-Type: application/json" \
  -d '{
    "profile": "car",
    "points": [
      { "lat": 35.68, "lon": 139.76 },
      { "lat": 35.69, "lon": 139.77 }
    ],
    "options": {}
  }'
```

## Configuration

Environment variables used by the current MVP:

- `ROUTING_PROVIDER` defaults to `graphhopper`
- `GRAPH_HOPPER_BASE_URL` defaults to `http://localhost:8989`
- `GRAPH_HOPPER_API_KEY` optional
- `GRAPH_HOPPER_TIMEOUT_SECONDS` defaults to `5`
- `GRAPH_HOPPER_RESTRICTED_PLAN` defaults to `false`; enables compatibility mode for restricted GraphHopper plans. Currently this suppresses flexible-mode request parameters where needed (for example, it avoids sending `ch.disable=true`)
- `PHLOEM_ROUTE_PROFILES` optional; comma-separated abstract profile names exposed by the API. Defaults to `car,bike,foot` when unset
- `PHLOEM_PROFILE_MAP` optional; JSON map of abstract profile name to provider profile name. Defaults to identity mapping for `PHLOEM_ROUTE_PROFILES` (for example, `{"car":"car","bike":"bike","foot":"foot"}`)
- `PHLOEM_PROFILE_PROBE_ON_BOOT` defaults to `true` outside test; when enabled, Phloem probes each configured profile at boot and excludes profiles that fail probe requests
- `PHLOEM_PROFILE_PROBE_POINTS` optional; semicolon-separated `lat,lon` pairs used by boot probes (for example, `35.68,139.76;35.69,139.77`)
- `PHLOEM_CORS_ORIGINS` optional; comma-separated list of allowed CORS origins for `POST /route`. When unset, CORS middleware is not enabled.
- `PHLOEM_API_KEY` optional; when set, `POST /route` and `GET /provider_usage` require `Authorization: Bearer <key>` or `X-API-Key: <key>`

**Profile probing behavior:**

- Probe failures do not stop Phloem boot.
- Failed profiles are excluded from request validation and route handling until the process is restarted.
- If all profiles fail probe checks, Phloem still boots and `POST /route` returns a validation error indicating no profiles are currently available.

**Provider usage cache behavior:**

Provider usage data (`provider_usage`) is stored via Rails cache. Whether this data is shared across processes and preserved across restarts depends on the configured cache backend. In deployments where `solid_cache_store` is backed by a shared, persistent database, all application processes will observe the same latest provider usage snapshot. In local-only or non-persistent cache setups, values may differ between processes and may be lost on restart.

## API

### POST /route

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

### GET /provider_usage

Provider usage snapshot response:

```json
{
  "provider_usage": {
    "provider": "graphhopper",
    "limit": 500,
    "remaining": 471,
    "reset_at": "2026-08-03T23:59:59Z"
  }
}
```

If no usage metadata has been captured yet (or the active provider does not provide usage metadata), `provider_usage` is returned as `null`.


## Development Setup

### Development Requirements

- Ruby 3.4.9 via `rbenv`
- Bundler 4+
- A reachable GraphHopper instance

### Setup

```sh
bundle install
bundle exec rspec
bin/rails server
```

## GraphHopper Setup (Local)

GraphHopper itself is configured separately from Rails. The local GraphHopper tool lives under `tools/routing/graphhopper`.

Place the downloaded `graphhopper-web-*.jar` in `tools/routing/graphhopper`, put your region PBF under `tools/routing/graphhopper/data`, and point `tools/routing/graphhopper/data/region.osm.pbf` at it.

```sh
cd tools/routing/graphhopper
curl -L https://github.com/graphhopper/graphhopper/releases/download/11.0/graphhopper-web-11.0.jar -o graphhopper-web-11.0.jar
curl -L -o ./data/japan-latest.osm.pbf https://download.geofabrik.de/asia/japan-latest.osm.pbf
ln -s japan-latest.osm.pbf ./data/region.osm.pbf
```

Example runtime expectations for the checked-in tool:

- PBF input under `tools/routing/graphhopper/data`
- imported graph cache under `tools/routing/graphhopper/graph-cache`
- SRTM cache under `tools/routing/graphhopper/srtm`
- logs under `tools/routing/graphhopper/logs`

Recommended adjustments before first run:

- set `graphhopper.datareader.file` to your `.osm.pbf`
- keep `profiles` limited to the modes Phloem actually exposes
- keep `profiles_ch` enabled for `car` so API latency stays low
- review `graph.elevation.*` if you do not want SRTM downloads or elevation-aware routing

From `tools/routing/graphhopper`, start GraphHopper with Docker Compose:

```sh
cd tools/routing/graphhopper
docker compose up --build
```

The checked-in Compose file builds a local image from the downloaded GraphHopper JAR and mounts the local `data`, `graph-cache`, `srtm`, and `logs` directories into the container, so the tool can be started from its own directory without touching the Rails app layout.

If you switch `region.osm.pbf` to a different source PBF, clear `tools/routing/graphhopper/graph-cache` before restart so GraphHopper rebuilds the import.

## Smoke test

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
- See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) and [docs/DEVELOPMENT.ja.md](docs/DEVELOPMENT.ja.md) for project status and the next milestone plan.
