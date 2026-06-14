# Kinly

Kinly is a cross-platform beauty, skincare, haircare, makeup, wellness, and fashion community app. Users can discover products, search brands and categories, read and write reviews, join discussions, receive notifications, and build reputation.

This repository is a greenfield MVP monorepo with:

- Flutter mobile/web app using Riverpod, GoRouter, and Dio
- Go backend using Gin
- PostgreSQL database
- JWT authentication
- PostgreSQL full-text search
- S3-compatible image storage setup through MinIO for local development

## Project Structure

```text
Kinly/
  backend/          Go API server
  database/         PostgreSQL migrations and seed data
  docs/             API and architecture notes
  mobile/           Flutter app
  scripts/          Local helper scripts
  docker-compose.yml
```

## Prerequisites

Install these before running the full project:

- Go 1.26+
- Flutter 3.44+
- Docker Desktop
- Xcode if you want to run iOS locally

Check your setup:

```sh
go version
flutter --version
docker --version
docker compose version
```

## Local Services

The Docker stack runs:

| Service | URL / Port | Purpose |
| --- | --- | --- |
| Backend API | `http://127.0.0.1:8080` | Go/Gin REST API |
| PostgreSQL | `localhost:5432` | App database |
| MinIO API | `http://127.0.0.1:9000` | Local S3-compatible storage |
| MinIO Console | `http://127.0.0.1:9001` | Storage admin UI |

MinIO local credentials:

```text
username: kinly
password: kinlysecret
```

## Start the Backend Stack

From the repository root:

```sh
cd /Users/teetasbhuiya/Developer/Kinly
docker compose up --build -d
```

Check status:

```sh
docker compose ps
```

Check backend health:

```sh
curl http://127.0.0.1:8080/health
```

Expected response:

```json
{"status":"ok"}
```

## Database Setup

For a fresh database, apply the migration and seed data.

If `psql` is installed locally:

```sh
cd /Users/teetasbhuiya/Developer/Kinly
scripts/migrate.sh
scripts/seed.sh
```

If you do not have local `psql`, use the Postgres Docker container:

```sh
cd /Users/teetasbhuiya/Developer/Kinly
docker compose cp database/migrations/000001_init.up.sql postgres:/tmp/000001_init.up.sql
docker compose exec -T postgres psql -U kinly -d kinly -v ON_ERROR_STOP=1 -f /tmp/000001_init.up.sql
docker compose cp database/seeds/000001_seed.sql postgres:/tmp/000001_seed.sql
docker compose exec -T postgres psql -U kinly -d kinly -v ON_ERROR_STOP=1 -f /tmp/000001_seed.sql
```

Do not rerun the migration on the same database unless you reset the database first, because the tables already exist.

## Start the Flutter UI

For the browser UI:

```sh
cd /Users/teetasbhuiya/Developer/Kinly/mobile
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Open:

```text
http://127.0.0.1:3000
```

To stop Flutter Web, press `q` in the Flutter terminal.

For iOS Simulator, first make sure Flutter sees an iOS device:

```sh
flutter doctor
flutter devices
```

Then run:

```sh
cd /Users/teetasbhuiya/Developer/Kinly/mobile
flutter run -d ios --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

For Android emulator:

```sh
cd /Users/teetasbhuiya/Developer/Kinly/mobile
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Use `10.0.2.2` for Android emulator because it maps to your host machine.

## Demo Account

A smoke-test account may exist if the local signup test was run:

```text
email: smoke@kinly.local
password: password123
```

If it does not exist, create a new account from the app login screen.

## Useful API Checks

```sh
curl http://127.0.0.1:8080/products
curl 'http://127.0.0.1:8080/products/search?q=serum'
curl -X POST http://127.0.0.1:8080/signup \
  -H 'Content-Type: application/json' \
  -d '{"email":"you@example.com","username":"yourname","password":"password123"}'
```

## Tests and Quality Checks

Backend:

```sh
cd /Users/teetasbhuiya/Developer/Kinly/backend
go test ./...
```

Flutter:

```sh
cd /Users/teetasbhuiya/Developer/Kinly/mobile
flutter analyze
flutter test
```

All checks together:

```sh
cd /Users/teetasbhuiya/Developer/Kinly
scripts/test.sh
```

## Stop or Reset Local Services

Stop containers but keep database data:

```sh
docker compose down
```

Stop containers and delete local database/storage volumes:

```sh
docker compose down -v
```

After `docker compose down -v`, run the database migration and seed steps again.

## Troubleshooting

If `docker` is not found:

```sh
brew install --cask docker
```

Then open Docker Desktop and wait until the engine is running.

If Flutter cannot see iOS Simulator:

```sh
open -a Simulator
flutter doctor
flutter devices
```

If port `3000` is already in use:

```sh
lsof -nP -iTCP:3000 -sTCP:LISTEN
```

Stop the old Flutter process or run Flutter on another port:

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3001 --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

If the app UI loads but data is empty, confirm the backend and database are running:

```sh
docker compose ps
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/products
```

## Current MVP Features

- Five-tab Flutter app shell: Home, Explore, Community, Notifications, Profile
- Home search bar that routes into Explore
- Product list, product search, product detail, review list, and review creation
- Auth signup/login/logout with JWT
- User profile view/edit
- Community posts, comments, voting, and reporting API support
- In-app notification API support
- PostgreSQL full-text product and post search
- Reputation/trust score recalculation foundation
