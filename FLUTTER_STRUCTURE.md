# Flutter App Structure

## Directory Layout

```
frontend/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   └── interceptors/
│   │   │       └── auth_interceptor.dart
│   │   ├── constants/
│   │   │   └── api_constants.dart
│   │   └── utils/
│   │       ├── date_formatter.dart
│   │       └── error_handler.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── user_model.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── providers/
│   │   │   │       └── auth_providers.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── login_screen.dart
│   │   │       └── widgets/
│   │   │           ├── google_sign_in_button.dart
│   │   │           └── facebook_sign_in_button.dart
│   │   ├── feed/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── post_model.dart
│   │   │   │   │   └── post_stats_model.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── feed_repository.dart
│   │   │   │   └── providers/
│   │   │   │       └── feed_providers.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── feed_screen.dart
│   │   │       │   └── post_detail_screen.dart
│   │   │       └── widgets/
│   │   │           ├── post_card.dart
│   │   │           ├── post_stats_bar.dart
│   │   │           ├── author_header.dart
│   │   │           └── shimmer_post_card.dart
│   │   ├── comments/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── comment_model.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── comment_repository.dart
│   │   │   │   └── providers/
│   │   │   │       └── comment_providers.dart
│   │   │   └── presentation/
│   │   │       └── widgets/
│   │   │           ├── comment_list.dart
│   │   │           ├── comment_item.dart
│   │   │           └── comment_input.dart
│   │   ├── board/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── board_question_model.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── board_repository.dart
│   │   │   │   └── providers/
│   │   │   │       └── board_providers.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── board_screen.dart
│   │   │       └── widgets/
│   │   │           ├── question_form.dart
│   │   │           └── question_list.dart
│   │   ├── profile/
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           └── profile_screen.dart
│   │   └── home/
│   │       └── presentation/
│   │           └── screens/
│   │               └── home_screen.dart (Bottom Nav Container)
│   └── generated/
│       └── proto/ (Generated from .proto files)
├── assets/
│   ├── images/
│   ├── icons/
│   └── .env
├── pubspec.yaml
└── README.md
```

## Key Features Implementation

### 1. Authentication Flow

**Login Screen** (`features/auth/presentation/screens/login_screen.dart`)
- Google Sign-In button
- Facebook Sign-In button
- Guest mode (browse only)
- Firebase Auth integration
- Auto-sync with backend after successful login

**Auth Provider** (`features/auth/data/providers/auth_providers.dart`)
```dart
@riverpod
class AuthState extends _$AuthState {
  @override
  Future<User?> build() async {
    // Listen to Firebase auth state
    // Sync with backend
    return null;
  }
  
  Future<void> signInWithGoogle() async { }
  Future<void> signInWithFacebook() async { }
  Future<void> signOut() async { }
}
```

### 2. Feed Screen (Main UI)

**Feed Screen** (`features/feed/presentation/screens/feed_screen.dart`)
- Infinite scroll pagination
- Pull-to-refresh
- Shimmer loading states
- Post cards matching image_0.png design

**Post Card** (`features/feed/presentation/widgets/post_card.dart`)
```dart
class PostCard extends StatelessWidget {
  final Post post;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          AuthorHeader(author: post.author),
          PostTitle(title: post.title),
          PostContent(content: post.content),
          if (post.imageUrl != null) PostImage(url: post.imageUrl),
          PostStatsBar(
            likes: post.stats.reactionCount,
            comments: post.stats.commentCount,
            shares: post.stats.viewCount,
            hasReacted: post.userHasReacted,
            onLike: () => _handleLike(),
            onComment: () => _navigateToComments(),
            onShare: () => _handleShare(),
          ),
        ],
      ),
    );
  }
}
```

### 3. Post Detail Screen

**Post Detail** (`features/feed/presentation/screens/post_detail_screen.dart`)
- Full post content
- Comments section
- Like/comment interactions
- Share functionality

### 4. Board Screen

**Board Screen** (`features/board/presentation/screens/board_screen.dart`)
- Question submission form
- User's question history
- Status indicators (pending/answered)

### 5. Home Screen (Bottom Navigation)

**Home Screen** (`features/home/presentation/screens/home_screen.dart`)
```dart
class HomeScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          FeedScreen(),
          BoardScreen(),
          StatsScreen(), // Analytics
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.messageSquare), label: 'Board'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.barChart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }
}
```

## State Management Pattern

### Riverpod Providers

**Feed Provider**
```dart
@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<List<Post>> build() async {
    final repository = ref.read(feedRepositoryProvider);
    return repository.getFeed(page: 1, pageSize: 20);
  }
  
  Future<void> loadMore() async { }
  Future<void> refresh() async { }
  Future<void> toggleLike(String postId) async { }
}
```

**Auth Guard**
```dart
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
}

// Usage in widgets
final isAuth = ref.watch(isAuthenticatedProvider);
if (!isAuth) {
  // Show login modal
  showLoginBottomSheet(context);
}
```

## API Integration

### API Client (`core/api/api_client.dart`)
```dart
class ApiClient {
  final Dio _dio;
  
  ApiClient(this._dio) {
    _dio.options.baseUrl = dotenv.env['API_BASE_URL']!;
    _dio.interceptors.add(AuthInterceptor());
  }
  
  Future<GetFeedResponse> getFeed({int page = 1, int pageSize = 20}) async {
    final response = await _dio.post(
      '/loft.v1.PublicService/GetFeed',
      data: GetFeedRequest(page: page, pageSize: pageSize).writeToBuffer(),
      options: Options(
        headers: {'Content-Type': 'application/proto'},
      ),
    );
    return GetFeedResponse.fromBuffer(response.data);
  }
}
```

### Auth Interceptor
```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

## UI Components Matching image_0.png

### Post Card Design
- Dark background (#1A1A1A)
- Author avatar (circular, 40x40)
- Author name + timestamp
- Post title (bold, 20sp, white)
- Post excerpt (14sp, gray)
- Hero image (full width, rounded corners)
- Stats bar (likes, comments, shares)
- Like button (heart icon, blue when active)

### Color Palette
- Background: #000000
- Card: #1A1A1A
- Primary Blue: #0066FF
- Accent Green: #00D9A3
- Text Primary: #FFFFFF
- Text Secondary: #999999

### Typography
- Title: 20sp, Bold
- Body: 14sp, Regular
- Metadata: 12sp, Regular
- Author: 13sp, Medium

## Guest vs Member Logic

```dart
Future<void> handleLikePress(String postId) async {
  final isAuth = ref.read(isAuthenticatedProvider);
  
  if (!isAuth) {
    // Show login modal
    final result = await showLoginBottomSheet(context);
    if (result == null) return; // User cancelled
  }
  
  // Proceed with like
  await ref.read(feedNotifierProvider.notifier).toggleLike(postId);
}
```

## Next Implementation Steps

1. ✅ Create Flutter project structure
2. ✅ Setup theme and routing
3. ⏳ Generate protobuf Dart code
4. ⏳ Implement API client
5. ⏳ Build auth flow
6. ⏳ Build feed screen
7. ⏳ Build post detail screen
8. ⏳ Build board screen
9. ⏳ Build profile screen
10. ⏳ Add shimmer loading states
11. ⏳ Test end-to-end flow
