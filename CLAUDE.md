# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hackathon logistics/warehouse management system. Go backend with clean layered architecture. Primary remaining work is the **AI demand prediction feature** (`feats/02_ai_demand_prediction.md`).

## Commands

```bash
# Start PostgreSQL + run migrations
cd backend && make start-deps
cd backend && make migrate-up

# Run server (with race detector)
cd backend && make start

# Regenerate Swagger docs
cd backend && make gen-swag

# Migrate down one step
cd backend && make migrate-down
```

Required `backend/.env`:
```
LOG_LEVEL=info
HTTP_SERVER_PORT=:8080
ENVIRONMENT=development
JWT_SECRET=your-secret-key
JWT_DURATION=15m
POSTGRES_CONNECTION_URI=postgres://postgres:password@localhost:5432/best?sslmode=disable
POSTGRES_MAX_CONNS=25
POSTGRES_MIN_CONNS=5
POSTGRES_MAX_CONN_LIFETIME=30m
POSTGRES_MAX_CONN_IDLE_TIME=10m
```

## Architecture

Module path: `github.com/Megidy/BestLviv2026Test`

Strict layered architecture — dependencies only flow inward:

```
Controller (HTTP/v1) → Use Case → Repository → PostgreSQL
```

| Layer | Path | Notes |
|-------|------|-------|
| Entity | `internal/entity/` | Domain models, enums (`DeliveryPriority`, `DeliveryStatus`, `UserRole`), sentinel errors |
| Use Case | `internal/usecase/<feature>/usecase.go` | Business logic; depends on local repo interface |
| Repository | `internal/repo/persistent/` | pgx v5; interfaces declared in `internal/repo/common_contracts.go` |
| Controller | `internal/controller/http/v1/` | Echo v5 handlers; defines local usecase interface inline |
| DTO | `internal/dto/` | `httprequest/` for input, `httpresponse/` for output, flat DTOs at package root |
| Config | `internal/cfg/config.go` | `caarlos0/env` — all config from env vars |

All dependencies wired manually in `cmd/api/main.go` — no DI framework.

**Adding any new feature follows this exact pattern:**
1. Entity in `internal/entity/`
2. Repo interface + postgres implementation in `internal/repo/persistent/`
3. Use case in `internal/usecase/<feature>/usecase.go` (declare repo interface locally)
4. Controller in `internal/controller/http/v1/` (declare usecase interface locally)
5. Register routes in `internal/controller/http/router.go` (add field + constructor param)
6. Wire in `cmd/api/main.go`

## Error Handling Pattern

Sentinel errors live in `internal/entity/error.go`. Map them to HTTP status in `internal/dto/httpresponse/error_maping.go`. Controllers call `httpresponse.NewErrorResponse(ctx, err, "msg")`.

## Database Schema

Migration: `backend/migrations/dev/20260401181020_initial.up.sql`

Key tables:
- `warehouses`, `customers` — locations with `latitude`/`longitude` (used for distance scoring in AI)
- `users` — `role user_role`, `warehouse_id`
- `resources`, `inventories` — what exists where (`UNIQUE (warehouse_id, resource_id)`)
- `delivery_requests` — `priority request_priority`, `status request_status`, `arrive_till`
- `delivery_request_items` — junction table: one request → many (resource, quantity) rows
- `allocations` — fulfillment tracking per source warehouse

Note: the migration file has two syntax errors (missing commas before `created_at` in `delivery_requests` and `delivery_request_items`) — fix before running.

## AI Feature (Priority Work)

Full spec: `feats/02_ai_demand_prediction.md`

**New entities needed:**
- `DemandReading` — `(point_id, resource_id, quantity, recorded_at, source)`
- `PredictiveAlert` — `(point_id, resource_id, predicted_shortfall_at, confidence float, status, proposal_id)`
- `RebalancingProposal` — target point + list of suggested transfers with confidence score

**Algorithm (start with Weighted Moving Average):**
- Rolling averages over 3 / 7 / 14 windows per (delivery_point × resource)
- Alert when short-term avg diverges ≥20% above long-term avg
- Rebalancing score: `(surplus × 0.6) - (distance_to_target × 0.4)`

**Endpoints to add:**
- `GET /v1/demand-predictions/{point_id}`
- `GET /v1/predictive-alerts`
- `POST /v1/rebalancing-proposals/{alert_id}/approve`
- `POST /v1/rebalancing-proposals/{alert_id}/dismiss`

**Delivery request feature** (`internal/usecase/deliveryrequest/usecase.go`) exists as a stub — no repo, no controller, no routes yet.

## Feature Specs

- `feats/01_offline_pwa_sync.md` — PWA + IndexedDB sync queue (frontend)
- `feats/02_ai_demand_prediction.md` — **AI, highest priority**
- `feats/03_live_map_heatmap.md` — Leaflet/Mapbox heatmap (frontend)
- `feats/04_role_auth_encryption.md` — field-level encryption + audit log
- `feats/05_mobile_qr_warehouse.md` — QR scanning (frontend)
