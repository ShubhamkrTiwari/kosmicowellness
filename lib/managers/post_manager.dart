import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/post.dart';
import 'user_manager.dart';
import 'notification_manager.dart';

class PostManager extends ChangeNotifier {
  static final PostManager _instance = PostManager._internal();
  factory PostManager() => _instance;
  PostManager._internal();

  List<Post> _feed = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get feed => _feed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFeed() async {
    final token = UserManager().token;
    if (token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getFeed(token);
      debugPrint('DEBUG: Post Feed Response: $response');
      if (response['success']) {
        final rawData = response['data'];
        List listData = [];
        if (rawData is List) {
          listData = rawData;
        } else if (rawData is Map && rawData['posts'] is List) {
          listData = rawData['posts'];
        } else if (rawData is Map && rawData['data'] is List) {
          listData = rawData['data'];
        }
        
        final List<Post> newFeed = listData.map((json) => Post.fromJson(json)).toList();
        final myId = UserManager().userId;

        // Auto-detect new likes and comments received on my posts
        if (myId != null && myId.isNotEmpty && _feed.isNotEmpty) {
          for (final np in newFeed) {
            if (np.userId == myId) {
              final oldIdx = _feed.indexWhere((p) => p.id == np.id);
              if (oldIdx != -1) {
                final oldPost = _feed[oldIdx];
                // Check new likes received
                final newLikes = np.likes.where((u) => !oldPost.likes.contains(u) && u != myId).toList();
                if (newLikes.isNotEmpty) {
                  final snippet = np.content.length > 25 ? '${np.content.substring(0, 25)}...' : (np.content.isNotEmpty ? np.content : 'your post');
                  NotificationManager().addNotification(
                    title: 'New Like on Your Post',
                    message: '${newLikes.length} person(s) liked "$snippet"',
                    icon: '❤️',
                    type: 'like',
                  );
                }

                // Check new comments received
                final newComments = np.comments.where((nc) => !oldPost.comments.any((oc) => oc.id == nc.id) && nc.userId != myId).toList();
                for (final nc in newComments) {
                  final snippet = np.content.length > 20 ? '${np.content.substring(0, 20)}...' : (np.content.isNotEmpty ? np.content : 'your post');
                  NotificationManager().addNotification(
                    title: 'New Comment on Your Post',
                    message: '${nc.userName} commented on "$snippet": "${nc.text}"',
                    icon: '💬',
                    type: 'comment',
                  );
                }
              }
            }
          }
        }

        _feed = newFeed;
        
        debugPrint('DEBUG: My UserID: $myId');
        debugPrint('DEBUG: Feed items count: ${_feed.length}');
      } else {
        _error = response['message'];
      }
    } catch (e) {
      debugPrint('DEBUG: fetchFeed Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPost(String content, {XFile? imageFile, String? location, String privacyLevel = 'public'}) async {
    final token = UserManager().token;
    if (token == null) return false;

    try {
      final response = await ApiService.createPost(
        content: content,
        imageFile: imageFile,
        location: location,
        privacyLevel: privacyLevel,
        token: token,
      );
      if (response['success']) {
        NotificationManager().addNotification(
          title: 'Post Published',
          message: 'Your post was successfully shared with the community.',
          icon: '📝',
          type: 'post',
        );
        await fetchFeed();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> likePost(String postId) async {
    final token = UserManager().token;
    if (token == null) return false;

    try {
      final response = await ApiService.likePost(postId, token);
      if (response['success']) {
        final index = _feed.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _feed[index];
          final userId = UserManager().userId;
          if (userId != null) {
            final bool wasLiked = post.likes.contains(userId);
            if (wasLiked) {
              post.likes.remove(userId);
            } else {
              post.likes.add(userId);
              // Notify user about their like
              final snippet = post.content.length > 25 ? '${post.content.substring(0, 25)}...' : (post.content.isNotEmpty ? post.content : 'post');
              NotificationManager().addNotification(
                title: 'Post Liked',
                message: 'You liked ${post.userName}\'s post "$snippet"',
                icon: '❤️',
                type: 'like',
              );
            }
            notifyListeners();
          }
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> addComment(String postId, String text) async {
    final token = UserManager().token;
    if (token == null) return false;

    try {
      final response = await ApiService.addComment(postId, text, token);
      if (response['success']) {
        final index = _feed.indexWhere((p) => p.id == postId);
        final post = index != -1 ? _feed[index] : null;
        final snippet = post != null && post.content.length > 20 
            ? '${post.content.substring(0, 20)}...' 
            : (post != null && post.content.isNotEmpty ? post.content : 'post');
            
        NotificationManager().addNotification(
          title: 'Comment Added',
          message: 'You commented on ${post?.userName ?? 'a'}\'s post "$snippet": "$text"',
          icon: '💬',
          type: 'comment',
        );
        await fetchFeed();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> editPost(String postId, String content) async {
    final token = UserManager().token;
    if (token == null) return false;

    try {
      final response = await ApiService.editPost(postId, {'content': content}, token);
      if (response['success']) {
        NotificationManager().addNotification(
          title: 'Post Updated',
          message: 'Your post was updated successfully.',
          icon: '✏️',
          type: 'post',
        );
        await fetchFeed();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deletePost(String postId) async {
    final token = UserManager().token;
    if (token == null) return false;

    try {
      final response = await ApiService.deletePost(postId, token);
      if (response['success']) {
        _feed.removeWhere((p) => p.id == postId);
        NotificationManager().addNotification(
          title: 'Post Deleted',
          message: 'Your post was deleted.',
          icon: '🗑️',
          type: 'post',
        );
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
