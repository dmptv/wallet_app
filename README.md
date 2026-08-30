# wallet_app

A Flutter wallet application built with Riverpod. It shows the balance,
transaction history, and network status for an Ethereum address.

## Screens

1. **Wallet Home** (`lib/home_screen.dart`) — wallet balance (live, from
   Blockscout), four action buttons (Receive/Send/Scan QR are placeholders,
   History navigates to Transaction History), and a network status bar with
   the watched address at the bottom.
2. **Transaction History** (`lib/features/transactions/`) — real on-chain
   transaction history via the Blockscout API, filterable by direction
   (All/Incoming/Outgoing), offline-first (cached locally, refreshed in the
   background, with an offline banner when the refresh fails).
3. **Network Status** (`lib/features/network_status/`) — a peer map (world
   outline SVG with plotted pins), a latency chart, and a peer list, all
   driven by a simulated peer service polling every 3 seconds.

## Tech Stack

- Flutter / Dart
- Riverpod (`flutter_riverpod`) for state management
- `http` for networking (Blockscout API)
- `flutter_svg` for map rendering
- `shared_preferences` for the local transaction cache
- `BigInt` (built into Dart) for exact wei amounts

## Riverpod Patterns

- **`ref.select`** — granular rebuild control (summary cards, filter chips,
  and the offline banner each watch only the field they need)
- **Deep provider graphs** — up to 6 levels (raw → filter → filtered →
  grouped → totals → derived) across two independent features
- **`ProviderObserver`** — `lib/core/logging_observer.dart` logs every state
  change across the app
- **Tests via `ProviderContainer`** — `test/balance_notifier_test.dart`
  (concurrent refresh, timer/dispose) and
  `test/features/transactions/offline_first_test.dart` (cache-first +
  offline fallback) with multiple overrides
- **`AsyncNotifier` + `Timer.periodic`** — live polling with proper cleanup
  in `onDispose` (balance, transactions, network peers)
- **Offline-first** — local cache renders immediately, a background refresh
  syncs silently, and a failed refresh degrades gracefully instead of
  losing data

## Roadmap

- DevTools integration (beyond the built-in Riverpod inspector)
- Analytics wired through `ProviderObserver`
- Crash reporting wired through `ProviderObserver`

## Getting Started

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter test
```
