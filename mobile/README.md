# LogiSync Mobile

Flutter mobile client for worker/dispatcher delivery and predictive flows.

## Run

Use a secure API base URL explicitly:

```bash
flutter run --dart-define=LOGISYNC_API_BASE_URL=https://your-api-host
```

For local HTTP backend (optional override):

```bash
flutter run \
  --dart-define=LOGISYNC_API_BASE_URL=http://localhost:8080 \
  --dart-define=LOGISYNC_ALLOW_INSECURE_HTTP=true
```

Note: in debug/profile builds HTTP is allowed by default. In release builds HTTPS is enforced unless `LOGISYNC_ALLOW_INSECURE_HTTP=true` is set.

## Quality Commands

```bash
flutter pub get
flutter analyze
flutter test
```

Integration tests:

```bash
flutter test test/integration
```
