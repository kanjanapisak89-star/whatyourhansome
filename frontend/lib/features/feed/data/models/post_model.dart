class PostModel {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final String? imageUrl;
  final bool published;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AuthorModel? author;
  final PostStatsModel stats;
  final bool userHasReacted;

  PostModel({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.published,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    required this.stats,
    required this.userHasReacted,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      authorId: json['author_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      published: json['published'] ?? false,
      viewCount: json['view_count'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['created_at_unix'] ?? 0) * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updated_at_unix'] ?? 0) * 1000,
      ),
      author: json['author'] != null
          ? AuthorModel.fromJson(json['author'])
          : null,
      stats: json['stats'] != null
          ? PostStatsModel.fromJson(json['stats'])
          : PostStatsModel(reactionCount: 0, commentCount: 0, viewCount: 0),
      userHasReacted: json['user_has_reacted'] ?? false,
    );
  }

  PostModel copyWith({
    bool? userHasReacted,
    PostStatsModel? stats,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      title: title,
      content: content,
      imageUrl: imageUrl,
      published: published,
      viewCount: viewCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author,
      stats: stats ?? this.stats,
      userHasReacted: userHasReacted ?? this.userHasReacted,
    );
  }
}

class AuthorModel {
  final String id;
  final String displayName;
  final String? avatarUrl;

  AuthorModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

class PostStatsModel {
  final int reactionCount;
  final int commentCount;
  final int viewCount;

  PostStatsModel({
    required this.reactionCount,
    required this.commentCount,
    required this.viewCount,
  });

  factory PostStatsModel.fromJson(Map<String, dynamic> json) {
    return PostStatsModel(
      reactionCount: json['reaction_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
    );
  }

  PostStatsModel copyWith({
    int? reactionCount,
    int? commentCount,
    int? viewCount,
  }) {
    return PostStatsModel(
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}
