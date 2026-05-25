# Development Plan

## Mission

Build Phloem as a standalone Rails API-only application that provides a thin, normalized routing facade over GraphHopper first, while preserving a clean internal path to future OSRM-compatible and Valhalla-style adapters.

## Scope

### Included in v1
- Rails API-only application
- `POST /route`
- GraphHopper adapter for route calculation
- provider-neutral request validation
- provider-neutral normalized response serialization
- timeout and upstream error handling
- test coverage for request and adapter behavior
- configuration via environment variables

### Explicitly out of scope for v1
- `POST /match`
- `GET /capabilities`
- turn-by-turn instructions
- matrix or isochrone endpoints
- provider-specific advanced costing exposure
- database-backed request history
- admin UI

## Design Principles

1. Keep the public API smaller than the internal abstraction.
2. Hide provider-specific request and response formats.
3. Prefer stateless request handling.
4. Avoid introducing persistence until a clear operational need exists.
5. Optimize for long-term provider replaceability, not for exposing every backend feature.

## Proposed Milestones

### Milestone 1: API contract
- define request JSON schema for `POST /route`
- define response JSON schema and stable error envelope
- define validation rules for `profile` and `points`

### Milestone 2: Rails skeleton
- generate Rails API-only app
- set up routes, base controller behavior, and environment configuration
- choose HTTP client strategy for upstream provider calls

### Milestone 3: Provider abstraction
- create abstract routing provider interface
- create GraphHopper adapter
- keep future method slots for `match` and `capabilities`

### Milestone 4: Orchestration and serialization
- implement routing service
- implement response serializer / normalizer
- map GraphHopper responses into public JSON

### Milestone 5: Operational hardening
- add timeout handling
- add upstream error mapping
- add optional fixed API-key auth seam
- decide whether to add caching immediately or as the next milestone

### Milestone 6: Verification
- request specs for API behavior
- adapter specs with fixture payloads
- manual curl verification against a running local GraphHopper instance

## Suggested Initial API Shape

### Request

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

### Response

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

### Error envelope

```json
{
  "error": {
    "code": "upstream_timeout",
    "message": "Routing provider timed out",
    "details": {}
  }
}
```

## Suggested Rails Implementation Areas

- `app/controllers/routes_controller.rb`
- `app/services/routing_service.rb`
- `app/adapters/routing_provider.rb`
- `app/adapters/graph_hopper_adapter.rb`
- `app/serializers/route_response_serializer.rb`
- `config/routes.rb`
- `spec/requests/route_spec.rb`
- `spec/adapters/graph_hopper_adapter_spec.rb`

## Risks To Watch

- leaking GraphHopper assumptions into the public contract
- expanding the public API before the first happy path works
- introducing too many provider-neutral options too early
- binding authentication and routing concerns too tightly

## Definition of Done for the First Working Slice

The first milestone is complete when:
- a local GraphHopper instance can be queried through `POST /route`
- invalid payloads return stable validation errors
- upstream failures return stable error envelopes
- at least one request spec and one adapter spec pass
- the returned geometry is directly consumable by a browser client without provider-specific decoding
