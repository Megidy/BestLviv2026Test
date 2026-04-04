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

### Create a delivery request
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

Valid priorities: `normal`, `elevated`, `critical`, `urgent`

`arrive_till` is optional:
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

Note: `urgent` priority triggers immediate auto-allocation.

### List delivery requests
`GET /v1/delivery-requests`

```
page=1&pageSize=20
```

### Get a single request
`GET /v1/delivery-requests/{id}` — no body.

### Cancel a request
`POST /v1/delivery-requests/{id}/cancel` — no body.

### Escalate priority
`POST /v1/delivery-requests/{id}/escalate` — no body.

### Update item quantity
`PATCH /v1/delivery-requests/{id}/items`

```json
{
  "resource_id": 22,
  "quantity": 15
}
```

### Auto-allocate all pending requests
`POST /v1/delivery-requests/allocate` — no body.

### Approve all allocations for a request
`POST /v1/delivery-requests/{id}/approve-all` — no body.

### Mark as delivered
`POST /v1/delivery-requests/{id}/deliver` — no body.

---

## Step 7 — Allocations

### List allocations
`GET /v1/allocations`

```
page=1&pageSize=20
```

### Approve an allocation
`POST /v1/allocations/{id}/approve` — no body.

### Reject an allocation
`POST /v1/allocations/{id}/reject`

```json
{
  "reason": "Insufficient transport capacity"
}
```

### Dispatch an allocation
`POST /v1/allocations/{id}/dispatch` — no body.

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

1. `POST /v1/auth/login` → copy token → Authorize
2. `POST /v1/ai/run` → wait 1-2 seconds
3. `GET /v1/predictive-alerts` → find a critical alert, note its `proposal_id`
4. `GET /v1/rebalancing-proposals/{proposal_id}` → review transfers
5. `POST /v1/rebalancing-proposals/{proposal_id}/approve` → approved
6. `POST /v1/delivery-requests` with `priority: urgent` → auto-allocated
7. `GET /v1/delivery-requests` → see the new request
8. `GET /v1/audit-log` → see the full trail
