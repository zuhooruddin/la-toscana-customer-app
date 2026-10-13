# La Toscana — customer app (Android / iOS)

Flutter app for ordering from La Toscana Pizzeria. Same backend, database and rules as the website (`la-toscana-backend`, `/api/v1`):
prices, availability, opening hours and scheduled times always come from the server, and orders appear instantly in the admin
dashboard.

## Features

- Restaurant + pickup/delivery selection (per-restaurant prices and availability)
- Home: banners (managed in the dashboard), categories with photos, featured dishes
- Menu with search, product page with option groups (required/optional, max per group, dynamic max e.g. scoops → flavours,
  pasta-type photos, gluten-free warning), notes and quantity
- Cart (persisted on the device, one restaurant at a time)
- Checkout: server-side quote, as soon as possible or a scheduled time (`GET /orders/slots`), contact details, delivery
  address when the restaurant delivers, "if an item is sold out" preference, promo code, cash payment, terms; idempotent submit
- Live order tracking (Socket.IO room + periodic resync), cancel while allowed
- Account: sign in / register (optional — guests can order), order history, language ES/EN, delete account (GDPR)
- Restaurants: hours, call, directions, book a table; table bookings with live availability

Not included yet (needs the client's accounts, never faked): card payments in the app (Stripe keys), push notifications
(Firebase project). Card payment works on the website once Stripe is configured.

## Run

```bash
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:4000          # Android emulator → local API
flutter run --dart-define=API_URL=https://api.example.com --dart-define=WEBSITE_URL=https://www.latoscanapizzeria.es
```

Debug builds allow plain HTTP to a local API; release builds are HTTPS only. Tokens are stored in the platform keystore
(`flutter_secure_storage`).

For a physical Android phone over USB (with the backend running on port 4000):

```bash
adb reverse tcp:4000 tcp:4000
flutter run --dart-define=API_URL=http://127.0.0.1:4000
```

Repeat `adb reverse` after reconnecting the phone. `10.0.2.2` is for the Android
emulator only. An API URL change requires a full restart of the app run.

## Checks

```bash
flutter analyze
flutter test
flutter build apk --release --dart-define=API_URL=…   # needs the client's signing key (see project-docs, Q-012/Q-016)
```

Bundle id is `es.latoscana.la_toscana_customer` until the owner decides whether to replace the existing store listing
(`com.latoscana.pizzeria`, DECISIONS Q-016).
