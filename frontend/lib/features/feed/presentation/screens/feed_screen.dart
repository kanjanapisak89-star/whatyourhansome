import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/feed_providers.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../widgets/post_card.dart';
import '../widgets/shimmer_post_card.dart';
import '../../../auth/presentation/widgets/login_bottom_sheet.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  Future<void> _handleLike(String postId) async {
    final isAuth = ref.read(isAuthenticatedProvider);
    
    if (!isAuth) {
      final result = await showLoginBottomSheet(context);
      if (result == null) return;
    }
    
    await ref.read(feedProvider.notifier).toggleLike(postId);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Architects of the\nNext Era.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24.sp,
                height: 1.2,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {
              // Search functionality - coming soon
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () {
                // Navigate to profile
              },
              child: CircleAvatar(
                radius: 18.r,
                backgroundImage: currentUser.value?.avatarUrl != null
                    ? NetworkImage(currentUser.value!.avatarUrl!)
                    : null,
                child: currentUser.value?.avatarUrl == null
                    ? const Icon(LucideIcons.user)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).refresh(),
        child: feedState.when(
          data: (posts) {
            if (posts.isEmpty) {
              return _buildEmptyState();
            }
            
            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  postId: post.id,
                  authorName: post.author?.displayName ?? 'Unknown',
                  authorAvatar: post.author?.avatarUrl ?? 
                      'https://via.placeholder.com/150',
                  title: post.title,
                  content: post.content,
                  imageUrl: post.imageUrl,
                  likeCount: post.stats.reactionCount,
                  commentCount: post.stats.commentCount,
                  viewCount: post.stats.viewCount,
                  hasReacted: post.userHasReacted,
                  createdAt: post.createdAt,
                  onLike: () => _handleLike(post.id),
                  onComment: () {
                    context.push('/post/${post.id}');
                  },
                  onShare: () {
                    // Share functionality - coming soon
                  },
                  onTap: () {
                    context.push('/post/${post.id}');
                  },
                );
              },
            );
          },
          loading: () => ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: 3,
            itemBuilder: (context, index) => const ShimmerPostCard(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  size: 64.sp,
                  color: Colors.red,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Failed to load feed',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 8.h),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => ref.read(feedProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.inbox,
            size: 64.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'No posts yet',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

Future<bool?> showLoginBottomSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (context) => const LoginBottomSheet(),
  );
}
