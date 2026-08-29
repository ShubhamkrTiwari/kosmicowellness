import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../managers/post_manager.dart';
import '../../managers/user_manager.dart';
import '../../models/post.dart';
import '../../widgets/image_viewer_dialog.dart';
import '../../services/location_service.dart';
import '../user_profile_screen.dart';
import 'package:intl/intl.dart';

class CommunityModule extends StatefulWidget {
  const CommunityModule({super.key});

  @override
  State<CommunityModule> createState() => _CommunityModuleState();
}

class _CommunityModuleState extends State<CommunityModule> {
  final TextEditingController _postController = TextEditingController();
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;
  XFile? _pickedImage;
  String? _postLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PostManager().fetchFeed();
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _fetchAndSetLocation() async {
    if (_postLocation != null) {
      setState(() => _postLocation = null);
      return;
    }

    setState(() => _isFetchingLocation = true);
    try {
      final pos = await LocationService.getCurrentExactPosition();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access GPS location. Please check permissions.')),
          );
        }
        return;
      }
      final locName = await LocationService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _postLocation = locName;
        });
      }
    } catch (e) {
      debugPrint('Error getting post location: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _handleCreatePost() async {
    if (_postController.text.trim().isEmpty && _pickedImage == null) return;

    setState(() => _isSubmitting = true);
    final success = await PostManager().createPost(
      _postController.text.trim(),
      imageFile: _pickedImage,
      location: _postLocation,
    );
    setState(() => _isSubmitting = false);

    if (success) {
      _postController.clear();
      setState(() {
        _pickedImage = null;
        _postLocation = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: PostManager(),
      builder: (context, _) {
        final manager = PostManager();
        
        return RefreshIndicator(
          onRefresh: () => manager.fetchFeed(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: _buildPostInput(colorScheme),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      if (manager.isLoading)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (manager.feed.isEmpty && !manager.isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 64, color: Colors.grey[200]),
                        const SizedBox(height: 16),
                        Text('No posts yet. Be the first to share!', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildPostCard(manager.feed[index], colorScheme);
                      },
                      childCount: manager.feed.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostInput(ColorScheme colorScheme) {
    final user = UserManager();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20, 
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
                child: user.profilePicture == null ? Icon(Icons.person, size: 20, color: colorScheme.primary) : null
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _postController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Share a recipe or milestone...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          if (_pickedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_pickedImage!.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _pickedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image_outlined, size: 18, color: colorScheme.primary),
                label: Text('Photo', style: TextStyle(color: colorScheme.primary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isFetchingLocation ? null : _fetchAndSetLocation,
                icon: _isFetchingLocation
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
                    : Icon(_postLocation != null ? Icons.location_on : Icons.location_on_outlined, size: 18, color: _postLocation != null ? Colors.red : colorScheme.primary),
                label: Text(
                  _postLocation != null ? _formatDisplayLocation(_postLocation!) : 'Location',
                  style: TextStyle(color: _postLocation != null ? Colors.red : colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: TextButton.styleFrom(
                  backgroundColor: (_postLocation != null ? Colors.red : colorScheme.primary).withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDisplayLocation(String rawLocation) {
    if (rawLocation.trim().isEmpty) return '';
    // Strip PIN code e.g. 201318
    String clean = rawLocation.replaceAll(RegExp(r'\b\d{5,6}\b'), '').trim();
    List<String> parts = clean.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && s != 'null').toList();
    if (parts.isEmpty) return rawLocation;
    if (parts.length == 1) return parts.first;

    // Filter out broad country/state labels if more specific local parts exist
    parts.removeWhere((p) {
      final l = p.toLowerCase();
      return (l == 'india' || l == 'uttar pradesh' || l == 'up' || l == 'maharashtra' || l == 'karnataka' || l == 'delhi') && parts.length > 2;
    });

    if (parts.length >= 3) {
      return '${parts.first}, ${parts.last}';
    } else if (parts.length == 2) {
      return '${parts[0]}, ${parts[1]}';
    }
    return parts.first;
  }

  String _formatPostTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.isNegative || diff.inSeconds < 45) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && local.day == now.day) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1 || (diff.inHours < 48 && local.day == now.subtract(const Duration(days: 1)).day)) {
      return 'Yesterday, ${DateFormat.jm().format(local)}';
    } else if (local.year == now.year) {
      return DateFormat('MMM d, h:mm a').format(local);
    } else {
      return DateFormat('MMM d, y, h:mm a').format(local);
    }
  }

  Widget _buildPostCard(Post post, ColorScheme colorScheme) {
    final timeStr = _formatPostTime(post.createdAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: post.userId,
                        userName: post.userName,
                        userImage: post.userImage,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18, 
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                  backgroundImage: post.userImage != null && post.userImage!.isNotEmpty ? NetworkImage(post.userImage!) : null,
                  child: (post.userImage == null || post.userImage!.isEmpty) 
                      ? Text(post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U', style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          userId: post.userId,
                          userName: post.userName,
                          userImage: post.userImage,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(timeStr, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500)),
                          if (post.location != null && post.location!.trim().isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text('•', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                            ),
                            const Icon(Icons.location_on, size: 11, color: Colors.redAccent),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                _formatDisplayLocation(post.location!),
                                style: TextStyle(color: Colors.grey[600], fontSize: 10.5, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (post.userId == UserManager().userId)
                PopupMenuButton(
                  icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 12), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditDialog(post);
                    } else if (val == 'delete') {
                      _showDeleteDialog(post.id);
                    }
                  },
                ),
            ],
          ),
          if (post.content.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              post.content, 
              style: TextStyle(
                fontSize: 14, 
                height: 1.6, 
                color: colorScheme.onSurface.withValues(alpha: 0.9),
                fontWeight: FontWeight.w400,
              )
            ),
          ],
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => ImageViewerDialog.show(
                context,
                imageUrl: post.mediaUrls.first,
                title: post.userName,
                caption: post.content,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  post.mediaUrls.first, 
                  width: double.infinity, 
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (c, e, s) => Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: const Center(child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _buildActionButton(
                icon: post.likes.contains(UserManager().userId) ? Icons.favorite : Icons.favorite_border,
                label: post.likes.length.toString(),
                color: post.likes.contains(UserManager().userId) ? Colors.red : colorScheme.primary,
                onTap: () => PostManager().likePost(post.id),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.comments.length}',
                color: Colors.grey[600]!,
                onTap: () => _showCommentSheet(post),
                colorScheme: colorScheme,
              ),
              const Spacer(),
              _buildActionButton(
                icon: Icons.ios_share_rounded,
                label: '',
                color: Colors.grey[600]!,
                onTap: () {},
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await PostManager().deletePost(postId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
              }
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Post post) {
    final TextEditingController editController = TextEditingController(text: post.content);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Edit Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: editController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'What do you want to say?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isEmpty) return;
              Navigator.pop(context);
              final success = await PostManager().editPost(post.id, newContent);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post updated successfully!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showCommentSheet(Post post) {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Expanded(
                  child: post.comments.isEmpty
                    ? Center(child: Text('No comments yet', style: TextStyle(color: Colors.grey[400])))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: post.comments.length,
                        itemBuilder: (context, index) {
                          final comment = post.comments[index];
                          String authorName = comment.userName.trim();
                          if (authorName.isEmpty || authorName.toLowerCase() == 'user' || authorName.toLowerCase() == 'anonymous') {
                            final myId = UserManager().userId;
                            final myName = UserManager().userName;
                            final myEmail = UserManager().userEmail;
                            if (comment.userId == myId || comment.userId.isEmpty) {
                              if (myName != null && myName.trim().isNotEmpty && myName.trim().toLowerCase() != 'user') {
                                authorName = myName.trim();
                              } else if (myEmail != null && myEmail.contains('@')) {
                                authorName = myEmail.split('@').first;
                              } else {
                                authorName = 'Member';
                              }
                            } else {
                              authorName = 'Member';
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                                  backgroundImage: comment.userImage != null && comment.userImage!.isNotEmpty ? NetworkImage(comment.userImage!) : null,
                                  child: (comment.userImage == null || comment.userImage!.isEmpty) 
                                      ? Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : 'M', style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.bold)) 
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text(_formatPostTime(comment.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment.text, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 10 + MediaQuery.of(context).viewInsets.bottom),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;
                          final text = commentController.text.trim();
                          commentController.clear();
                          final success = await PostManager().addComment(post.id, text);
                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment added')));
                          }
                        },
                        icon: Icon(Icons.send, color: colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}
