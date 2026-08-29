import 'package:flutter/foundation.dart';
import '../managers/user_manager.dart';
import '../services/api_service.dart';

class Post {
  final String id;
  final String content;
  final List<String> mediaUrls;
  final String privacyLevel;
  final List<String> tags;
  final String? location;
  final String userId;
  final String userName;
  final String? userImage;
  final List<String> likes;
  final List<Comment> comments;
  final bool isEdited;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.content,
    required this.mediaUrls,
    required this.privacyLevel,
    required this.tags,
    this.location,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.likes,
    required this.comments,
    required this.isEdited,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Handle nested user object if it exists
    final userData = json['user'] ?? 
                     json['author'] ?? 
                     json['postedBy'] ?? 
                     json['creator'] ?? 
                     json['createdBy'] ?? 
                     json['member'] ?? 
                     json['userData'];
    String uName = '';
    String uId = '';
    String? uImg;

    if (userData is Map) {
      uName = userData['name']?.toString() ?? 
              userData['userName']?.toString() ?? 
              userData['fullName']?.toString() ?? 
              userData['username']?.toString() ?? 
              userData['displayName']?.toString() ?? 
              userData['firstName']?.toString() ?? 
              '';
      if (uName.isEmpty && userData['firstName'] != null) {
        uName = '${userData['firstName']} ${userData['lastName'] ?? ''}'.trim();
      }
      uId = userData['_id']?.toString() ?? userData['id']?.toString() ?? userData['uid']?.toString() ?? '';
      uImg = userData['profilePicture']?.toString() ?? 
             userData['avatar']?.toString() ?? 
             userData['userImage']?.toString() ?? 
             userData['image']?.toString();
    } else if (userData != null) {
      uId = userData.toString();
    }

    if (uId.isEmpty) {
      uId = json['userId']?.toString() ?? json['user_id']?.toString() ?? '';
    }

    if (uName.isEmpty || uName.trim().toLowerCase() == 'anonymous' || uName.trim().toLowerCase() == 'user') {
      final topCandidates = [
        json['userName'],
        json['name'],
        json['fullName'],
        json['username'],
        json['displayName'],
        json['authorName'],
        json['user_name'],
        json['full_name'],
        (json['author'] is Map ? (json['author']['name'] ?? json['author']['userName']) : null),
      ];
      for (var cand in topCandidates) {
        if (cand != null && cand.toString().trim().isNotEmpty && cand.toString().trim().toLowerCase() != 'user') {
          uName = cand.toString().trim();
          break;
        }
      }
    }

    uImg ??= json['userImage']?.toString() ?? 
             json['profilePicture']?.toString() ?? 
             json['avatar']?.toString() ?? 
             json['image']?.toString();

    // Check if the post author is the current logged-in user
    final currentUserId = UserManager().userId;
    final currentUserName = UserManager().userName;
    final currentUserEmail = UserManager().userEmail;

    final isCurrentUser = (currentUserId != null && currentUserId.isNotEmpty && uId == currentUserId) ||
                          (currentUserEmail != null && currentUserEmail.isNotEmpty && uId == currentUserEmail);

    if (isCurrentUser || uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous') {
      if (currentUserName != null && currentUserName.trim().isNotEmpty && currentUserName.trim().toLowerCase() != 'user') {
        uName = currentUserName.trim();
      } else if (currentUserEmail != null && currentUserEmail.contains('@')) {
        uName = currentUserEmail.split('@').first;
      }
      uImg ??= UserManager().profilePicture;
    }

    // Fallback using email if available
    if ((uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous')) {
      final emailCandidate = (userData is Map ? userData['email'] : null) ?? json['email'] ?? json['userEmail'];
      if (emailCandidate != null && emailCandidate.toString().contains('@')) {
        final raw = emailCandidate.toString().split('@').first;
        if (raw.isNotEmpty) {
          uName = raw[0].toUpperCase() + (raw.length > 1 ? raw.substring(1) : '');
        }
      }
    }

    if (uName.isEmpty || uName.trim().toLowerCase() == 'user') {
      uName = (currentUserName != null && currentUserName.isNotEmpty && currentUserName != 'User') 
          ? currentUserName 
          : 'Member';
    }

    // Normalize user image URL if relative
    if (uImg != null && uImg.trim().isNotEmpty) {
      String imgStr = uImg.trim();
      if (!imgStr.startsWith('http://') &&
          !imgStr.startsWith('https://') &&
          !imgStr.startsWith('blob:') &&
          !imgStr.startsWith('data:')) {
        String cleanBase = ApiService.baseUrl.endsWith('/')
            ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
            : ApiService.baseUrl;
        String cleanPath = imgStr.startsWith('/') ? imgStr : '/$imgStr';
        uImg = '$cleanBase$cleanPath';
      }
    }

    // Robust extraction for content/text from all possible field names
    String extractedContent = '';
    final contentCandidates = [
      json['content'],
      json['text'],
      json['caption'],
      json['description'],
      json['message'],
      json['body'],
      json['postText'],
      json['postContent'],
      json['status'],
      json['title'],
    ];
    for (final candidate in contentCandidates) {
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        extractedContent = candidate.toString().trim();
        break;
      }
    }

    // Robust extraction and URL normalization for media/images
    List<String> extractedMediaUrls = [];

    void addMediaItem(dynamic item) {
      if (item == null) return;
      if (item is String) {
        String str = item.trim();
        if (str.isNotEmpty) {
          if (!str.startsWith('http://') &&
              !str.startsWith('https://') &&
              !str.startsWith('blob:') &&
              !str.startsWith('data:')) {
            String cleanBase = ApiService.baseUrl.endsWith('/')
                ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
                : ApiService.baseUrl;
            String cleanPath = str.startsWith('/') ? str : '/$str';
            str = '$cleanBase$cleanPath';
          }
          if (!extractedMediaUrls.contains(str)) {
            extractedMediaUrls.add(str);
          }
        }
      } else if (item is Map) {
        final url = item['url'] ??
            item['path'] ??
            item['src'] ??
            item['link'] ??
            item['mediaUrl'] ??
            item['imageUrl'] ??
            item['fileUrl'] ??
            item['secure_url'];
        if (url != null) addMediaItem(url);
      } else if (item is List) {
        for (var sub in item) {
          addMediaItem(sub);
        }
      }
    }

    final mediaCandidates = [
      json['mediaUrls'],
      json['media'],
      json['images'],
      json['image'],
      json['imageUrls'],
      json['imageUrl'],
      json['photos'],
      json['photo'],
      json['attachments'],
      json['attachment'],
      json['files'],
      json['file'],
      json['postImage'],
      json['mediaUrl'],
    ];

    for (var candidate in mediaCandidates) {
      if (candidate != null) {
        addMediaItem(candidate);
      }
    }

    debugPrint('DEBUG: Post.fromJson - content: "$extractedContent", media: $extractedMediaUrls');

    return Post(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      content: extractedContent,
      mediaUrls: extractedMediaUrls,
      privacyLevel: json['privacyLevel']?.toString() ?? 'public',
      tags: List<String>.from(json['tags'] ?? []),
      location: json['location']?.toString(),
      userId: uId,
      userName: uName,
      userImage: uImg,
      likes: List<String>.from(json['likes'] ?? []),
      comments: (json['comments'] as List? ?? [])
          .map((c) => Comment.fromJson(c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c as Map)))
          .toList(),
      isEdited: json['isEdited'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val.toLocal();
    if (val is int) {
      if (val > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
      } else {
        return DateTime.fromMillisecondsSinceEpoch(val * 1000).toLocal();
      }
    }
    String str = val.toString().trim();
    if (str.isEmpty) return DateTime.now();

    try {
      if (str.contains('T') && !str.endsWith('Z') && !str.contains('+') && !str.contains('-')) {
        str = '${str}Z';
      }
      DateTime? dt = DateTime.tryParse(str);
      if (dt != null) {
        return dt.toLocal();
      }
    } catch (_) {}
    return DateTime.now();
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Check all possible user object locations
    final userData = json['user'] ?? 
                     json['author'] ?? 
                     json['postedBy'] ?? 
                     json['creator'] ?? 
                     json['commenter'] ?? 
                     json['createdBy'] ?? 
                     json['member'] ?? 
                     json['userData'];
    String uName = '';
    String uId = '';
    String? uImg;

    if (userData is Map) {
      uName = userData['name']?.toString() ?? 
              userData['userName']?.toString() ?? 
              userData['fullName']?.toString() ?? 
              userData['username']?.toString() ?? 
              userData['displayName']?.toString() ?? 
              userData['firstName']?.toString() ?? 
              '';
      if (uName.isEmpty && userData['firstName'] != null) {
        uName = '${userData['firstName']} ${userData['lastName'] ?? ''}'.trim();
      }
      uId = userData['_id']?.toString() ?? userData['id']?.toString() ?? userData['uid']?.toString() ?? '';
      uImg = userData['profilePicture']?.toString() ?? 
             userData['avatar']?.toString() ?? 
             userData['userImage']?.toString() ?? 
             userData['image']?.toString();
    } else if (userData != null) {
      uId = userData.toString();
    }

    if (uId.isEmpty) {
      uId = json['userId']?.toString() ?? json['user_id']?.toString() ?? json['authorId']?.toString() ?? '';
    }

    // Top-level fallbacks if uName is empty or 'User' or 'Anonymous'
    if (uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous') {
      final topCandidates = [
        json['userName'],
        json['name'],
        json['fullName'],
        json['username'],
        json['displayName'],
        json['authorName'],
        json['commenterName'],
        json['user_name'],
        json['full_name'],
        json['userFullName'],
        (json['author'] is Map ? (json['author']['name'] ?? json['author']['userName']) : null),
      ];
      for (var cand in topCandidates) {
        if (cand != null && cand.toString().trim().isNotEmpty && cand.toString().trim().toLowerCase() != 'user') {
          uName = cand.toString().trim();
          break;
        }
      }
    }

    // Top-level image fallbacks
    uImg ??= json['userImage']?.toString() ?? 
             json['profilePicture']?.toString() ?? 
             json['avatar']?.toString() ?? 
             json['image']?.toString();

    // Check if the comment author is the current logged-in user
    final currentUserId = UserManager().userId;
    final currentUserName = UserManager().userName;
    final currentUserEmail = UserManager().userEmail;

    final isCurrentUser = (currentUserId != null && currentUserId.isNotEmpty && uId == currentUserId) ||
                          (currentUserEmail != null && currentUserEmail.isNotEmpty && uId == currentUserEmail);

    if (isCurrentUser || uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous') {
      if (currentUserName != null && currentUserName.trim().isNotEmpty && currentUserName.trim().toLowerCase() != 'user') {
        uName = currentUserName.trim();
      } else if (currentUserEmail != null && currentUserEmail.contains('@')) {
        uName = currentUserEmail.split('@').first;
      }
      uImg ??= UserManager().profilePicture;
    }

    // Fallback if userData has email
    if ((uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous')) {
      final emailCandidate = (userData is Map ? userData['email'] : null) ?? json['email'] ?? json['userEmail'];
      if (emailCandidate != null && emailCandidate.toString().contains('@')) {
        final raw = emailCandidate.toString().split('@').first;
        if (raw.isNotEmpty) {
          uName = raw[0].toUpperCase() + (raw.length > 1 ? raw.substring(1) : '');
        }
      }
    }

    if (uName.isEmpty || uName.trim().toLowerCase() == 'user') {
      uName = (currentUserName != null && currentUserName.isNotEmpty && currentUserName != 'User') 
          ? currentUserName 
          : 'Member';
    }

    // Normalize user image URL if relative
    if (uImg != null && uImg.trim().isNotEmpty) {
      String imgStr = uImg.trim();
      if (!imgStr.startsWith('http://') &&
          !imgStr.startsWith('https://') &&
          !imgStr.startsWith('blob:') &&
          !imgStr.startsWith('data:')) {
        String cleanBase = ApiService.baseUrl.endsWith('/')
            ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
            : ApiService.baseUrl;
        String cleanPath = imgStr.startsWith('/') ? imgStr : '/$imgStr';
        uImg = '$cleanBase$cleanPath';
      }
    }

    return Comment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: uId,
      userName: uName,
      userImage: uImg,
      text: json['text']?.toString() ?? json['comment']?.toString() ?? json['message']?.toString() ?? json['content']?.toString() ?? '',
      createdAt: Post._parseDateTime(json['createdAt']),
    );
  }
}
