# Loft - Content-to-Customer Platform

A full-stack mobile application for content creators to share high-value content with their audience. Built with Flutter (frontend) and Golang (backend).

## 🎯 Project Overview

This is a Content-to-Customer app where owners/admins post content, and users (guests/members) can interact through reactions, comments, and board questions.

### Key Features

- **Guest Access**: Browse all content without authentication
- **Member Features**: Like posts, comment, submit board questions (requires Google/Facebook login)
- **Admin/Owner**: Create/edit posts, moderate comments, manage users, respond to questions
- **Real-time Stats**: View counts, like counts, comment counts
- **Responsive Design**: Matches Figma design pixel-perfect

## 📁 Project Structure

```
loft/
├── backend/                    # Golang backend
│   ├── cmd/server/            # Main server entry point
│   ├── internal/
│   │   ├── auth/              # Firebase auth & middleware
│   │   ├── db/                # Database connection & queries
│   │   └── service/           # Business logic (Public, Member, Admin services)
│   ├── migrations/            # SQL migrations
│   ├── proto/                 # Protobuf definitions
│   ├── gen/                   # Generated protobuf code
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── go.mod
├── frontend/                   # Flutter app
│   ├── lib/
│   │   ├── core/              # Theme, routing, API client
│   │   ├── features/          # Feature modules (auth, feed, board, profile)
│   │   └── main.dart
│   ├── assets/
│   ├── pubspec.yaml
│   └── .env
├── DATABASE_SCHEMA.md         # Database documentation
├── IMPLEMENTATION_PLAN.md     # Development roadmap
├── FLUTTER_STRUCTURE.md       # Flutter architecture guide
└── README.md                  # This file
```

## 🗄️ Database Schema

### Tables
- **users**: User accounts (Firebase Auth integration)
- **posts**: Content created by admins/owners
- **reactions**: Likes/hearts on posts
- **comments**: User feedback on posts
- **board_questions**: User-submitted questions
- **audit_logs**: Admin action tracking
- **post_stats**: Materialized view for performance

See [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) for detailed schema documentation.

## 🚀 Getting Started

### Prerequisites

- **Backend**:
  - Go 1.21+
  - PostgreSQL 15+
  - Docker (optional)
  - protoc (Protocol Buffer compiler)
  - buf (optional, for protobuf generation)

- **Frontend**:
  - Flutter 3.16+
  - Dart 3.0+
  - Android Studio / Xcode (for mobile development)

- **Services**:
  - Firebase project (for authentication)
  - Railway account (for deployment)

### Backend Setup

1. **Clone and navigate to backend**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   go mod download
   ```

3. **Setup PostgreSQL**
   ```bash
   # Using Docker
   docker-compose up -d postgres
   
   # Or install locally and create database
   createdb loft
   ```

4. **Run migrations**
   ```bash
   # Install migrate CLI
   go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
   
   # Run migrations
   migrate -path migrations -database "postgresql://postgres:postgres@localhost:5432/loft?sslmode=disable" up
   ```

5. **Generate protobuf code**
   ```bash
   # Install buf
   go install github.com/bufbuild/buf/cmd/buf@latest
   
   # Generate
   buf generate
   ```

6. **Setup Firebase Admin SDK**
   - Download service account key from Firebase Console
   - Save as `firebase-admin-sdk.json`
   - Set environment variable:
     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-admin-sdk.json
     ```

7. **Run the server**
   ```bash
   go run cmd/server/main.go
   ```

   Server will start on `http://localhost:8080`

### Frontend Setup

1. **Navigate to frontend**
   ```bash
   cd frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Firebase and API credentials
   ```

4. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   # iOS
   flutter run -d ios
   
   # Android
   flutter run -d android
   
   # Web (for admin panel)
   flutter run -d chrome
   ```

## 🔧 Configuration

### Backend Environment Variables

```bash
DATABASE_URL=postgresql://user:pass@localhost:5432/loft?sslmode=disable
PORT=8080
GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-admin-sdk.json
```

### Frontend Environment Variables (.env)

```bash
API_BASE_URL=http://localhost:8080
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_APP_ID=your_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
GOOGLE_CLIENT_ID=your_google_client_id
FACEBOOK_APP_ID=your_facebook_app_id
```

## 📡 API Endpoints

### Public Service (No Auth Required)
- `POST /loft.v1.PublicService/GetFeed` - List published posts
- `POST /loft.v1.PublicService/GetPost` - Get single post
- `POST /loft.v1.PublicService/GetComments` - Get post comments

### Member Service (Auth Required)
- `POST /loft.v1.MemberService/ToggleReaction` - Like/unlike post
- `POST /loft.v1.MemberService/CreateComment` - Add comment
- `POST /loft.v1.MemberService/CreateBoardQuestion` - Submit question
- `POST /loft.v1.MemberService/GetMyQuestions` - Get user's questions
- `POST /loft.v1.MemberService/GetCurrentUser` - Get profile

### Admin Service (Admin Role Required)
- `POST /loft.v1.AdminService/CreatePost` - Create new post
- `POST /loft.v1.AdminService/UpdatePost` - Edit post
- `POST /loft.v1.AdminService/DeletePost` - Delete post
- `POST /loft.v1.AdminService/DeleteComment` - Moderate comment
- `POST /loft.v1.AdminService/BlockUser` - Block user
- `POST /loft.v1.AdminService/UnblockUser` - Unblock user
- `POST /loft.v1.AdminService/GetBoardQuestions` - Get all questions
- `POST /loft.v1.AdminService/RespondToQuestion` - Answer question

### Auth Service
- `POST /loft.v1.AuthService/SyncUser` - Sync Firebase user with backend

## 🎨 UI Design

The app follows the dark theme design from the provided Figma mockup:

- **Background**: #000000
- **Card Background**: #1A1A1A
- **Primary Blue**: #0066FF
- **Accent Green**: #00D9A3
- **Text Primary**: #FFFFFF
- **Text Secondary**: #999999

### Screens
1. **Feed Screen**: Main content feed with infinite scroll
2. **Post Detail**: Full post with comments
3. **Board Screen**: Submit and view questions
4. **Profile Screen**: User profile and settings
5. **Login Screen**: Google/Facebook authentication

## 🚢 Deployment

### Backend to Railway

1. **Create Railway project**
   ```bash
   railway init
   ```

2. **Add PostgreSQL**
   ```bash
   railway add postgresql
   ```

3. **Set environment variables**
   ```bash
   railway variables set GOOGLE_APPLICATION_CREDENTIALS="$(cat firebase-admin-sdk.json)"
   ```

4. **Deploy**
   ```bash
   railway up
   ```

### Flutter App

1. **Build APK (Android)**
   ```bash
   flutter build apk --release
   ```

2. **Build IPA (iOS)**
   ```bash
   flutter build ipa --release
   ```

3. **Submit to stores**
   - Follow Google Play Store submission guide
   - Follow Apple App Store submission guide

## 🧪 Testing

### Backend Tests
```bash
cd backend
go test ./...
```

### Flutter Tests
```bash
cd frontend
flutter test
```

### Integration Tests
```bash
cd frontend
flutter test integration_test/
```

## 📝 Development Workflow

1. **Database Changes**
   - Create new migration: `migrate create -ext sql -dir migrations -seq migration_name`
   - Update schema
   - Run migration: `migrate up`

2. **API Changes**
   - Update `proto/loft/v1/loft.proto`
   - Regenerate: `buf generate`
   - Update service implementations

3. **Frontend Changes**
   - Update models/providers
   - Run code generation: `flutter pub run build_runner build`
   - Update UI components

## 🔐 Security

- Firebase JWT validation on all protected endpoints
- Role-based access control (RBAC)
- SQL injection prevention (parameterized queries)
- CORS configuration
- Input validation
- Audit logging for admin actions

## 📚 Documentation

- [Database Schema](./DATABASE_SCHEMA.md) - Complete database documentation
- [Implementation Plan](./IMPLEMENTATION_PLAN.md) - Development roadmap
- [Flutter Structure](./FLUTTER_STRUCTURE.md) - Frontend architecture guide

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is proprietary and confidential.

## 🆘 Support

For issues and questions:
- Backend: Check logs in Railway dashboard
- Frontend: Use Flutter DevTools
- Database: Check PostgreSQL logs

## 🎯 Next Steps

1. ✅ Database schema created
2. ✅ Backend API structure defined
3. ✅ Flutter app structure created
4. ⏳ Complete backend service implementations
5. ⏳ Implement Firebase Auth in Flutter
6. ⏳ Connect Flutter to backend API
7. ⏳ Build admin/backoffice panel
8. ⏳ Deploy to Railway
9. ⏳ Submit to app stores

---

Built with ❤️ using Flutter & Golang
