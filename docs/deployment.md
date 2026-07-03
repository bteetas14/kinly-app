# Production Deployment

This guide describes the production-ready path for Kinly Web and API.

## Required Values

Create `backend/.env.production` from `backend/.env.production.example` and replace every placeholder.

Required production settings:

- `APP_ENV=production`
- `DATABASE_URL` for the production PostgreSQL database
- `JWT_SECRET` with at least 32 random characters
- `CORS_ALLOWED_ORIGINS` with the exact HTTPS web origin, for example `https://kinly.example.com`
- `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, and `S3_REGION`

The API refuses to boot in production when these values are missing, local-only, or permissive.

## Build

Build the backend image:

```sh
cd /Users/teetasbhuiya/Developer/Kinly
docker build -t kinly-api:latest backend
```

Build the Flutter website. The default API base is `/api`, which matches the included Nginx reverse proxy config.

```sh
cd /Users/teetasbhuiya/Developer/Kinly/mobile
flutter build web --release
```

If the API is hosted on a separate domain, pass the full API URL instead:

```sh
flutter build web --release --dart-define=API_BASE_URL=https://api.kinly.example.com
```

## Run Migrations

Run migrations before starting a new API version:

```sh
cd /Users/teetasbhuiya/Developer/Kinly
KINLY_API_IMAGE=kinly-api:latest docker compose -f docker-compose.production.yml --profile migrate run --rm migrate
```

## Serve Web and API

The provided production compose file serves Flutter Web through Nginx and proxies `/api/*` to the backend service.

```sh
cd /Users/teetasbhuiya/Developer/Kinly
KINLY_API_IMAGE=kinly-api:latest docker compose -f docker-compose.production.yml up -d backend web
```

For a managed host, copy the same behavior:

- Serve `mobile/build/web` as static files.
- Rewrite unknown web routes to `index.html`.
- Proxy `/api/*` to the backend, stripping the `/api` prefix.
- Terminate TLS at the load balancer, CDN, or reverse proxy.
- Set `CORS_ALLOWED_ORIGINS` to the public HTTPS web origin.

## Mobile Release Signing

Android release signing uses `mobile/android/key.properties`, which is intentionally ignored by git.

Example:

```properties
storeFile=upload-keystore.jks
storePassword=replace-me
keyAlias=upload
keyPassword=replace-me
```

Place the keystore under `mobile/android/` or use a path relative to that directory.

iOS uses bundle id `com.kinly.app`; configure the production Apple team, signing certificate, and provisioning profile in Xcode or CI.

## Smoke Checks

After deployment:

```sh
curl https://kinly.example.com/api/health
curl https://kinly.example.com/api/products
```

Then open the website and verify:

- Browser refresh works on nested routes such as `/products/{id}`.
- Signup/login succeeds.
- Product, brand, community, notification, and profile screens load without console errors.
