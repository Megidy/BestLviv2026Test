# LogySync — AI-Powered Humanitarian Logistics Platform

> Real-time inventory management and predictive resupply for humanitarian operations in Ukraine.

LogySync bridges the gap between warehouses and delivery points by combining live inventory tracking, role-based dispatch workflows, and a proactive AI engine that predicts shortages **before they happen** — and automatically proposes optimal resupply routes.

---

## The Problem

Humanitarian logistics in crisis zones fails not because of lack of resources, but because of **information lag**. Warehouse workers discover shortages only after they occur. Dispatchers manually coordinate transfers across dozens of locations. Medical supplies, generators, and fuel run out while surplus sits idle 80 km away.

LogySync solves this with an always-on prediction engine that turns reactive logistics into a proactive, AI-assisted operation.

---

## Key Features

### AI Demand Prediction & Auto-Rebalancing
The core differentiator. The system continuously monitors demand patterns per delivery point and resource type. When a surge is detected:

1. A **predictive alert** is raised with a confidence score and estimated hours-to-shortfall
2. An **optimal rebalancing proposal** is generated — listing which warehouses to draw from, how much, and estimated arrival time
3. A dispatcher reviews and approves with **one tap**

The system acts before the shortage exists.

### Live Map Overview
Interactive map of all warehouses and delivery points across Ukraine. Each pin is color-coded by status (normal / elevated / critical) based on current inventory levels and active alerts. Dispatchers see the full picture at a glance.

### Full Delivery Workflow
End-to-end delivery request lifecycle: create → allocate → approve → dispatch → deliver. Urgent requests trigger immediate auto-allocation. Full audit log for every action.

### Role-Based Access
Three roles — `admin`, `dispatcher`, `worker` — each scoped to a warehouse. JWT authentication on every protected endpoint.

### LLM-Generated Alert Rationale
When a Groq API key is configured, each predictive alert includes a two-sentence human-readable explanation of what is happening and what action is recommended.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Frontend (React)                  │
│   Dashboard · Map · Inventory · Alerts · Delivery    │
└────────────────────────┬────────────────────────────┘
                         │ REST / JSON
┌────────────────────────▼────────────────────────────┐
│               Backend API (Go / Echo v5)             │
│                                                      │
│  Auth  ·  Inventory  ·  Delivery  ·  AI  ·  Map      │
│                                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │          AI Prediction Engine               │    │
│  │  WMA · Shortfall Calc · Rebalancing Score   │    │
│  │  Background loop every 1h (configurable)    │    │
│  └─────────────────────────────────────────────┘    │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│               PostgreSQL 16                          │
│  warehouses · customers · resources · inventories   │
│  delivery_requests · allocations · audit_log        │
│  demand_readings · predictive_alerts · proposals    │
└─────────────────────────────────────────────────────┘
```

**Stack:** Go 1.25 · Echo v5 · pgx v5 · PostgreSQL 16 · React 18 · TypeScript · Vite · Tailwind · Leaflet

**CI/CD:** GitHub Actions → EC2 (deploy on every push to `main`)

---

## Getting Started

### Prerequisites
- Docker + Docker Compose
- Go 1.25 (for local development)
- Node 20 (for frontend)

### Run with Docker

```bash
git clone https://github.com/Megidy/BestLviv2026Test.git logysinc
cd logysinc/backend

cp .env.example .env
# Edit .env — set JWT_SECRET at minimum

docker compose up -d
```

The API is available at `http://localhost:8080`.
Swagger UI: `http://localhost:8080/swagger/index.html`

### Demo Credentials

All users share password `secret`.

| Username | Role | Warehouse |
|---|---|---|
| `admin_w1` | Admin | Kyiv Central (W1) |
| `dispatcher_w1` | Dispatcher | Kyiv Central (W1) |
| `worker1_w1` | Worker | Kyiv Central (W1) |
| `admin_w3` | Admin | Kharkiv Main (W3) |

Full list: `admin_w1`–`admin_w20`, `dispatcher_w1`–`dispatcher_w20`, `worker1_w1`–`worker1_w20`.

### Trigger AI Predictions Immediately

After login, hit the manual trigger instead of waiting for the 1h background interval:

```bash
curl -X POST http://localhost:8080/v1/ai/run \
  -H "Authorization: Bearer <token>"
```

This generates 4 critical and 3 elevated alerts from the seeded demand data.

---

## Project Structure

```
├── backend/                  # Go API
│   ├── cmd/api/              # Entry point, dependency wiring
│   ├── internal/
│   │   ├── cfg/              # Config from env vars
│   │   ├── controller/http/  # Echo route handlers
│   │   ├── usecase/          # Business logic
│   │   ├── repo/persistent/  # PostgreSQL repositories
│   │   ├── entity/           # Domain models & sentinel errors
│   │   ├── dto/              # Request/response DTOs
│   │   └── pkg/groq/         # Groq LLM client
│   ├── migrations/dev/       # SQL migrations (ordered)
│   └── docs/                 # Backend & AI module docs
├── frontend/                 # React SPA
└── .github/workflows/        # CI/CD pipelines
```

---

## Documentation

- [Backend Architecture & API Reference](backend/docs/BACKEND.md)
- [AI Prediction Module Deep-Dive](backend/docs/AI_MODULE.md)
