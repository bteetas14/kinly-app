# Kinly Mobile

Flutter client for Kinly.

## Run in Browser

```sh
cd /Users/teetasbhuiya/Developer/Kinly/mobile
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Open:

```text
http://127.0.0.1:3000
```

## Build for Web Production

```sh
flutter build web --release
```

Production web builds use `/api` by default. Configure the web host to proxy `/api/*` to the Kinly backend, or pass `--dart-define=API_BASE_URL=https://your-api-domain.example` for a separate API domain.

## Run on iOS

```sh
open -a Simulator
flutter devices
flutter run -d ios --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

If no iOS device appears, run:

```sh
flutter doctor
```

## Run on Android Emulator

```sh
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Checks

```sh
flutter analyze
flutter test
```

## Backend Requirement

The app expects the Kinly backend to be running. From the repository root:

```sh
docker compose up --build -d
```
