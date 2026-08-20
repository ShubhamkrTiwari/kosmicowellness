import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:io' as io;
import '../../managers/care_manager.dart';
import '../../managers/user_manager.dart';
import '../../services/api_service.dart';
import '../../services/report_service.dart';

class CareNetworkModule extends StatefulWidget {
  const CareNetworkModule({super.key});

  @override
  State<CareNetworkModule> createState() => _CareNetworkModuleState();
}

class _CareNetworkModuleState extends State<CareNetworkModule> {
  bool _isGettingLocation = false;
  int _selectedNetworkTab = 0; // 0 for Social, 1 for My Activity

  Future<void> _pickContact(TextEditingController nameCtrl, TextEditingController phoneCtrl) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact picking is not supported on Web. Please enter manually.')),
      );
      return;
    }

    try {
      if (await (FlutterContacts as dynamic).requestPermission()) {
        // Use dynamic to bypass compilation errors on Web where this member is missing
        final dynamic contact = await (FlutterContacts as dynamic).openExternalPicker();
        if (contact != null) {
          final dynamic fullContact = await (FlutterContacts as dynamic).getContact(contact.id);
          if (fullContact != null) {
            nameCtrl.text = fullContact.displayName ?? '';
            if (fullContact.phones != null && (fullContact.phones as List).isNotEmpty) {
              phoneCtrl.text = fullContact.phones.first.number ?? '';
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission denied')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().contains('openExternalPicker') ? 'Native picker not available' : e}')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch dialer for $phoneNumber')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching dialer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: CareManager(),
      builder: (context, _) {
        final manager = CareManager();
        final contacts = manager.contacts;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colorScheme, context),
              const SizedBox(height: 16),
              ...List.generate(contacts.length, (index) {
                final c = contacts[index];
                return _buildContactCard(c['name'], c['phone'], index, colorScheme);
              }),
              const SizedBox(height: 24),
              _buildHypoAlertSection(colorScheme, context),
              const SizedBox(height: 24),
              _buildClinicalReportSection(colorScheme, context),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Peer Support Network', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    onPressed: () => _showAddPostDialog(context),
                    icon: Icon(Icons.add_comment_outlined, color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Custom Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTabButton('Social Feed', 0, colorScheme)),
                    Expanded(child: _buildTabButton('My Activity', 1, colorScheme)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Conditional Feed View (Fixed height issue and assertion error)
              if (_selectedNetworkTab == 0)
                _buildPostList(manager.communityPosts.where((p) => p['user'] != 'You').toList(), colorScheme)
              else
                _buildPostList(manager.communityPosts.where((p) => p['user'] == 'You').toList(), colorScheme, isMyActivity: true),
              
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, int index, ColorScheme colorScheme) {
    final bool isSelected = _selectedNetworkTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNetworkTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPostList(List<Map<String, dynamic>> posts, ColorScheme colorScheme, {bool isMyActivity = false}) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(isMyActivity ? 'You haven\'t posted anything yet.' : 'No social posts found.', 
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildPostCard(posts[index], colorScheme),
    );
  }

  void _showAddPostDialog(BuildContext context) {
    final contentController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    XFile? pickedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Share your thoughts'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "How's your wellness journey today?",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pickedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb 
                            ? Image.network(pickedImage!.path, height: 180, width: double.infinity, fit: BoxFit.cover)
                            : Image.file(io.File(pickedImage!.path), height: 180, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setDialogState(() => pickedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                          );
                          if (image != null) {
                            setDialogState(() => pickedImage = image);
                          }
                        } catch (e) {
                          debugPrint('Image Pick Error: $e');
                        }
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Add Image'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (contentController.text.isNotEmpty) {
                  CareManager().addCommunityPost(
                    'You', 
                    contentController.text, 
                    image: pickedImage?.path
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, ColorScheme colorScheme) {
    final String id = post['id'] ?? '';
    final String user = post['user'] ?? 'User';
    final String time = post['time'] ?? 'Recently';
    final String content = post['content'] ?? '';
    final String? image = post['image'];
    final int likes = post['likes'] ?? 0;
    final bool isLiked = post['isLiked'] ?? false;
    final List comments = post['comments'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: colorScheme.primary.withValues(alpha: 0.1), child: Text(user[0], style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                ],
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'delete') {
                    CareManager().deletePost(id);
                  } else if (value == 'report') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post reported.')));
                  }
                },
                itemBuilder: (context) => [
                  if (user == 'You')
                    const PopupMenuItem(value: 'delete', child: Text('Delete Post')),
                  if (user != 'You')
                    const PopupMenuItem(value: 'report', child: Text('Report')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.5)),
          if (image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildPostImage(image),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => CareManager().toggleLike(id),
                child: Row(
                  children: [
                    Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 18, color: isLiked ? Colors.red : colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(likes.toString(), style: TextStyle(color: isLiked ? Colors.red : colorScheme.primary, fontSize: 12, fontWeight: isLiked ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showCommentsBottomSheet(context, post),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(comments.isEmpty ? 'Comment' : comments.length.toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Share.share('$content\n\nShared via Kosmico Wellness'),
                icon: const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, Map<String, dynamic> post) {
    final TextEditingController commentController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListenableBuilder(
                listenable: CareManager(),
                builder: (context, _) {
                  final posts = CareManager().communityPosts;
                  // Handle cases where post might have been deleted or id changed
                  Map<String, dynamic>? currentPost;
                  try {
                    currentPost = posts.firstWhere((p) => p['id'] == post['id']);
                  } catch (_) {
                    currentPost = post;
                  }
                  
                  final List comments = currentPost['comments'] ?? [];
                  
                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text('No comments yet.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16, 
                              backgroundColor: colorScheme.primary.withOpacity(0.1),
                              child: Text((c['user'] ?? 'U')[0], style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold))
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(c['user'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Text(c['time'] ?? 'Just now', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c['text'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    child: IconButton(
                      onPressed: () {
                        if (commentController.text.trim().isNotEmpty) {
                          CareManager().addComment(post['id'], commentController.text.trim());
                          commentController.clear();
                          // Keep sheet open
                        }
                      },
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImage(String image) {
    if (image.startsWith('http') || kIsWeb) {
      return Image.network(image, height: 150, width: double.infinity, fit: BoxFit.cover, 
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50, color: Colors.grey));
    }
    return Image.file(io.File(image), height: 150, width: double.infinity, fit: BoxFit.cover,
      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50, color: Colors.grey));
  }

  Widget _buildHeader(ColorScheme colorScheme, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        TextButton.icon(
          onPressed: () => _showAddContactDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildContactCard(String name, String phone, int index, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => CareManager().deleteContact(index),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(phone),
            icon: const Icon(Icons.call, color: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb) ...[
              OutlinedButton.icon(
                onPressed: () => _pickContact(nameController, phoneController),
                icon: const Icon(Icons.contact_phone_outlined, size: 18),
                label: const Text('Pick from Contacts', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(hintText: 'Phone'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                CareManager().saveContact(nameController.text, phoneController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildHypoAlertSection(ColorScheme colorScheme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          const Text('Hypo-Alert', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          const Text(
            'Notify your care network with your real live location in case of a glucose emergency.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isGettingLocation ? null : () => _handleHypoAlert(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: _isGettingLocation 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Trigger Emergency Alert'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleHypoAlert(BuildContext context) async {
    setState(() => _isGettingLocation = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // 1. Get Live Location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 2. Get readable address (Mobile Only)
      String address = 'Address lookup not supported on web';
      if (!kIsWeb) {
        try {
          List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            address = '${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}';
          }
        } catch (e) {
          address = 'Coordinates: ${position.latitude}, ${position.longitude}';
        }
      } else {
        address = 'Location: Lat ${position.latitude.toStringAsFixed(4)}, Long ${position.longitude.toStringAsFixed(4)}';
      }

      // 3. Call Backend / Prepare Message
      final token = UserManager().token;
      final String googleMapsLink = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      final String localFallbackText = '🚨 URGENT: I am having a glucose emergency and need immediate assistance! My live location: $googleMapsLink';
      
      String shareableText = localFallbackText;

      if (token != null) {
        try {
          final result = await ApiService.generateEmergencyMessage(
            latitude: position.latitude,
            longitude: position.longitude,
            token: token,
          );

          if (result['success'] == true && result['data'] != null) {
            shareableText = result['data']['shareableText'] ?? localFallbackText;
          }
        } catch (e) {
          debugPrint('Emergency API Error: $e');
        }
      }

      // 4. Open native share sheet
      try {
        await Share.share(shareableText);
      } catch (e) {
        debugPrint('Share Error: $e');
      }

      if (mounted) {
        _showEmergencySentDialog(context, address, shareableText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alert Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _showEmergencySentDialog(BuildContext context, String address, String shareableText) {
    final contacts = CareManager().contacts;
    showDialog(
      context: context,
      barrierDismissible: false, // Force interaction
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Icon(Icons.emergency_share, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text('ALERT READY!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency message and live location are ready to be shared:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(address, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
            ),
            const SizedBox(height: 16),
            Text(
              'Care Network: ${contacts.map((c) => c['name']).join(', ')}',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Share.share(shareableText),
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text('SHARE NOW', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSmsSimulation(context, shareableText);
                  },
                  icon: const Icon(Icons.sms, size: 20),
                  label: const Text('SIMULATE SMS ALERT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DISMISS', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSmsSimulation(BuildContext context, String message) {
    final contacts = CareManager().contacts;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sms, color: Colors.blue),
            SizedBox(width: 12),
            Text('Simulating SMS...', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text('Sending emergency SMS to ${contacts.length} contacts:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Text(message, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildClinicalReportSection(ColorScheme colorScheme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Clinical Report', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Generate a formal medical report of your real glucose logs and trends.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReportPreview(context),
              icon: const Icon(Icons.description_outlined),
              label: const Text('View Clinical Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final manager = CareManager();
    final reportText = manager.generateClinicalReport();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Report',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.primary),
                      ),
                      Text(
                        'Preview of your health logs',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    reportText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Share.share(reportText, subject: 'My Glucose Report - Kosmico Wellness');
                      },
                      icon: const Icon(Icons.text_snippet_outlined, size: 18),
                      label: const Text('Share Text'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ReportService.shareClinicalReport(manager);
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Share PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
