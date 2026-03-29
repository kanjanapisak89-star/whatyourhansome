# ── Stage 1: Build Flutter web ────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy dependency manifests first for better layer caching
COPY pubspec.yaml pubspec.lock ./

# Fetch dependencies
RUN flutter pub get

# Copy the rest of the source
COPY . .

# Build Flutter web with CanvasKit renderer for consistent cross-browser rendering
# --dart-define allows injecting env vars at build time if needed
RUN flutter build web \
      --release \
      --web-renderer canvaskit \
      --no-tree-shake-icons

# ── Stage 2: Serve with nginx ──────────────────────────────────────────────────
FROM nginx:alpine AS runner

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built Flutter web output
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom nginx config (SPA routing + security headers)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
