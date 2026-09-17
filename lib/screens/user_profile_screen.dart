import 'package:flutter/material.dart';
import '../managers/user_manager.dart';
import '../managers/notification_manager.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/image_viewer_dialog.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userImage;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userImage,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Post> _userPosts = [];
  bool _isLoading = true;
  bool _isAddingFriend = false;
  String _friendStatus = 'none'; // 'none', 'pending', 'friends'

  @override
  void initState() {
    super.initState();
    _fetchUserPosts();
    _checkFriendStatus();
  }

  Future<void> _checkFriendStatus() async {
    final token = UserManager().token;
    if (token == null) return;

    try {
      final friendsRes = await ApiService.getFriends(token);
      if (friendsRes['success'] == true && friendsRes['data'] != null) {
        final List fList = friendsRes['data'] is List ? friendsRes['data'] : (friendsRes['data']['friends'] ?? []);
        final isFriend = fList.any((f) {
          final id = f is Map ? (f['_id'] ?? f['id']) : f.toString();
          return id == widget.userId;
        });
        if (isFriend && mounted) {
          setState(() => _friendStatus = 'friends');
          return;
        }
      }

      final reqRes = await ApiService.getFriendRequests(token);
      if (reqRes['success'] == true && reqRes['data'] != null) {
        final List rList = reqRes['data'] is List ? reqRes['data'] : [];
        final isPending = rList.any((r) {
          if (r is Map) {
            final receiverId = r['receiver'] is Map ? r['receiver']['_id'] : r['receiver'];
            final senderId = r['sender'] is Map ? r['sender']['_id'] : r['sender'];
            return receiverId == widget.userId || senderId == widget.userId;
          }
          return false;
        });
        if (isPending && mounted) {
          setState(() => _friendStatus = 'pending');
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchUserPosts() async {
    final token = UserManager().token;
    if (token == null) return;

    final response = await ApiService.getUserPosts(widget.userId, token);
    if (response['success']) {
      final List data = response['data'] ?? [];
      setState(() {
        _userPosts = data.map((json) => Post.fromJson(json)).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleAddFriend() async {
    final token = UserManager().token;
    if (token == null) return;

    setState(() => _isAddingFriend = true);
    final response = await ApiService.addFriend(widget.userId, token);
    setState(() => _isAddingFriend = false);

    final bool isSuccess = response['success'] == true;
    String displayMessage = isSuccess ? 'Friend request sent!' : 'Could not send friend request.';
    if (response['data'] != null && response['data'] is Map && response['data']['message'] != null) {
      displayMessage = response['data']['message'];
    } else if (response['message'] != null) {
      displayMessage = response['message'];
    }

    final lowerMsg = displayMessage.toLowerCase();
    if (lowerMsg.contains('already friends') || lowerMsg.contains('already friend')) {
      setState(() => _friendStatus = 'friends');
      displayMessage = 'You are already friends!';
    } else if (isSuccess || lowerMsg.contains('sent') || lowerMsg.contains('pending')) {
      setState(() => _friendStatus = 'pending');
      NotificationManager().addNotification(
        title: 'Friend Request Sent',
        message: 'You sent a friend request to ${widget.userName}.',
        icon: '👥',
        type: 'friend_request',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          backgroundColor: (isSuccess || lowerMsg.contains('already')) ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.userName),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.userImage != null ? NetworkImage(widget.userImage!) : null,
                  child: widget.userImage == null ? Text(widget.userName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)) : null,
                ),
                const SizedBox(height: 16),
                Text(widget.userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (widget.userId != UserManager().userId) ...[
                  if (_friendStatus == 'friends')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text('Friends', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    )
                  else if (_friendStatus == 'pending')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text('Request Sent', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isAddingFriend ? null : _handleAddFriend,
                      icon: _isAddingFriend 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.person_add),
                      label: const Text('Add Friend'),
                    ),
                ],
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                if (_userPosts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('No posts yet', style: TextStyle(color: Colors.grey[400])),
                  )
                else
                  ..._userPosts.map((post) => _buildMiniPostCard(post, colorScheme)),
              ],
            ),
          ),
    );
  }

  Widget _buildMiniPostCard(Post post, ColorScheme colorScheme) {
    final timeStr = DateFormat.yMMMd().format(post.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeStr, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              if (post.privacyLevel == 'friends')
                const Icon(Icons.people, size: 12, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.content, style: const TextStyle(fontSize: 13)),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => ImageViewerDialog.show(
                context,
                imageUrl: post.mediaUrls.first,
                title: widget.userName,
                caption: post.content,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(post.mediaUrls.first, height: 100, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
