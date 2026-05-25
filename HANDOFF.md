# Phloem Handoff

## Project Status

This is a standalone Rails API-only project. The initial application skeleton and a working `POST /route` MVP are now in place.

## Product Definition

Phloem is a thin routing facade that normalizes route-related geospatial APIs behind a single provider-neutral HTTP surface.

## Confirmed Decisions

- Product name: `Phloem`
- Implementation stack: Rails API-only
- Deployment assumption: Docker image, likely deployed with Kamal
- v1 public feature scope: `route` only
- v1 backend provider: GraphHopper only
- Future design target: support additional adapters for OSRM-compatible and Valhalla-style providers
- Internal design must anticipate future `match` and `capabilities` endpoints
- Authentication is not required for the first local bring-up, but the design must leave a clean seam for fixed API-key authentication
- Database usage is deferred unless request history, quotas, analytics, or an admin UI become necessary

## Architectural Direction

Phloem should expose a normalized HTTP API and hide provider-specific request/response formats.

Suggested public shape for v1:
- `POST /route`
- input: `profile`, ordered `points`, optional provider-neutral options block
- output: normalized geometry, distance, duration, provider identifier, warnings, and a stable error envelope

Suggested internal structure:
- controller layer for request validation and rendering
- orchestration service layer for provider selection and policy
- adapter layer for provider-specific translation
- serializer/normalizer layer for stable public JSON
- environment-driven configuration for provider URL, credentials, timeouts, and future auth toggles

## Near-Term Implementation Order

1. Harden the public JSON schema for `POST /route` with additional abnormal-path tests.
2. Keep the provider interface ready for future `route`, `match`, and `capabilities` expansion.
3. Add optional fixed API-key auth once the happy path is stable.
4. Decide whether a minimal `/health` or `/capabilities` endpoint belongs in the next slice.
5. Decide whether caching belongs in the first operational pass or immediately after.

## Key Constraints

- Do not let GraphHopper-specific fields leak through the public API.
- Do not design the request format around one provider's quirks.
- Keep the initial API small; avoid adding instructions, matrix, isochrone, or provider-specific costing details in v1.
- Keep the service stateless unless persistence becomes clearly necessary.

## Open Areas That Can Be Finalized During Implementation

- exact request JSON schema for `POST /route`
- exact normalized response format
- whether to expose `provider` in the response body or metadata only
- whether to add a minimal `/health` or `/capabilities` endpoint in the first implementation pass
- whether caching should be added in the first milestone or immediately after

## Suggested Initial Directory Shape

```text
phloem/
  README.md
  HANDOFF.md
  HANDOFF.ja.md
  docs/
    DEVELOPMENT-PLAN.md
    DEVELOPMENT-PLAN.ja.md
```

After Rails app generation, expected main implementation areas:

```text
app/
  controllers/
  services/
  adapters/
  serializers/
config/
  routes.rb
spec/
  requests/
  adapters/
```

## First Concrete Goal

Keep one end-to-end request working locally while tightening the contract:
- Rails API receives `POST /route`
- GraphHopper is called through the adapter
- response is normalized into provider-neutral JSON
- request and adapter specs cover both happy-path and core abnormal-path behavior

## Notes for the Next AI Session

Prefer a disciplined MVP. The main risk is accidental API over-design. Keep the public surface small and explicit, and keep future extensibility inside the adapter boundary rather than in a large request schema.
