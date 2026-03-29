# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Set build-time environment variables
ARG API_BASE_URL=http://localhost:8080
ENV API_BASE_URL=$API_BASE_URL

# Copy pubspec files
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy source code (exclude .env files)
COPY . .

# Remove any .env files to prevent them from being included in web build
RUN find . -name ".env" -type f -delete

# For web builds, environment variables should be set at compile time
# or passed as constants. We don't create .env files for web deployment.

# Enable web platform
RUN flutter config --enable-web

# Create web platform files if not exists
RUN flutter create . --platforms web

# Build web app (removed --web-renderer flag as it's deprecated in newer Flutter versions)
RUN flutter build web --release

# Runtime stage - serve with nginx
FROM nginx:alpine

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
