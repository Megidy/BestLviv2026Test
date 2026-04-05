# Frontend Architecture

## Overview

The LogySync frontend is a React 18 single-page application built with Vite, TypeScript, and Tailwind CSS. It connects to the Go backend via a thin REST client and renders a fully role-aware operations hub for warehouse managers, dispatchers, and workers.

**Stack:** React 18 · TypeScript · Vite · Tailwind CSS · Lucide Icons · Leaflet (map) · React Router v6

---

## Project Structure

```
frontend/src/
├── app/
│   ├── providers/       — AppProviders wrapper (auth context, router)
│   └── router/
│       ├── router.tsx   — Route definitions (createBrowserRouter)
│       ├── AppRouter.tsx
│       └── AuthGuard.tsx — Redirects unauthenticated users to /login
│
├── features/            — Self-contained feature modules
│   ├── auth/            — AuthProvider, useAuth hook, login logic
│   ├── alerts/          — useAlerts hook, AlertsModule, AlertRow component
│   ├── inventory/       — useInventory hook, InventoryModule, API client
│   └── map/             — useMap hook, MapView component, Leaflet integration
│
├── pages/               — Thin page wrappers (mount feature modules)
│   ├── Dashboard/
│   ├── Inventory/
│   ├── Map/
│   ├── Alerts/
│   ├── Delivery/        — Delivery requests list with status/priority badges
│   ├── Allocations/     — Allocation management with approve/reject/dispatch
│   ├── Admin/           — Audit log (admin only)
│   └── Settings/
│
├── shared/
│   ├── api/
│   │   ├── apiClient.ts — fetch wrapper with auth header injection
│   │   ├── endpoints.ts — all endpoint URLs in one place
│   │   └── types.ts     — all shared TypeScript types
│   ├── config/
│   │   └── navigation.ts — nav items with role visibility rules
│   ├── lib/
│   │   ├── cn.ts        — clsx + tailwind-merge utility
│   │   └── formatters.ts — date, percent, countdown formatters
│   └── ui/              — Headless UI components (Badge, Button, Card, Table, Input)
│
└── widgets/             — Layout-level components
    ├── Layout.tsx        — Root layout: sidebar + topbar + main content
    ├── Sidebar.tsx       — Navigation with role-based item filtering
    ├── Topbar.tsx        — Mobile hamburger + user info
    ├── MapPanel.tsx      — Map detail side panel
    └── ResourcePanel.tsx — Inventory resource detail panel
```

---

## Core Patterns

### API Layer

All HTTP calls go through a single `request()` function in `shared/api/apiClient.ts`. It:
- Reads the JWT token from localStorage
- Injects `Authorization: Bearer <token>` on every call
- Supports `query` params (serialised to `?key=value`), `method`, and `body`
- Returns the raw API envelope

Results are unwrapped with `unwrapApiResponse()`:

```ts
const response = await request<ApiResponse<DeliveryRequestsResponse>>(
  endpoints.requests.list,
  { query: { page: 1, pageSize: 50 } },
);
const data = unwrapApiResponse(response);
setRequests(data?.requests ?? []);
```

All endpoint strings live in `shared/api/endpoints.ts` — no URL literals in components.

### Feature Hooks

Each feature owns a custom hook that encapsulates loading state, error state, and data:

```ts
// Example: useAlerts()
const { alerts, proposals, isLoading, error, notice,
        pendingActionKeys, loadProposal,
        dismissAlert, approveProposal, dismissProposal, runAi } = useAlerts();
```

Hooks use `useCallback` + `useEffect` for loading, and expose action functions that set `pendingActionKeys[key]` while a mutation is in flight. This drives the "Approving…" / "Dispatching…" button states without extra state management.

### Optimistic / Pessimistic Updates

For high-frequency mutations (alert approve/dismiss), the hooks use **optimistic updates**: the local state is updated immediately, and rolled back if the server returns an error. For low-frequency mutations (allocation approve/reject), a full reload is issued after the mutation completes.

### Role-Based UI

The authenticated user's role (`worker`, `dispatcher`, `admin`) is available everywhere via `useAuth()`:

```ts
const { user } = useAuth();
const canManage = user?.role === 'dispatcher' || user?.role === 'admin';
```

Role hierarchy is enforced:
- `dispatcher` inherits all `worker` capabilities
- `admin` inherits all `dispatcher` and `worker` capabilities

Navigation items with `roles: ['admin', 'dispatcher']` are filtered in `Sidebar.tsx`. Pages with restricted content show a friendly forbidden screen instead of an error.

---

## Pages

### Dashboard (`/dashboard`)
At-a-glance summary. Loads data from multiple endpoints in parallel: inventory count, active alert count, pending requests, recent allocations.

### Inventory (`/inventory`)
Paginated, filterable grid of all resources at the authenticated user's warehouse. Clicking a resource opens a detail panel with full history. Dispatchers and admins can switch between warehouses.

### Map (`/map`)
Leaflet map with 60 pins (20 warehouses + 40 delivery points). Colour-coded by `status` field from `/v1/map/points`. Clicking a pin opens a side panel with inventory and alerts. Map auto-refreshes every 30s.

### Alerts (`/alerts`)
The AI prediction dashboard. Shows all open predictive alerts sorted by confidence. Each row can be expanded to show the WMA reasoning breakdown, time-to-shortfall, and the rebalancing proposal transfers. Dispatchers can approve or reject proposals inline. "Run predictive AI" button triggers `POST /v1/ai/run`.

On load, all proposals linked to visible alerts are fetched eagerly via `Promise.allSettled` — ensuring action buttons reflect the true server state without requiring manual expansion first.

### Delivery (`/delivery`)
Delivery request list with priority and status badges. All roles can create requests (dispatcher inherits worker functions). Status badges: pending=amber, allocated/in_transit=blue, delivered=green, cancelled=neutral.

### Allocations (`/allocations`)
Allocation management. Dispatchers and admins see Approve + Reject buttons for `planned` allocations, and a Dispatch button for `approved` allocations. Source warehouse and resource names are resolved from live API data (not hardcoded). Reject prompts for a reason string.

### Admin (`/admin`)
Audit log table — admins only. Full-text search across actor ID, role, action, and entity type. If a non-admin navigates here, a clean "Access restricted" screen is shown instead of an error.

### Settings (`/settings`)
Profile view and logout. Shows username, role, and assigned warehouse.

---

## Design System

### Colour Tokens (Tailwind config)

All colours are custom tokens defined in `tailwind.config.js`:

| Token | Usage |
|---|---|
| `background` | Page background (dark) |
| `surface` | Card / panel backgrounds |
| `border` | All borders |
| `text` | Primary text |
| `text-muted` | Secondary / label text |
| `primary` | Brand blue — active nav, primary buttons |
| `success` | Green — delivered, approved, healthy stock |
| `warning` | Amber — pending, elevated alerts |
| `danger` | Red — critical alerts, errors, reject actions |
| `info` | Blue — neutral informational badges |

### Component Library

All UI primitives live in `shared/ui/`:

- **Badge** — accepts a `tone` prop (`success`, `warning`, `danger`, `info`, `neutral`)
- **Button** — `variant` (`default`, `outline`, `ghost`) × `size` (`sm`, `md`)
- **Card / CardHeader / CardContent / CardTitle** — consistent panel layout
- **Table / TableHeader / TableRow / TableHead / TableCell / TableBody** — semantic table with hover states
- **Input** — controlled text input with consistent focus ring

### Responsive Layout

Every page renders two layouts:
- **Mobile (`lg:hidden`)** — card list, stacked layout, touch-friendly tap targets
- **Desktop (`hidden lg:block`)** — full table with sortable columns and inline action buttons

The sidebar collapses to a slide-in drawer on mobile, triggered by the hamburger button in the Topbar. Drawer closes on Escape key, backdrop click, or navigation.

---

## Authentication Flow

1. Unauthenticated users are redirected to `/login` by `AuthGuard`
2. Login calls `POST /v1/auth/login` → stores JWT in `localStorage`
3. `AuthProvider` decodes the token on mount to restore session
4. `useAuth()` exposes `user`, `login()`, and `logout()` everywhere
5. On logout, token is cleared and the user is redirected to `/login`

Token expiry is not yet handled client-side (the API returns 401, which surfaces as an error). A token refresh mechanism can be added without changing the component layer.

---

## State Management

There is no global state management library (no Redux, no Zustand). State lives at the feature hook level:

- **Server data** — fetched and cached inside hooks with `useState` + `useEffect`
- **UI state** — local `useState` in components (expanded rows, search terms, pending keys)
- **Auth state** — single `AuthContext` via React Context

This is intentional: the app's data is time-sensitive (stock levels, alerts) so caching aggressively would cause stale reads in a shared dispatcher environment. Hooks re-fetch on mount and after mutations.

---

## Build & Deploy

```bash
npm install
npm run dev      # local dev server on :5173
npm run build    # outputs to dist/
npm run lint     # ESLint + TypeScript checks
```

The Vite build is production-optimised: tree-shaking, code splitting by route, and asset hashing. The `dist/` folder is served as static files — currently served separately from the backend (not embedded in the Go binary).

### CI

Every PR touching `frontend/**` runs:
1. `npm run lint` — ESLint + TS type checks
2. `npm run build` — ensures the build compiles clean
3. `npm test` — Vitest unit tests (if any exist)
