# Development

## Status

Milestone 1 is complete.

Phloem now runs as a standalone Rails API-only application with a working `POST /route` endpoint backed by GraphHopper. The local development workflow includes a self-contained GraphHopper tool under `tools/routing/graphhopper`, request and adapter specs pass, and a manual smoke test against a running local GraphHopper instance succeeds.

## Mission

Build Phloem as a thin, provider-neutral routing facade that starts with GraphHopper and preserves a clean path to future OSRM-compatible and Valhalla-style adapters.

## Current Product Shape

- Public endpoint: `POST /route`
- Backend provider in active use: GraphHopper
- Health check: Rails built-in `GET /up`
- Optional request authentication: `PHLOEM_API_KEY` for `POST /route`
- Response contract: normalized geometry, distance, duration, provider, warnings, and stable error envelopes

## What Is Done

### API and contract
- request validation for `profile`, `points`, and `options`
- normalized route response serialization
- stable validation, upstream timeout, upstream error, and authentication error envelopes

### Provider integration
- GraphHopper adapter behind a provider abstraction
- routing orchestration through `RoutingService`
- environment-driven provider configuration

### Operational baseline
- local GraphHopper runtime isolated under `tools/routing/graphhopper`
- Docker Compose based startup for GraphHopper
- local GraphHopper configuration, cache directories, SRTM cache, and logs documented
- optional API-key protection for `POST /route`
- Rails `GET /up` adopted as the baseline health check

### Verification
- request specs for public API behavior
- adapter specs for GraphHopper mapping and timeout handling
- successful manual smoke test through the Rails endpoint against local GraphHopper

## Current Scope

### Included in v1
- Rails API-only application
- `POST /route`
- GraphHopper adapter for route calculation
- provider-neutral request validation
- provider-neutral normalized response serialization
- timeout and upstream error handling
- optional API-key authentication
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

## Architecture Notes

- Keep the public API smaller than the internal abstraction.
- Hide provider-specific request and response formats.
- Prefer stateless request handling.
- Avoid persistence until an operational need is clear.
- Optimize for provider replaceability rather than exposing every backend feature.

## Next Milestone

The next milestone should focus on tightening the MVP rather than widening the surface.

### Recommended priorities
1. Harden the `POST /route` contract with more abnormal-path and edge-case coverage.
2. Keep the provider interface ready for future `route`, `match`, and `capabilities` expansion without exposing those endpoints yet.
3. Keep the optional API-key flow lightweight and operationally simple.
4. Decide whether caching belongs in the next operational slice.
5. Decide whether a richer `GET /capabilities` endpoint is needed beyond Rails `GET /up`.

### Non-goals for the next slice unless requirements change
- turn-by-turn instructions
- matrix or isochrone support
- request persistence, quotas, analytics, or admin UI
- provider-specific costing controls in the public API

## Risks To Watch

- leaking GraphHopper assumptions into the public contract
- expanding the public API before there is a clear need
- introducing too many provider-neutral options too early
- coupling authentication concerns too tightly to routing behavior
- letting the local GraphHopper tool drift from the documented workflow

## Working Agreements

- Keep one local end-to-end request working at all times.
- Preserve the normalized response contract when changing providers or internals.
- Treat `tools/routing/graphhopper` as an external tool boundary, not part of the Rails app core.
- When switching the local PBF dataset, rebuild the GraphHopper cache rather than trying to reuse it.

## Main Implementation Areas

- `app/controllers/routes_controller.rb`
- `app/services/routing_service.rb`
- `app/adapters/routing_provider.rb`
- `app/adapters/graph_hopper_adapter.rb`
- `app/serializers/route_response_serializer.rb`
- `config/routes.rb`
- `spec/requests/route_spec.rb`
- `spec/adapters/graph_hopper_adapter_spec.rb`