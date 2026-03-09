# TripPulse

Trip planning app built with Flutter.

## Core Features (A1)
- Authentication: Email/Password + Google Sign-In
- Trip CRUD: create, view, edit, delete trip
- Itinerary by day: add and manage activities
- Place search: Geoapify-powered destination and attraction lookup
- Map view: route and activity markers per trip/day
- Weather + currency helpers in trip flow

## Project Structure (B1)
```text
lib/
  app.dart
  main.dart
  config/
  itenaries/
    models/
    screens/
  maps/
    screens/
    services/
  places/
    models/
    screens/
    services/
    widgets/
  trips/
    models/
    screens/
    services/
    widgets/
  users/
    screens/
    services/
  widgets/
```

## Setup
1. Install Flutter (stable channel) and run:
```bash
flutter --version
```
2. Install dependencies:
```bash
flutter pub get
```
3. Create `.env` from `.env.example` and set your API key:
```bash
cp .env.example .env
```
4. Configure Firebase for your target platform.

## Run
```bash
flutter run
```

## Quality Gates (B5)
Run before submission:
```bash
flutter analyze
flutter test
```

## Test Layout
Tests are split by module:
- `test/trips/`
- `test/itinerary/`
- `test/map/`
- `test/places/`
- `test/users/`

## Demo Evidence (A6)
- Demo video: `<add-video-link-here>`
- Screenshots:
  - `<add-screenshot-login>`
  - `<add-screenshot-trip-list>`
  - `<add-screenshot-itinerary>`
  - `<add-screenshot-map>`
  - `<add-screenshot-place-search>`

## Notes
- Do not commit real keys in `.env`.
- Keep Firestore rules configured for authenticated user data access.
