import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiClient {
  late final Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ApiClient() {
    // Resolve API base URL: .env (dev) → --dart-define (prod) → localhost fallback.
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    final baseUrl = dotenv.env['API_BASE_URL'] ??
        (dartDefineUrl.isNotEmpty ? dartDefineUrl : 'http://localhost:8080');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = _auth.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle errors globally
          return handler.next(error);
        },
      ),
    );
  }

  // Public endpoints
  Future<Map<String, dynamic>> getFeed({int page = 1, int pageSize = 20}) async {
    final response = await _dio.post(
      '/loft.v1.PublicService/GetFeed',
      data: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getPost(String postId) async {
    final response = await _dio.post(
      '/loft.v1.PublicService/GetPost',
      data: {'post_id': postId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getComments({
    required String postId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.post(
      '/loft.v1.PublicService/GetComments',
      data: {
        'post_id': postId,
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data;
  }

  // Member endpoints (auth required)
  Future<Map<String, dynamic>> toggleReaction(String postId) async {
    final response = await _dio.post(
      '/loft.v1.MemberService/ToggleReaction',
      data: {'post_id': postId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
  }) async {
    final response = await _dio.post(
      '/loft.v1.MemberService/CreateComment',
      data: {
        'post_id': postId,
        'content': content,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createBoardQuestion({
    required String title,
    required String content,
  }) async {
    final response = await _dio.post(
      '/loft.v1.MemberService/CreateBoardQuestion',
      data: {
        'title': title,
        'content': content,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getMyQuestions({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.post(
      '/loft.v1.MemberService/GetMyQuestions',
      data: {
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.post(
      '/loft.v1.MemberService/GetCurrentUser',
      data: {},
    );
    return response.data;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> syncUser({
    required String firebaseUid,
    required String email,
    required String displayName,
    String? avatarUrl,
    required String provider,
  }) async {
    final response = await _dio.post(
      '/loft.v1.AuthService/SyncUser',
      data: {
        'firebase_uid': firebaseUid,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl ?? '',
        'provider': provider,
      },
    );
    return response.data;
  }
}
