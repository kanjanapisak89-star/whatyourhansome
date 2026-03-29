# Quick Start Guide

## What's Been Built

### ✅ Completed

1. **Database Schema** (PostgreSQL)
   - 7 tables: users, posts, reactions, comments, board_questions, audit_logs, post_stats
   - Materialized view for performance
   - Complete migrations (up/down)
   - Indexes and triggers configured

2. **Backend API** (Golang + Connect-RPC)
   - Protobuf definitions for 4 services
   - Service implementations (Public, Member, Admin, Auth)
   - SQL queries defined (sqlc ready)
   - Firebase Auth integration structure
   - Main server with CORS and routing

3. **Flutter App** (Material 3 + Riverpod)
   - Project structure with feature-based architecture
   - Theme matching UI design (dark mode)
   - Core screens: Feed, Post Detail, Board, Profile, Login
   - Reusable widgets: PostCard, ShimmerPostCard
   - Router configuration
   - Dependencies configured

4. **Documentation**
   - DATABASE_SCHEMA.md - Complete schema docs
   - IMPLEMENTATION_PLAN.md - Development roadmap
   - FLUTTER_STRUCTURE.md - Frontend architecture
   - README.md - Full project documentation

## 🚀 Run It Now

### 1. Start Backend (5 minutes)

```bash
# Terminal 1: Start PostgreSQL
cd backend
docker-compose up -d postgres

# Run migrations
migrate -path migrations -database "postgresql://postgres:postgres@localhost:5432/loft?sslmode=disable" up

# Start server
go run cmd/server/main.go
```

Backend will be at `http://localhost:8080`

### 2. Start Flutter App (3 minutes)

```bash
# Terminal 2: Run Flutter
cd frontend

# Create .env file
cp .env.example .env
# Edit .env with your Firebase credentials

# Get dependencies
flutter pub get

# (Optional) Generate splash screen assets
# See frontend/generate_placeholder_assets.md for quick logo creation
# Or skip - app has built-in animated splash

# Generate native splash screens (if you have assets)
flutter pub run flutter_native_splash:create

# Run app
flutter run
```

## 📋 What to Do Next

### Phase 1: Complete Backend (1-2 hours)

1. **Generate Protobuf Code**
   ```bash
   cd backend
   # Install buf if needed
   go install github.com/bufbuild/buf/cmd/buf@latest
   buf generate
   ```

2. **Generate sqlc Code**
   ```bash
   # Install sqlc
   go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
   sqlc generate
   ```

3. **Implement Service Methods**
   - Replace TODO comments in `internal/service/*.go`
   - Use generated sqlc queries
   - Add error handling

4. **Test Endpoints**
   ```bash
   # Test public endpoint
   curl -X POST http://localhost:8080/loft.v1.PublicService/GetFeed \
     -H "Content-Type: application/json" \
     -d '{"page": 1, "page_size": 20}'
   ```

### Phase 2: Complete Flutter App (2-3 hours)

1. **Setup Firebase**
   - Create Firebase project
   - Enable Google/Facebook auth
   - Download `google-services.json` (Android)
   - Download `GoogleService-Info.plist` (iOS)
   - Update `.env` with credentials

2. **Generate Protobuf Dart Code**
   ```bash
   cd frontend
   # Install protoc plugin
   dart pub global activate protoc_plugin
   
   # Generate from backend proto files
   protoc --dart_out=grpc:lib/generated \
     -I../backend/proto \
     ../backend/proto/loft/v1/loft.proto
   ```

3. **Implement API Client**
   - Create `lib/core/api/api_client.dart`
   - Use Dio with Connect-RPC
   - Add auth interceptor

4. **Implement Providers**
   - Auth provider (Firebase + backend sync)
   - Feed provider (fetch posts, pagination)
   - Comment provider
   - Board provider

5. **Connect UI to Data**
   - Replace mock data in screens
   - Add loading states
   - Add error handling
   - Test user flows

### Phase 3: Admin Panel (1-2 hours)

Option A: Flutter Web
- Build admin screens in Flutter
- Deploy to Firebase Hosting

Option B: Separate Admin Tool
- Build simple React/Next.js admin panel
- Or use Retool/Budibase

### Phase 4: Deploy (30 minutes)

1. **Backend to Railway**
   ```bash
   cd backend
   railway init
   railway add postgresql
   railway up
   ```

2. **Flutter to Stores**
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ipa --release
   ```

## 🎯 Testing Checklist

### Backend
- [ ] Database migrations run successfully
- [ ] Server starts without errors
- [ ] Public endpoints work (no auth)
- [ ] Member endpoints require auth
- [ ] Admin endpoints check roles
- [ ] Firebase JWT validation works

### Frontend
- [ ] App launches successfully
- [ ] Feed screen loads posts
- [ ] Guest can browse content
- [ ] Login with Google works
- [ ] Login with Facebook works
- [ ] Member can like posts
- [ ] Member can comment
- [ ] Member can submit questions
- [ ] Shimmer loading states work
- [ ] Infinite scroll works
- [ ] Pull-to-refresh works

### Integration
- [ ] User login syncs with backend
- [ ] Like action updates count immediately
- [ ] Comment appears in list after posting
- [ ] Board question submission works
- [ ] Admin can create posts
- [ ] Admin can delete comments
- [ ] Admin can block users

## 🐛 Common Issues

### Backend

**Issue**: `buf: command not found`
```bash
go install github.com/bufbuild/buf/cmd/buf@latest
export PATH="$PATH:$(go env GOPATH)/bin"
```

**Issue**: `migrate: command not found`
```bash
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

**Issue**: Database connection failed
```bash
# Check PostgreSQL is running
docker ps
# Check connection string
psql "postgresql://postgres:postgres@localhost:5432/loft"
```

### Frontend

**Issue**: `go_router` not found
```bash
flutter pub get
```

**Issue**: Firebase not initialized
- Check `google-services.json` is in `android/app/`
- Check `GoogleService-Info.plist` is in `ios/Runner/`
- Run `flutter clean && flutter pub get`

**Issue**: `.env` file not loaded
- Ensure `.env` is in `frontend/` root
- Check `pubspec.yaml` has `.env` in assets
- Run `flutter clean`

## 📊 Current Status

```
Backend:     [████████░░] 80% (Structure complete, needs implementation)
Frontend:    [██████░░░░] 60% (UI complete, needs data integration)
Database:    [██████████] 100% (Schema complete and documented)
Deployment:  [░░░░░░░░░░]  0% (Ready to deploy)
```

## 🎓 Learning Resources

- [Connect-RPC Docs](https://connectrpc.com/docs/introduction)
- [Riverpod Docs](https://riverpod.dev/)
- [Flutter Material 3](https://m3.material.io/)
- [Firebase Auth Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Railway Docs](https://docs.railway.app/)

## 💡 Pro Tips

1. **Use Hot Reload**: Flutter's hot reload speeds up UI development
2. **Test on Real Devices**: Emulators don't show real performance
3. **Monitor Backend Logs**: Use Railway dashboard for production logs
4. **Use Flutter DevTools**: Essential for debugging state management
5. **Version Control**: Commit frequently with clear messages

## 🎉 You're Ready!

The foundation is solid. Now it's time to:
1. Wire up the backend services with real database queries
2. Connect Flutter to the backend API
3. Test the complete user flow
4. Deploy and celebrate! 🚀

---

Need help? Check the main README.md or the detailed documentation files.
