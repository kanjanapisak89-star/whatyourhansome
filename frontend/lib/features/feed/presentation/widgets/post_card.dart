import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final String postId;
  final String authorName;
  final String authorAvatar;
  final String title;
  final String content;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool hasReacted;
  final DateTime createdAt;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.postId,
    required this.authorName,
    required this.authorAvatar,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.hasReacted,
    required this.createdAt,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.only(bottom: 16.h),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author header
              _buildAuthorHeader(context),
              SizedBox(height: 12.h),
              
              // Post title
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 8.h),
              
              // Post content
              Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Post image
              if (imageUrl != null) ...[
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: double.infinity,
                    height: 200.h,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 12.h),
              
              // Stats bar
              _buildStatsBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundImage: CachedNetworkImageProvider(authorAvatar),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                timeago.format(createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.moreVertical),
          onPressed: () {
            // Post options menu - coming soon
          },
        ),
      ],
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    return Row(
      children: [
        _buildStatButton(
          icon: hasReacted ? LucideIcons.heart : LucideIcons.heart,
          count: likeCount,
          isActive: hasReacted,
          onTap: onLike,
        ),
        SizedBox(width: 16.w),
        _buildStatButton(
          icon: LucideIcons.messageCircle,
          count: commentCount,
          onTap: onComment,
        ),
        SizedBox(width: 16.w),
        _buildStatButton(
          icon: LucideIcons.share2,
          count: viewCount,
          onTap: onShare,
        ),
      ],
    );
  }

  Widget _buildStatButton({
    required IconData icon,
    required int count,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isActive ? const Color(0xFF0066FF) : Colors.grey,
            ),
            SizedBox(width: 6.w),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 13.sp,
                color: isActive ? const Color(0xFF0066FF) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
