import 'package:flutter/foundation.dart';
import '../managers/user_manager.dart';
import '../services/api_service.dart';

class UserCache {
  static final Map<String, Map<String, String?>> _cache = {};
  static final Set<String> _pendingRequests = {};

  static void set(String? userId, String? name, String? image) {
    if (userId == null || userId.trim().isEmpty) return;
    final uid = userId.trim();
    final cleanName = name?.trim() ?? '';
    
    if (cleanName.isNotEmpty &&
        cleanName.toLowerCase() != 'user' &&
        cleanName.toLowerCase() != 'member' &&
        cleanName.toLowerCase() != 'anonymous' &&
        !Post.isIdString(cleanName)) {
      _cache[uid] = {
        'name': cleanName,
        'image': (image != null && image.trim().isNotEmpty) ? image.trim() : _cache[uid]?['image'],
      };
    } else if (image != null && image.trim().isNotEmpty) {
      final existingName = _cache[uid]?['name'];
      if (existingName != null && existingName.isNotEmpty) {
        _cache[uid] = {
          'name': existingName,
          'image': image.trim(),
        };
      }
    }
  }

  static String? getName(String? userId) {
    if (userId == null || userId.trim().isEmpty) return null;
    return _cache[userId.trim()]?['name'];
  }

  static String? getImage(String? userId) {
    if (userId == null || userId.trim().isEmpty) return null;
    return _cache[userId.trim()]?['image'];
  }

  static Future<void> fetchMissingUser(String userId, String? token, VoidCallback onResolved) async {
    final uid = userId.trim();
    if (uid.isEmpty || token == null || token.isEmpty || _cache.containsKey(uid) || _pendingRequests.contains(uid)) return;
    
    _pendingRequests.add(uid);
    try {
      final res = await ApiService.getUserPosts(uid, token);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        String? foundName;
        String? foundImage;

        if (data is Map) {
          final userObj = data['user'] ?? data['author'] ?? data['userData'];
          if (userObj is Map) {
            foundName = userObj['name']?.toString() ?? userObj['userName']?.toString() ?? userObj['fullName']?.toString();
            foundImage = userObj['profilePicture']?.toString() ?? userObj['avatar']?.toString();
          }
          if ((foundName == null || foundName.isEmpty || Post.isIdString(foundName)) && data['posts'] is List && (data['posts'] as List).isNotEmpty) {
            final p = (data['posts'] as List).first;
            if (p is Map) {
              final postObj = Post.fromJson(Map<String, dynamic>.from(p));
              if (postObj.userName.isNotEmpty && !Post.isIdString(postObj.userName)) {
                foundName = postObj.userName;
                foundImage = postObj.userImage;
              }
            }
          }
        } else if (data is List && data.isNotEmpty) {
          final p = data.first;
          if (p is Map) {
            final postObj = Post.fromJson(Map<String, dynamic>.from(p));
            if (postObj.userName.isNotEmpty && !Post.isIdString(postObj.userName)) {
              foundName = postObj.userName;
              foundImage = postObj.userImage;
            }
          }
        }

        if (foundName != null && foundName.isNotEmpty && !Post.isIdString(foundName)) {
          set(uid, foundName, foundImage);
          onResolved();
        }
      }
    } catch (_) {
    } finally {
      _pendingRequests.remove(uid);
    }
  }
}

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

  static bool isIdString(String s) {
    final clean = s.trim();
    if (clean.isEmpty) return true;
    if (RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(clean)) return true;
    if (RegExp(r'^[0-9a-fA-F-]{32,36}$').hasMatch(clean)) return true;
    if (clean.length >= 16 && !clean.contains(' ') && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(clean)) return true;
    return false;
  }

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
    } else if (userData is String && userData.trim().isNotEmpty) {
      final str = userData.trim();
      if (str.contains(' ') || str.contains('@')) {
        if (str.contains('@')) {
          uName = str.split('@').first;
        } else {
          uName = str;
        }
      } else {
        uId = str;
      }
    }

    if (uId.isEmpty) {
      uId = json['userId']?.toString() ?? json['user_id']?.toString() ?? json['authorId']?.toString() ?? '';
    }

    if (uName.isEmpty || uName.trim().toLowerCase() == 'anonymous' || uName.trim().toLowerCase() == 'user' || isIdString(uName)) {
      final topCandidates = [
        json['userName'],
        json['name'],
        json['fullName'],
        json['username'],
        json['displayName'],
        json['authorName'],
        json['user_name'],
        json['full_name'],
        json['userFullName'],
        (json['author'] is Map ? (json['author']['name'] ?? json['author']['userName']) : (json['author'] is String && !isIdString(json['author']) ? json['author'] : null)),
        (json['user'] is Map ? (json['user']['name'] ?? json['user']['userName']) : (json['user'] is String && !isIdString(json['user']) ? json['user'] : null)),
      ];
      for (var cand in topCandidates) {
        if (cand != null) {
          final str = cand.toString().trim();
          if (str.isNotEmpty && str.toLowerCase() != 'user' && !isIdString(str)) {
            uName = str;
            break;
          }
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

    final isCurrentUser = (currentUserId != null && currentUserId.isNotEmpty && uId.isNotEmpty && uId == currentUserId) ||
                          (currentUserEmail != null && currentUserEmail.isNotEmpty && uId.isNotEmpty && uId == currentUserEmail);

    if (isCurrentUser) {
      if (uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous' || isIdString(uName)) {
        if (currentUserName != null && currentUserName.trim().isNotEmpty && currentUserName.trim().toLowerCase() != 'user' && !isIdString(currentUserName)) {
          uName = currentUserName.trim();
        } else if (currentUserEmail != null && currentUserEmail.contains('@')) {
          uName = currentUserEmail.split('@').first;
        }
      }
      uImg ??= UserManager().profilePicture;
    } else {
      if (uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous' || isIdString(uName)) {
        final emailCandidate = (userData is Map ? userData['email'] : null) ?? json['email'] ?? json['userEmail'];
        if (emailCandidate != null && emailCandidate.toString().contains('@')) {
          final raw = emailCandidate.toString().split('@').first;
          if (raw.isNotEmpty) {
            uName = raw[0].toUpperCase() + (raw.length > 1 ? raw.substring(1) : '');
          }
        }
        if (uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous' || isIdString(uName)) {
          uName = 'Member';
        }
      }
    }

    if (uId.isNotEmpty && uName.isNotEmpty && uName != 'Member' && !isIdString(uName)) {
      UserCache.set(uId, uName, uImg);
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
    } else if (userData is String && userData.trim().isNotEmpty) {
      final str = userData.trim();
      if (str.contains(' ') || str.contains('@')) {
        if (str.contains('@')) {
          uName = str.split('@').first;
        } else {
          uName = str;
        }
      } else {
        uId = str;
      }
    }

    if (uId.isEmpty) {
      uId = json['userId']?.toString() ?? json['user_id']?.toString() ?? json['authorId']?.toString() ?? json['commenterId']?.toString() ?? '';
    }

    // Top-level fallbacks if uName is empty or 'User' or 'Anonymous' or an ID string
    if (uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous' || Post.isIdString(uName)) {
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
        (json['author'] is Map ? (json['author']['name'] ?? json['author']['userName']) : (json['author'] is String && !Post.isIdString(json['author']) ? json['author'] : null)),
        (json['commenter'] is Map ? (json['commenter']['name'] ?? json['commenter']['userName']) : (json['commenter'] is String && !Post.isIdString(json['commenter']) ? json['commenter'] : null)),
        (json['user'] is Map ? (json['user']['name'] ?? json['user']['userName']) : (json['user'] is String && !Post.isIdString(json['user']) ? json['user'] : null)),
      ];
      for (var cand in topCandidates) {
        if (cand != null) {
          final str = cand.toString().trim();
          if (str.isNotEmpty && str.toLowerCase() != 'user' && !Post.isIdString(str)) {
            uName = str;
            break;
          }
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

    final isCurrentUser = (currentUserId != null && currentUserId.isNotEmpty && uId.isNotEmpty && uId == currentUserId) ||
                          (currentUserEmail != null && currentUserEmail.isNotEmpty && uId.isNotEmpty && uId == currentUserEmail);

    if (isCurrentUser) {
      if (uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous' || Post.isIdString(uName)) {
        if (currentUserName != null && currentUserName.trim().isNotEmpty && currentUserName.trim().toLowerCase() != 'user' && !Post.isIdString(currentUserName)) {
          uName = currentUserName.trim();
        } else if (currentUserEmail != null && currentUserEmail.contains('@')) {
          uName = currentUserEmail.split('@').first;
        } else {
          uName = 'Member';
        }
      }
      uImg ??= UserManager().profilePicture;
    } else {
      // Check UserCache
      if (uId.isNotEmpty) {
        final cachedName = UserCache.getName(uId);
        final cachedImg = UserCache.getImage(uId);
        if (cachedName != null && cachedName.isNotEmpty && !Post.isIdString(cachedName)) {
          uName = cachedName;
          uImg ??= cachedImg;
        }
      }

      if (uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous' || Post.isIdString(uName)) {
        final emailCandidate = (userData is Map ? userData['email'] : null) ?? json['email'] ?? json['userEmail'];
        if (emailCandidate != null && emailCandidate.toString().contains('@')) {
          final raw = emailCandidate.toString().split('@').first;
          if (raw.isNotEmpty) {
            uName = raw[0].toUpperCase() + (raw.length > 1 ? raw.substring(1) : '');
          }
        }
        if (uName.isEmpty || uName.trim().toLowerCase() == 'user' || uName.trim().toLowerCase() == 'anonymous' || Post.isIdString(uName)) {
          uName = 'Member';
        }
      }
    }

    if (uId.isNotEmpty && uName.isNotEmpty && uName != 'Member' && !Post.isIdString(uName)) {
      UserCache.set(uId, uName, uImg);
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
