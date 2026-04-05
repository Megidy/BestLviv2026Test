# LogiSync Mobile — Warehouse Worker App

## Overview

LogiSync Mobile is a Flutter application built for **warehouse workers operating in the field**. It targets the core brief requirement: *"зручність використання в складських приміщеннях"* (convenience of use in warehouse premises).

A warehouse worker is not sitting at a desktop. They have gloves on, poor lighting, and a phone in one hand. The mobile app is designed for exactly that environment: large tap targets, high contrast, minimal text input, and a QR scan workflow that turns what used to be a multi-step lookup into a single camera scan followed by two taps.

**Platform:** Flutter 3 · Dart · iOS · Android  
**API:** Same backend as the web app — `https://api.logisync.systems`  
**Version:** 1.0.0

---

## Why Flutter

- **Single codebase, two platforms** — identical experience on iOS and Android from one Dart codebase
- **Native camera access** — required for QR scanning; Flutter's plugin ecosystem (e.g. `mobile_scanner`) gives full camera control without a WebView
- **Offline-capable** — Flutter apps can run full logic locally and sync when connectivity returns
- **No App Store required for demos** — APK sideloading on Android, TestFlight on iOS

---

## Feature Set

### 1. QR Code Scanning

The primary input method. Every resource shelf in a warehouse has a printed QR label. The worker taps **Scan**, points the camera, and the app:

1. Decodes the payload
2. Fetches current stock + alert status for that resource at that warehouse
3. Opens the Quick Action screen in under one second

**QR payload format:**
```
RESOURCE:{resource_id}:POINT:{point_id}

Example: RESOURCE:17:POINT:3
```

The format is intentionally simple and URL-safe. The same QR codes can be scanned by any QR reader and interpreted manually — no proprietary encoding.

**Alternative inputs (planned):**
- Bluetooth HID barcode scanner (acts as a keyboard, no extra code)
- NFC tag tap (Web NFC API / flutter_nfc_kit)

---

### 2. Quick Action Screen

After scanning, the worker sees a focused single-resource screen — no navigation chrome, no sidebars:

```
┌──────────────────────────────────────┐
│  Бензин А-95                         │
│  Склад Київ-Центральний              │
│                                      │
│  Current stock: 340 L                │
│  Status: ▲ ELEVATED                  │
│                                      │
│  ┌─────────────────────────────────┐ │
│  │       + Update demand           │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │       ⚡ Flag as URGENT          │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │       ✓ Confirm delivery        │ │
│  └─────────────────────────────────┘ │
└──────────────────────────────────────┘
```

Three actions maximum. Each requires at most one additional input (a quantity field or a confirmation tap). No forms, no dropdowns.

---

### 3. Demand Update Flow

Minimum steps to record a demand reading:

```
Step 1  Scan QR code (or select resource from list)
Step 2  Current stock shown → enter new quantity via large numeric keypad
        OR tap NORMAL / ELEVATED / CRITICAL level button
Step 3  Tap CONFIRM (one large green button)

→ POST /v1/demand-readings
→ AI analysis triggered in the background
→ Alert may appear on the dispatcher's dashboard within seconds
```

The numeric keypad is rendered as a custom large-button grid — not the system keyboard — to work with gloves and maximize tap accuracy.

---

### 4. Delivery Request Creation

Workers can create delivery requests directly from the mobile app:

- Select destination (customer location), resource, and quantity
- Priority defaults to `normal`; can be escalated to `urgent` with one tap
- Urgent requests trigger immediate auto-allocation on the backend
- Confirmation shown with request ID for reference

Mirrors `POST /v1/delivery-requests` on the backend.

---

### 5. My Requests

Workers see only their own requests (enforced by the backend for the `worker` role). Status badges match the web app: pending=amber, in_transit=blue, delivered=green.

Includes pull-to-refresh for natural mobile interaction.

---

### 6. Inventory View

Browse current stock at the worker's assigned warehouse. Filterable by category. Tapping a resource opens the Quick Action screen (same flow as QR scan but without the camera step).

---

## Architecture

```
lib/
├── main.dart                  — App entry, MaterialApp, theme, routing
│
├── core/
│   ├── api/
│   │   ├── api_client.dart    — Dio HTTP client, auth token injection
│   │   └── endpoints.dart     — All API endpoint constants
│   ├── auth/
│   │   ├── auth_service.dart  — Login, token storage (flutter_secure_storage)
│   │   └── auth_provider.dart — ChangeNotifier for auth state
│   └── models/                — Dart model classes matching API types
│       ├── delivery_request.dart
│       ├── inventory_item.dart
│       ├── predictive_alert.dart
│       └── demand_reading.dart
│
├── features/
│   ├── scan/
│   │   ├── scan_page.dart     — Camera view, QR decode, navigation on success
│   │   └── quick_action_page.dart — Post-scan action screen
│   ├── inventory/
│   │   ├── inventory_page.dart
│   │   └── resource_card.dart
│   ├── delivery/
│   │   ├── delivery_list_page.dart
│   │   └── create_request_page.dart
│   └── auth/
│       └── login_page.dart
│
└── shared/
    ├── widgets/
    │   ├── status_badge.dart   — Colour-coded status chip
    │   ├── action_button.dart  — Large full-width tap target (min 48px height)
    │   └── numeric_keypad.dart — Custom glove-friendly keypad
    └── theme/
        └── app_theme.dart      — High-contrast dark theme
```

---

## State Management

**Provider** (`package:provider`) — lightweight, idiomatic for mid-size Flutter apps. No overkill (no BLoC, no Riverpod) for the feature scope of this app.

- `AuthProvider` — token, current user, login/logout
- `InventoryProvider` — current warehouse stock, refresh
- `DeliveryProvider` — request list, create, status updates

---

## API Integration

The mobile app connects to the same backend as the web app:

```
https://api.logisync.systems
```

Auth flow:
1. `POST /v1/auth/login` → JWT stored in `flutter_secure_storage` (keychain on iOS, Keystore on Android)
2. All subsequent requests include `Authorization: Bearer <token>`
3. 401 response → clear token, redirect to login

Key endpoints used:

| Feature | Endpoint |
|---|---|
| Login | `POST /v1/auth/login` |
| My profile | `GET /v1/auth/me` |
| Warehouse inventory | `GET /v1/inventory/:location_id` |
| Record demand | `POST /v1/demand-readings` |
| My requests | `GET /v1/delivery-requests` |
| Create request | `POST /v1/delivery-requests` |
| Predictive alerts | `GET /v1/predictive-alerts` |

---

## Design Principles

Every UI decision is driven by warehouse conditions:

| Principle | Implementation |
|---|---|
| Min tap target 48×48 px | All buttons use `SizedBox(height: 56)` minimum |
| Large readable text | Body text 16 sp minimum, headings 20+ sp |
| High contrast | Dark background (#0F172A) with white text and vibrant accent colours |
| Bottom navigation | Primary nav in thumb-reachable zone (bottom sheet / BottomNavigationBar) |
| Glove-safe keypad | Custom numeric grid, no small system keyboard |
| No hover states | Flutter on mobile never renders hover — no workaround needed |
| Status never colour-only | Every status badge has a text label alongside the colour |

---

## QR Label Generation (Admin Web)

Admins generate printable QR sheets from the web admin panel. Each label encodes:

```
RESOURCE:{resource_id}:POINT:{point_id}
```

Labels are printed as a CSS grid with QR image + human-readable name beneath. Workers stick them on shelves once — no hardware cost, no RFID.

---

## Running Locally

### Prerequisites
- Flutter 3.x (`flutter --version`)
- Android Studio (for Android) or Xcode (for iOS)
- A device or emulator

### Setup

```bash
cd mobile
flutter pub get
flutter run                    # runs on connected device/emulator
flutter run -d chrome          # web target (limited — no camera access)
```

### Build

```bash
# Android APK (for sideloading / demo)
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release

# macOS desktop
flutter build macos --release
```

### Environment

The API base URL is set in `lib/core/api/endpoints.dart`. For production it points to `https://api.logisync.systems`. For local development, change it to `http://localhost:8080`.

---

## Demo Script

1. Install the APK on an Android phone (sideload via USB or QR share)
2. Login as `worker1_w1` / `secret`
3. Show the inventory list for Kyiv Central warehouse
4. Tap **Scan** — camera opens
5. Scan a printed QR label (or a QR displayed on another screen showing `RESOURCE:17:POINT:1`)
6. Quick Action screen appears with current stock and status
7. Tap **Update demand** → enter quantity 80 → tap CONFIRM
8. Switch to the dispatcher's desktop browser → open Alerts → show new alert appeared automatically

The cross-device, real-time update (phone action → alert on desktop within seconds) is the strongest 30-second demo sequence.

---

## Scalability Path

- **Bluetooth HID scanners** — Zebra or Honeywell handheld scanners emit keypresses; no code change, just connect via Bluetooth
- **NFC tags** — `flutter_nfc_kit` reads NFC chips encoded with the same payload format; workers tap instead of scan
- **Offline queue** — `hive` or `drift` local database + background sync; actions recorded locally, flushed when connectivity returns
- **Push notifications** — `firebase_messaging` for real-time alert delivery to workers without polling

---

## Accessibility

- All interactive elements have `semanticsLabel` set
- Status indicators combine colour + icon + text (WCAG AA colour-blind safe)
- `MediaQuery.textScaleFactor` respected — system font size preferences honoured
- Supports `prefers-reduced-motion` equivalent via `AnimationController` checks on `AccessibilityFeatures.disableAnimations`
