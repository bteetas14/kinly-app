# Kinly Architecture

Kinly uses a modular monolith backend and a Flutter mobile client.

## Backend

The Go service is organized by technical layer:

- `handlers` parse HTTP input and write responses.
- `services` enforce product rules and orchestration.
- `repositories` own SQL and persistence.
- `middleware` handles auth, logging, recovery, and CORS.
- `dto` defines request and response contracts.
- `models` defines domain structs shared across layers.

The backend intentionally keeps ranking, reputation, trust score, and notification generation in services so the algorithms can evolve without changing handlers or SQL callers.

## Mobile

The Flutter app uses:

- Riverpod for state and dependency injection.
- GoRouter for route configuration and auth redirects.
- Dio for REST API calls.

Feature folders keep screens, DTOs, and repositories close to their UI surface while shared API/auth/navigation code lives under `lib/core`.

## Storage

Image storage is represented by a backend abstraction with S3-compatible configuration. Local development uses MinIO; production can use any S3-compatible provider with the same environment contract.
