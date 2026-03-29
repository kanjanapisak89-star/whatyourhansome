import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../models/post_model.dart';

// Feed state notifier
final feedProvider = StateNotifierProvider<FeedNotifier, AsyncValue<List<PostModel>>>((ref) {
  return FeedNotifier(ref);
});

class FeedNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;

  FeedNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadFeed();
  }

  ApiClient get _apiClient => _ref.read(apiClientProvider);

  Future<void> loadFeed() async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _apiClient.getFeed(page: 1, pageSize: 20);
      final posts = (response['posts'] as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
      
      _currentPage = 1;
      _hasMore = response['has_more'] ?? false;
      state = AsyncValue.data(posts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    final currentPosts = state.value ?? [];
    
    try {
      final response = await _apiClient.getFeed(
        page: _currentPage + 1,
        pageSize: 20,
      );
      
      final newPosts = (response['posts'] as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
      
      _currentPage++;
      _hasMore = response['has_more'] ?? false;
      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (e) {
      // Keep current state on error
    }
  }

  Future<void> refresh() async {
    await loadFeed();
  }

  Future<void> toggleLike(String postId) async {
    final currentPosts = state.value ?? [];
    final postIndex = currentPosts.indexWhere((p) => p.id == postId);
    
    if (postIndex == -1) return;

    try {
      // Optimistic update
      final post = currentPosts[postIndex];
      final newReacted = !post.userHasReacted;
      final newCount = post.stats.reactionCount + (newReacted ? 1 : -1);
      
      final updatedPost = post.copyWith(
        userHasReacted: newReacted,
        stats: post.stats.copyWith(reactionCount: newCount),
      );
      
      final updatedPosts = [...currentPosts];
      updatedPosts[postIndex] = updatedPost;
      state = AsyncValue.data(updatedPosts);

      // API call
      final response = await _apiClient.toggleReaction(postId);
      
      // Update with server response
      final serverReacted = response['is_reacted'] ?? newReacted;
      final serverCount = response['new_count'] ?? newCount;
      
      final finalPost = post.copyWith(
        userHasReacted: serverReacted,
        stats: post.stats.copyWith(reactionCount: serverCount),
      );
      
      updatedPosts[postIndex] = finalPost;
      state = AsyncValue.data(updatedPosts);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentPosts);
    }
  }
}

// Single post provider
final postProvider = FutureProvider.family<PostModel, String>((ref, postId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.getPost(postId);
  return PostModel.fromJson(response['post']);
});
