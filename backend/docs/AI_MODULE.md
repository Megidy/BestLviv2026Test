# AI Demand Prediction Module

## What It Solves

Most logistics software is reactive: it tells you stock has hit zero. By then it's too late.

LogySync's prediction engine monitors demand trends continuously across every `(delivery point, resource)` pair. When a surge is detected, it raises an alert **hours before stock runs out** — and immediately generates a concrete, optimal rebalancing proposal that a dispatcher can approve with one click.

The engine runs in the background every hour. A manual trigger endpoint exists for demos.

---

## Code Location

```
internal/usecase/prediction/
├── usecase.go     — orchestration: background loop, alert creation, proposal generation
└── wma.go         — pure math: WMA, confidence, shortfall estimate, Haversine, rebalancing score

internal/repo/persistent/
└── ai_postgres.go — all DB reads/writes for the prediction module

internal/controller/http/v1/
└── prediction.go  — HTTP handlers for alerts, proposals, demand readings, manual trigger

internal/pkg/groq/
└── client.go      — optional Groq LLM client for alert rationale
```

---

## Algorithm: Weighted Moving Average (WMA)

### Why WMA

WMA is the right trade-off for this problem:
- **Explainable** — non-technical judges and dispatchers can understand it: "recent demand is 67% higher than the historical baseline"
- **Correct** — it handles the surge patterns common in humanitarian logistics (sudden demand spikes around events/incidents)
- **Swappable** — the interface boundary is already drawn; replacing WMA with Prophet or LSTM requires changes only in `wma.go`

### Computation

For each `(point_id, resource_id)` pair, the engine fetches the last 14 demand readings ordered by `recorded_at`.

Reading at position `i` (1-indexed from oldest) gets weight `i`. The most recent reading has the highest weight.

```
WMA = Σ(reading[i] × i) / Σ(i)   for i = 1..n
```

Two averages are computed:

| Window | Readings | Purpose |
|---|---|---|
| Short-term | Last 3 | Captures the current trend |
| Long-term | Last 14 | Baseline — what "normal" looks like |

**Example (CRITICAL pair):**

Readings: `20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 55, 55, 55`

```
shortTermAvg  = (55×1 + 55×2 + 55×3) / (1+2+3) = 330/6 = 55.0
longTermAvg   = Σ(reading[i]×i) / Σ(i) over 14 readings = 33.0

divergence    = (55.0 − 33.0) / 33.0 = 0.667  →  66.7%
```

### Alert Trigger Condition

```
divergence = (shortTermAvg − longTermAvg) / longTermAvg

if divergence >= 0.20 → create alert
```

A 20% surge in short-term demand above the long-term baseline is the threshold. Below this, noise and normal fluctuations are ignored.

### Confidence Score

```
confidence = min(0.5 + (divergence − 0.20) / 0.40, 1.0)
```

| Divergence | Confidence | Label |
|---|---|---|
| 20% | 0.50 | Elevated |
| 40% | 0.75 | High |
| 60%+ | 1.00 | Critical |

Confidence is shown on every alert, used to sort the alert queue (highest first), and passed to the LLM rationale prompt.

### Shortfall Estimation

Once a trend is confirmed, the engine estimates how many hours remain before stock is exhausted:

```go
avgIntervalHours = totalTimeSpanHours / (numReadings − 1)
shortfallHours   = (totalStockAtPoint / shortTermAvg) × avgIntervalHours
predictedAt      = NOW() + shortfallHours
```

An alert is only created if `shortfallHours < 48`. This prevents the system from flagging slow-moving resources with a real trend but no urgency.

---

## Rebalancing Proposal

Every alert immediately triggers proposal generation. The goal: find the best combination of warehouses to cover the projected shortage.

### Step 1 — Candidate Warehouses

All warehouses holding the resource are queried. For each:

```go
surplus = quantity × (1 − 0.20)   // keep 20% as safety stock
```

Warehouses with `surplus <= 0` are excluded.

### Step 2 — Scoring

Each candidate is scored:

```go
score = (surplus × 0.6) − (normalizedDistance × 0.4)
```

Distance is computed with the **Haversine formula** using actual `latitude` / `longitude` from the `warehouses` and `customers` tables. It's normalised to `[0, 1]` across all candidates.

This formula prioritises nearby warehouses with large surplus. The 0.6/0.4 weight split can be tuned; closer to 1.0/0.0 favours proximity alone.

Candidates are sorted descending by score.

### Step 3 — Greedy Allocation

```go
neededQty = shortTermAvg × 2   // buffer: 2 demand periods
```

Draw from the ranked list until `neededQty` is covered. Each transfer records:

| Field | Value |
|---|---|
| `from_warehouse_id` | Source warehouse |
| `quantity` | Units allocated |
| `estimated_arrival_hours` | `distanceKm / 60` |

### Result Example

```json
{
  "id": 12,
  "target_point_id": 9,
  "resource_id": 23,
  "urgency": "predictive",
  "confidence": 1.0,
  "status": "pending",
  "transfers": [
    { "from_warehouse_id": 5, "quantity": 64, "estimated_arrival_hours": 1.4 },
    { "from_warehouse_id": 3, "quantity": 46, "estimated_arrival_hours": 2.1 }
  ]
}
```

---

## Background Loop

```go
// Started at application boot in cmd/api/main.go
go predictionUseCase.StartPredictionLoop(ctx, c.PredictionInterval)
```

Each tick:
1. Query all distinct `(point_id, resource_id)` pairs from `demand_readings`
2. Run `analyzePair` for each
3. Skip pairs that already have an open alert — no duplicates
4. For pairs triggering: create alert → create proposal → link proposal ID to alert

The interval is set via `PREDICTION_INTERVAL` env var (default: `1h`).

### On-Demand Trigger

For demos, skip the wait:

```bash
POST /v1/ai/run
Authorization: Bearer <token>

← 202 Accepted
```

The run happens in a background goroutine. Refresh `/v1/predictive-alerts` after ~2 seconds.

### Post-Record Analysis

When a demand reading is recorded via `POST /v1/demand-readings`, the module also immediately runs `analyzePair` for that specific pair in a background goroutine. Alerts can appear within seconds of a new reading — not just at the next scheduled tick.

---

## Proposal Lifecycle

```
pending  →  approved  (alert auto-resolves, disappears from queue)
         →  dismissed (alert stays open but marked "Proposal rejected")
```

Approving a proposal calls `ResolveAlertByProposalID` before returning. The alert status changes to `resolved` and it is excluded from the open alert list.

---

## LLM Rationale (Optional)

If `GROQ_API_KEY` is set, each new alert gets a two-sentence explanation via Groq's `llama-3.1-8b-instant` model.

**Prompt includes:** location name, resource name, short-term avg, long-term avg, divergence %, hours to shortfall, confidence score.

**Response** is stored in the `rationale` column of `predictive_alerts` and returned in the API response alongside the structured alert data.

If the API key is absent or the call fails, the alert is created normally — rationale is `null`. The LLM layer is strictly best-effort; it never blocks alert creation.

**Nil-interface safety:** the `llmClient` field in the use case is a typed interface. To avoid the Go typed-nil trap, the main.go always passes an **untyped nil** when no key is configured — not a typed `*groq.Client(nil)`.

---

## Data Model

### `demand_readings`

| Column | Type | Notes |
|---|---|---|
| `point_id` | uint | Customer delivery point ID |
| `resource_id` | uint | Resource being tracked |
| `quantity` | float64 | Units consumed / demanded this period |
| `recorded_at` | timestamptz | When the demand occurred |
| `source` | text | `sensor`, `manual`, or `predicted` |

### `predictive_alerts`

| Column | Type | Notes |
|---|---|---|
| `point_id` | uint | Delivery point at risk |
| `resource_id` | uint | Resource trending to shortage |
| `predicted_shortfall_at` | timestamptz | Estimated time of stock-out |
| `confidence` | float64 | 0.0–1.0 (see formula above) |
| `status` | text | `open`, `dismissed`, `resolved` |
| `proposal_id` | *uint | Linked proposal (nullable) |
| `rationale` | *text | LLM explanation (nullable) |

### `rebalancing_proposals`

| Column | Type | Notes |
|---|---|---|
| `target_point_id` | uint | Destination delivery point |
| `resource_id` | uint | Resource to transfer |
| `urgency` | text | Always `predictive` for AI-generated proposals |
| `confidence` | float64 | Inherited from the alert |
| `status` | text | `pending`, `approved`, `dismissed` |

### `rebalancing_transfers`

| Column | Type | Notes |
|---|---|---|
| `proposal_id` | uint | Parent proposal |
| `from_warehouse_id` | uint | Source warehouse |
| `quantity` | float64 | Units to send |
| `estimated_arrival_hours` | float64 | `distanceKm / 60` |

---

## Seeded Demo Data

The migration `20260404130000_seed_demand_readings.up.sql` pre-loads readings to produce a realistic demo without waiting for real data collection.

**CRITICAL pairs (divergence ~67%, confidence 1.0):**

14 readings per pair: readings 1–11 at qty=20, readings 12–14 at qty=55.

| Delivery Point | Resource |
|---|---|
| Ocean Plaza Kyiv | Бинт стерильний |
| Сільпо Дніпро Перемога | Маска медична |
| City Mall Запоріжжя | Антисептик |
| Любава Черкаси | Бинт стерильний |

**ELEVATED pairs (divergence ~33%, confidence ~0.66):**

Readings 1–11 at qty=20, readings 12–14 at qty=30.

| Delivery Point | Resource |
|---|---|
| Фора Харків Центр | Power Bank |
| Новус Львів Сихів | Ліхтар LED |
| АТБ Одеса Приморський | Радіоприймач |

**STABLE pairs (no alert):**
- Сільпо Київ Оболонь × Молоко — steady at 20
- Французький Бульвар Харків × Хліб — steady at 20
- Фора Вінниця × Олія — steady at 20

After `make migrate-up`, call `POST /v1/ai/run` to generate all 7 alerts instantly.

---

## Scalability Path

The WMA model is intentionally swappable. The `aiRepo` interface is the only dependency; replacing the algorithm requires changes only in `usecase/prediction/wma.go`:

- **Linear regression** — fit a line to the last N readings, extrapolate forward
- **Facebook Prophet** — handles seasonality and missing data via a Python sidecar
- **Lightweight LSTM** — per-pair rolling model; can be deployed as an independent microservice that writes alerts directly to the DB
- **Real sensor integration** — the `source` field on `demand_readings` is already designed for `"sensor"` entries from IoT or POS systems

The prediction loop can also be extracted into a separate process that publishes to a message queue (Kafka, NATS), fully decoupling prediction latency from API latency.
