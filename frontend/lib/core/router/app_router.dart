import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/feed/presentation/screens/post_detail_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/post/:id',
      name: 'post-detail',
      builder: (context, state) {
        final postId = state.pathParameters['id']!;
        return PostDetailScreen(postId: postId);
      },
    ),
  ],
);
