# API Testing Guide

Swagger UI: `http://localhost:8080/swagger/index.html`

All protected endpoints require a Bearer token. Get one from the Login endpoint first, then click **Authorize** in Swagger and paste `Bearer <token>`.

---

## Step 1 — Login

`POST /v1/auth/login`

```json
{
  "username": "admin_w1",
  "password": "secret"
}
```

Copy the `data` value from the response. In Swagger click **Authorize → BearerAuth** and enter:
```
Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Other available logins: `dispatcher_w1`, `worker1_w1`, `admin_w3` … `admin_w20`. All use password `secret`.

---

## Step 2 — Auth

### Get current user
`GET /v1/auth/me` — no body.

### Create a new user (admin only)
`POST /v1/auth/create`

```json
{
  "username": "newworker",
  "required": "password123",
  "role": "worker",
  "warehouse_id": 1
}
```

> Note: the password field JSON tag is literally `"required"` (a typo in the DTO). Use that key name exactly.

Valid roles: `worker`, `dispatcher`

---

## Step 3 — Inventory

### Get inventory for a location
`GET /v1/inventory/{location_id}`

| location_id | Name |
|---|---|
| 1 | Склад Київ-Центральний (largest hub) |
| 3 | Склад Харків-Головний |
| 6 | Склад Львів-Захід |

Query params (all optional):
```
page=1&pageSize=20&resource_name=молоко&resource_category=food
```

Valid categories: `food`, `beverages`, `household`, `electronics`, `fuel`, `medical`, `stationery`, `building`, `clothing`, `communications`

---

## Step 4 — Map

### Get all map points
`GET /v1/map/points` — no body.

Returns all 20 warehouses + 40 customer locations with `status`: `normal`, `elevated`, or `critical`.

---

## Step 5 — AI / Prediction

### Trigger predictions immediately (skip the 1h wait)
`POST /v1/ai/run` — no body. Returns `202 Accepted`.

After running, the 7 seeded demand pairs will generate alerts.

### Record a demand reading
`POST /v1/demand-readings`

```json
{
  "point_id": 3,
  "resource_id": 22,
  "quantity": 55,
  "source": "manual"
}
```

Valid sources: `manual`, `sensor`, `predicted`  
`recorded_at` is optional (ISO 8601). If omitted, uses current time:
```json
{
  "point_id": 3,
  "resource_id": 22,
  "quantity": 55,
  "source": "sensor",
  "recorded_at": "2026-04-04T12:00:00Z"
}
```

### Get demand history for a point
`GET /v1/demand-readings/{point_id}`

```
point_id=3&page=1&pageSize=20
```

### List open predictive alerts
`GET /v1/predictive-alerts`

```
page=1&pageSize=20
```

Sorted by confidence descending. After running `POST /v1/ai/run`, expect 4 critical + 3 elevated alerts.

### Get alerts for a specific delivery point
`GET /v1/predictive-alerts/{point_id}`

```
point_id=3
```

Seeded critical points: `3`, `9`, `14`, `20`  
Seeded elevated points: `5`, `11`, `7`

### Dismiss an alert
`POST /v1/predictive-alerts/{alert_id}/dismiss` — no body.

### Get a rebalancing proposal
`GET /v1/rebalancing-proposals/{proposal_id}` — no body.

The `proposal_id` comes from the `proposal_id` field on an alert.

### Approve a rebalancing proposal
`POST /v1/rebalancing-proposals/{proposal_id}/approve` — no body.

### Dismiss a rebalancing proposal
`POST /v1/rebalancing-proposals/{proposal_id}/dismiss` — no body.

---

## Step 6 — Delivery Requests

### Status machine

**Normal / elevated / critical flow:**
```
pending → (allocate) → allocated → (dispatch all) → in_transit → (deliver) → delivered
```

**Urgent flow (auto-allocated on create, skips planned/approval):**
```
pending → allocated[approved] → (dispatch all) → in_transit → (deliver) → delivered
```

Key constraints:
- `PATCH items` — only works when status is `pending`. Once allocated, items are locked.
- `approve allocation` — only works when allocation status is `planned`. Urgent requests create allocations as `approved` already, skip straight to dispatch.
- `deliver request` — only works when status is `in_transit` (all allocations must be dispatched first).

---

### Create a normal request (goes to pending, needs manual allocation)
`POST /v1/delivery-requests`

```json
{
  "destination_id": 3,
  "priority": "normal",
  "items": [
    { "resource_id": 22, "quantity": 10 },
    { "resource_id": 7,  "quantity": 50 }
  ]
}
```

### Create an urgent request (auto-allocated immediately, allocations already approved)
`POST /v1/delivery-requests`

```json
{
  "destination_id": 3,
  "priority": "urgent",
  "arrive_till": "2026-04-05T08:00:00Z",
  "items": [
    { "resource_id": 23, "quantity": 5 }
  ]
}
```

`arrive_till` is **required** for urgent priority.

### Update item quantity (only while status = pending)
`PATCH /v1/delivery-requests/{id}/items`

```json
{
  "resource_id": 22,
  "quantity": 15
}
```

### List delivery requests
`GET /v1/delivery-requests`

```
page=1&pageSize=20
```

### Get a single request with items and allocations
`GET /v1/delivery-requests/{id}` — no body.

### Cancel a request (pending or allocated only)
`POST /v1/delivery-requests/{id}/cancel` — no body.

### Escalate priority
`POST /v1/delivery-requests/{id}/escalate` — no body. Bumps one level: normal → elevated → critical → urgent.

### Auto-allocate all pending requests
`POST /v1/delivery-requests/allocate` — no body. Returns count of allocated requests.

### Approve all allocations for a request at once
`POST /v1/delivery-requests/{id}/approve-all` — no body. Skips individual allocation approvals.

### Mark as delivered (only when status = in_transit)
`POST /v1/delivery-requests/{id}/deliver` — no body.

---

## Step 7 — Allocations

### List allocations
`GET /v1/allocations`

```
page=1&pageSize=20
```

### Approve an allocation (only when status = planned)
`POST /v1/allocations/{id}/approve` — no body.

> Urgent requests create allocations as `approved` — skip this step and go straight to dispatch.

### Reject an allocation (planned or approved only)
`POST /v1/allocations/{id}/reject`

```json
{
  "reason": "Insufficient transport capacity"
}
```

### Dispatch an allocation (only when status = approved)
`POST /v1/allocations/{id}/dispatch` — no body. When ALL allocations for a request are dispatched, request moves to `in_transit`.

---

## Step 8 — Nearest Stock & Audit

### Find nearest warehouse with stock
`GET /v1/stock/nearest`

```
resource_id=22&customer_id=3&needed=10
```

### Get audit log
`GET /v1/audit-log`

```
page=1&pageSize=20
```

---

## Health Check

`GET /health` — no auth, no body.

Expected response:
```json
{ "status": "healthy" }
```

---

## Quick End-to-End Flow

### AI alert → rebalancing
1. `POST /v1/auth/login` → copy token → Authorize
2. `POST /v1/ai/run` → triggers prediction immediately
3. `GET /v1/predictive-alerts` → find a critical alert, note its `proposal_id`
4. `GET /v1/rebalancing-proposals/{proposal_id}` → review suggested transfers
5. `POST /v1/rebalancing-proposals/{proposal_id}/approve`

### Normal delivery request (manual allocation)
1. `POST /v1/delivery-requests` with `priority: normal`
2. `POST /v1/delivery-requests/allocate` → allocates all pending
3. `GET /v1/allocations` → find allocation IDs, status = `planned`
4. `POST /v1/allocations/{id}/approve` (or `POST /v1/delivery-requests/{id}/approve-all`)
5. `POST /v1/allocations/{id}/dispatch` → when all dispatched, request = `in_transit`
6. `POST /v1/delivery-requests/{id}/deliver`

### Urgent delivery request (auto-approved, skip allocation step)
1. `POST /v1/delivery-requests` with `priority: urgent` + `arrive_till`
2. `GET /v1/allocations` → allocations already `approved`
3. `POST /v1/allocations/{id}/dispatch`
4. `POST /v1/delivery-requests/{id}/deliver`

### Audit trail
`GET /v1/audit-log` — every action above is recorded here.
