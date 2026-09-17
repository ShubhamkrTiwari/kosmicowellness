import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../managers/post_manager.dart';
import '../../managers/user_manager.dart';
import '../../models/post.dart';
import '../../widgets/image_viewer_dialog.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../user_profile_screen.dart';
import 'package:intl/intl.dart';

class CommunityModule extends StatefulWidget {
  const CommunityModule({super.key});

  @override
  State<CommunityModule> createState() => _CommunityModuleState();
}

class _CommunityModuleState extends State<CommunityModule> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PostManager().fetchFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListenableBuilder(
      listenable: PostManager(),
      builder: (context, _) {
        final manager = PostManager();
        
        return RefreshIndicator(
          onRefresh: () => manager.fetchFeed(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: PostInputWidget(),
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
                        return PostCardWidget(post: manager.feed[index]);
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
}

class PostInputWidget extends StatefulWidget {
  const PostInputWidget({super.key});

  @override
  State<PostInputWidget> createState() => _PostInputWidgetState();
}

class _PostInputWidgetState extends State<PostInputWidget> {
  final TextEditingController _postController = TextEditingController();
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;
  XFile? _pickedImage;
  String? _postLocation;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
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
        setState(() => _postLocation = locName);
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

  String _formatDisplayLocation(String rawLocation) {
    if (rawLocation.trim().isEmpty) return '';
    String clean = rawLocation.replaceAll(RegExp(r'\b\d{5,6}\b'), '').trim();
    List<String> parts = clean.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && s != 'null').toList();
    if (parts.isEmpty) return rawLocation;
    if (parts.length == 1) return parts.first;
    parts.removeWhere((p) {
      final l = p.toLowerCase();
      return (l == 'india' || l == 'uttar pradesh' || l == 'up' || l == 'maharashtra' || l == 'karnataka' || l == 'delhi') && parts.length > 2;
    });
    if (parts.length >= 3) return '${parts.first}, ${parts.last}';
    if (parts.length == 2) return '${parts[0]}, ${parts[1]}';
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = UserManager();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
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
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    Flexible(
                      child: TextButton.icon(
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
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
}

class PostCardWidget extends StatelessWidget {
  final Post post;
  const PostCardWidget({super.key, required this.post});

  String _formatDisplayLocation(String rawLocation) {
    if (rawLocation.trim().isEmpty) return '';
    String clean = rawLocation.replaceAll(RegExp(r'\b\d{5,6}\b'), '').trim();
    List<String> parts = clean.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && s != 'null').toList();
    if (parts.isEmpty) return rawLocation;
    if (parts.length == 1) return parts.first;
    parts.removeWhere((p) {
      final l = p.toLowerCase();
      return (l == 'india' || l == 'uttar pradesh' || l == 'up' || l == 'maharashtra' || l == 'karnataka' || l == 'delhi') && parts.length > 2;
    });
    if (parts.length >= 3) return '${parts.first}, ${parts.last}';
    if (parts.length == 2) return '${parts[0]}, ${parts[1]}';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = _formatPostTime(post.createdAt);
    final myId = UserManager().userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: post.userId, userName: post.userName, userImage: post.userImage))),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: post.userId, userName: post.userName, userImage: post.userImage))),
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
              if (post.userId == myId)
                _PostMenuButton(postId: post.id, post: post),
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
                  height: 280,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 280,
                      width: double.infinity,
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (c, e, s) => Container(
                    height: 280,
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
              _PostActionButton(
                icon: post.likes.contains(myId) ? Icons.favorite : Icons.favorite_border,
                label: post.likes.length.toString(),
                color: post.likes.contains(myId) ? Colors.red : colorScheme.primary,
                onTap: () => PostManager().likePost(post.id),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 12),
              _PostActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.comments.length}',
                color: Colors.grey[600]!,
                onTap: () => _showCommentSheet(context, post),
                colorScheme: colorScheme,
              ),
              const Spacer(),
              _PostActionButton(
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

  void _showCommentSheet(BuildContext context, Post post) {
    final TextEditingController commentController = TextEditingController();
    final token = UserManager().token;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colorScheme = Theme.of(context).colorScheme;

          // Fetch fresh comments from backend if available
          if (token != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ApiService.getComments(post.id, token).then((res) {
                if (res['success'] == true && res['data'] != null) {
                  final List rawList = res['data'] is List 
                      ? res['data'] 
                      : (res['data']['comments'] is List ? res['data']['comments'] : []);
                  if (rawList.isNotEmpty) {
                    final List<Comment> freshComments = rawList
                        .map((c) => Comment.fromJson(c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c as Map)))
                        .toList();
                    if (freshComments.length != post.comments.length ||
                        freshComments.any((fc) => Post.isIdString(fc.userName) || fc.userName == 'Member')) {
                      post.comments.clear();
                      post.comments.addAll(freshComments);
                      setSheetState(() {});
                    }
                  }
                }
              }).catchError((_) {});
            });
          }

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
                          String? authorImg = comment.userImage;

                          final myId = UserManager().userId;
                          final myName = UserManager().userName;
                          final myEmail = UserManager().userEmail;

                          if (authorName.isEmpty ||
                              authorName.toLowerCase() == 'user' ||
                              authorName.toLowerCase() == 'anonymous' ||
                              authorName.toLowerCase() == 'member' ||
                              Post.isIdString(authorName)) {
                            if (myId != null && myId.isNotEmpty && comment.userId == myId) {
                              if (myName != null && myName.trim().isNotEmpty && myName.trim().toLowerCase() != 'user' && !Post.isIdString(myName)) {
                                authorName = myName.trim();
                              } else if (myEmail != null && myEmail.contains('@')) {
                                authorName = myEmail.split('@').first;
                              } else {
                                authorName = 'Member';
                              }
                              authorImg ??= UserManager().profilePicture;
                            } else if (post.userId.isNotEmpty && comment.userId == post.userId && post.userName.isNotEmpty && !Post.isIdString(post.userName)) {
                              authorName = post.userName;
                              authorImg ??= post.userImage;
                            } else if (UserCache.getName(comment.userId) != null) {
                              authorName = UserCache.getName(comment.userId)!;
                              authorImg ??= UserCache.getImage(comment.userId);
                            } else {
                              final feedMatch = PostManager().feed.where((p) => p.userId.isNotEmpty && p.userId == comment.userId && p.userName.isNotEmpty && !Post.isIdString(p.userName)).firstOrNull;
                              if (feedMatch != null) {
                                authorName = feedMatch.userName;
                                authorImg ??= feedMatch.userImage;
                                UserCache.set(comment.userId, authorName, authorImg);
                              } else {
                                authorName = 'Member';
                                if (comment.userId.isNotEmpty && token != null) {
                                  UserCache.fetchMissingUser(comment.userId, token, () {
                                    setSheetState(() {});
                                  });
                                }
                              }
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
                                  backgroundImage: authorImg != null && authorImg.isNotEmpty ? NetworkImage(authorImg) : null,
                                  child: (authorImg == null || authorImg.isEmpty) 
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
                          decoration: const InputDecoration(hintText: 'Write a comment...', border: InputBorder.none),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;
                          final text = commentController.text.trim();
                          commentController.clear();
                          final success = await PostManager().addComment(post.id, text);
                          if (success && context.mounted) {
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

class _PostMenuButton extends StatelessWidget {
  final String postId;
  final Post post;
  const _PostMenuButton({required this.postId, required this.post});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 12), Text('Edit')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
      ],
      onSelected: (val) {
        if (val == 'edit') {
          _showEditDialog(context, post);
        } else if (val == 'delete') {
          _showDeleteDialog(context, postId);
        }
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String id) {
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
              final success = await PostManager().deletePost(id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
              }
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Post p) {
    final TextEditingController editController = TextEditingController(text: p.content);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          maxLines: 4,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isEmpty) return;
              Navigator.pop(context);
              final success = await PostManager().editPost(p.id, newContent);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated'), backgroundColor: Colors.green));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _PostActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _PostActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
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
}
