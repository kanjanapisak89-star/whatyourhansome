#!/bin/bash

# Loft Platform Setup Script
# This script sets up the complete development environment

set -e

echo "🚀 Loft Platform Setup"
echo "======================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Backend Setup
echo "📦 Setting up Backend..."
echo ""

cd backend

# Check Go
if ! command_exists go; then
    echo -e "${RED}❌ Go is not installed${NC}"
    echo "Please install Go from https://golang.org/dl/"
    exit 1
fi
echo -e "${GREEN}✓${NC} Go installed: $(go version)"

# Install dependencies
echo "Installing Go dependencies..."
go mod download
echo -e "${GREEN}✓${NC} Go dependencies installed"

# Check PostgreSQL
if ! command_exists psql; then
    echo -e "${YELLOW}⚠${NC}  PostgreSQL CLI not found"
    echo "Starting PostgreSQL with Docker..."
    docker-compose up -d postgres
else
    echo -e "${GREEN}✓${NC} PostgreSQL available"
fi

# Wait for PostgreSQL
echo "Waiting for PostgreSQL to be ready..."
sleep 3

# Run migrations
echo "Running database migrations..."
if command_exists migrate; then
    migrate -path migrations -database "postgresql://postgres:postgres@localhost:5432/loft?sslmode=disable" up
    echo -e "${GREEN}✓${NC} Migrations completed"
else
    echo -e "${YELLOW}⚠${NC}  migrate CLI not found"
    echo "Install with: go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest"
fi

# Create .env if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env file"
    echo -e "${YELLOW}⚠${NC}  Please update .env with your Firebase credentials"
fi

cd ..

# Frontend Setup
echo ""
echo "📱 Setting up Frontend..."
echo ""

cd frontend

# Check Flutter
if ! command_exists flutter; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo -e "${GREEN}✓${NC} Flutter installed: $(flutter --version | head -n 1)"

# Install dependencies
echo "Installing Flutter dependencies..."
flutter pub get
echo -e "${GREEN}✓${NC} Flutter dependencies installed"

# Create .env if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env file"
    echo -e "${YELLOW}⚠${NC}  Please update .env with your Firebase and API credentials"
fi

# Create asset directories
mkdir -p assets/images assets/icons
echo -e "${GREEN}✓${NC} Created asset directories"

cd ..

# Summary
echo ""
echo "✨ Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo ""
echo "1. Backend:"
echo "   cd backend"
echo "   # Update .env with Firebase credentials"
echo "   go run cmd/server/main.go"
echo ""
echo "2. Frontend:"
echo "   cd frontend"
echo "   # Update .env with Firebase and API credentials"
echo "   flutter run"
echo ""
echo "3. Optional - Generate splash screens:"
echo "   cd frontend"
echo "   flutter pub run flutter_native_splash:create"
echo ""
echo "📚 Documentation:"
echo "   - README.md - Complete project documentation"
echo "   - QUICK_START.md - Quick start guide"
echo "   - DATABASE_SCHEMA.md - Database documentation"
echo "   - FLUTTER_STRUCTURE.md - Frontend architecture"
echo ""
echo "🎉 Happy coding!"
