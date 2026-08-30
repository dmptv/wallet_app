# wallet_app

A Flutter wallet application built with Riverpod. It shows the balance,
transaction history, and network status for an Ethereum address.

## Features

- **Wallet Home** — balance overview and quick actions
- **Transaction History** — on-chain transaction history via the Blockscout API, offline-first (cached locally, refreshed in the background)
- **Network Status** — live peer map, latency chart, and peer list

## Tech Stack

- Flutter
- Riverpod (`flutter_riverpod`) for state management
- `http` for networking
- `flutter_svg` for map rendering
- `shared_preferences` for local transaction cache

## Getting Started

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter test
```
