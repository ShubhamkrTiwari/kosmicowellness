import '../services/api_service.dart';

class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImage;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime? createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImage,
    required this.receiverId,
    required this.status,
    this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    String sId = '';
    String sName = 'User';
    String? sImage;

    if (sender is Map<String, dynamic>) {
      sId = (sender['_id'] ?? sender['id'] ?? '').toString();
      sName = (sender['name'] ?? sender['userName'] ?? sender['fullName'] ?? sender['displayName'] ?? 'User').toString();
      sImage = (sender['profilePicture'] ?? sender['avatar'] ?? sender['image'] ?? sender['userImage'])?.toString();
    } else if (sender is String) {
      sId = sender;
    }

    if (sImage != null && sImage.isNotEmpty && !sImage.startsWith('http') && !sImage.startsWith('data:')) {
      sImage = '${ApiService.baseUrl}/$sImage'.replaceAll(RegExp(r'(?<!:)/+'), '/');
    }

    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }

    return FriendRequest(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      senderId: sId,
      senderName: sName,
      senderImage: sImage,
      receiverId: (json['receiver'] is Map ? json['receiver']['_id'] : json['receiver'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: created,
    );
  }
}
