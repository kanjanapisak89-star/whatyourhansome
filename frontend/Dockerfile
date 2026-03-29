# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# ---------------------------------------------------------------------------
# Build-time arguments — set these as Railway environment variables so they
# are injected at image build time via --dart-define and compiled into the
# Flutter web bundle. None of these have defaults here; they must be supplied
# by the CI/CD environment (Railway → Variables).
# ---------------------------------------------------------------------------
ARG FIREBASE_API_KEY
ARG FIREBASE_PROJECT_ID
ARG FIREBASE_APP_ID
ARG FIREBASE_MESSAGING_SENDER_ID
ARG FIREBASE_AUTH_DOMAIN
ARG FIREBASE_STORAGE_BUCKET
ARG API_BASE_URL

# Copy pubspec files
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Enable web platform
RUN flutter config --enable-web

# Create web platform files if not exists
RUN flutter create . --platforms web

# Build web app — pass Railway env vars as --dart-define so Dart's
# String.fromEnvironment() resolves them at compile time.
RUN flutter build web --release \
    --dart-define=FIREBASE_API_KEY="${FIREBASE_API_KEY}" \
    --dart-define=FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID}" \
    --dart-define=FIREBASE_APP_ID="${FIREBASE_APP_ID}" \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID="${FIREBASE_MESSAGING_SENDER_ID}" \
    --dart-define=FIREBASE_AUTH_DOMAIN="${FIREBASE_AUTH_DOMAIN}" \
    --dart-define=FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET}" \
    --dart-define=API_BASE_URL="${API_BASE_URL}"

# Runtime stage - serve with nginx
FROM nginx:alpine

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
