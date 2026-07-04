import 'package:flutter/material.dart';
import 'help_center_screen.dart';
import 'payment_methods_screen.dart';
import 'shipping_addresses_screen.dart';
import 'my_orders_screen.dart';
import 'wishlist_screen.dart';
import '../managers/wishlist_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final wishlistManager = WishlistManager();
  String userName = 'Shubham Tiwari';
  String userEmail = 'shubham.tiwari@example.com';
  XFile? _pickedImage;

  String _getInitials(String name) {
    try {
      if (name.trim().isEmpty) return '??';
      List<String> parts = name.trim().split(' ');
      String initials = '';
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials += parts[0][0].toUpperCase();
      }
      if (parts.length > 1 && parts[parts.length - 1].isNotEmpty) {
        initials += parts[parts.length - 1][0].toUpperCase();
      }
      return initials.isEmpty ? name.trim()[0].toUpperCase() : initials;
    } catch (e) {
      return '??';
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditProfileSheet() {
    final nameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: userEmail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 30,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: _inputDecoration('Full Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: _inputDecoration('Email Address'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    userName = nameController.text.isNotEmpty ? nameController.text : userName;
                    userEmail = emailController.text.isNotEmpty ? emailController.text : userEmail;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          border: Border.all(color: colorScheme.primary, width: 2),
                        ),
                        child: Center(
                          child: _pickedImage == null
                              ? Text(
                                  _getInitials(userName),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : ClipOval(
                                  child: kIsWeb
                                      ? Image.network(
                                          _pickedImage!.path,
                                          fit: BoxFit.cover,
                                          width: 80,
                                          height: 80,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(_getInitials(userName));
                                          },
                                        )
                                      : Image.file(
                                          File(_pickedImage!.path),
                                          fit: BoxFit.cover,
                                          width: 80,
                                          height: 80,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(_getInitials(userName));
                                          },
                                        ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'Pitta Dosha',
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEditProfileSheet,
                    icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Wellness Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Orders', '12', Icons.local_shipping_outlined, colorScheme),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const WishlistScreen()),
                      ).then((_) => setState(() {}));
                    },
                    child: _buildStatItem('Wishlist', wishlistManager.items.length.toString(), Icons.favorite_border, colorScheme),
                  ),
                  _buildStatItem('Coupons', '3', Icons.confirmation_number_outlined, colorScheme),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Settings Section
            _buildSectionHeader('Account Settings', colorScheme),
            _buildMenuItem(Icons.shopping_bag_outlined, 'My Orders', 'Track and manage your orders', colorScheme, onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
              );
            }),
            _buildMenuItem(Icons.location_on_outlined, 'Shipping Addresses', 'Manage your delivery locations', colorScheme, onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ShippingAddressesScreen()),
              );
            }),
            _buildMenuItem(Icons.payment_outlined, 'Payment Methods', 'Saved cards and UPI', colorScheme, onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
              );
            }),
            
            const SizedBox(height: 20),
            
            _buildSectionHeader('Wellness Profile', colorScheme),
            _buildMenuItem(Icons.health_and_safety_outlined, 'My Dosha Profile', 'View your Ayurvedic constitution', colorScheme),
            _buildMenuItem(Icons.history_outlined, 'Consultation History', 'Previous sessions with doctors', colorScheme),

            const SizedBox(height: 20),

            _buildSectionHeader('Support & Preferences', colorScheme),
            _buildMenuItem(Icons.help_outline, 'Help Center', 'FAQs and support chat', colorScheme, onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
              );
            }),
            _buildMenuItem(Icons.info_outline, 'About Kosmico', 'Our story and values', colorScheme),

            const SizedBox(height: 30),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 120), // Bottom padding for floating nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary.withValues(alpha: 0.7),
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, ColorScheme colorScheme, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap ?? () {},
      ),
    );
  }
}
