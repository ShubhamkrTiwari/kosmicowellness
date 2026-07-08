import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../managers/theme_manager.dart';
import '../managers/user_manager.dart';
import '../managers/wishlist_manager.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'help_center_screen.dart';
import 'my_orders_screen.dart';
import 'payment_methods_screen.dart';
import 'shipping_addresses_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final wishlistManager = WishlistManager();
  final userManager = UserManager();
  late String userName;
  late String userEmail;
  late String userPhone;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await userManager.init();
    setState(() {
      userName = userManager.userName ?? 'Guest User';
      userEmail = userManager.userEmail ?? 'Not logged in';
      userPhone = userManager.userPhone ?? 'Add phone number';
    });
  }

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

        // Ensure token is loaded
        await userManager.init();
        final token = userManager.token;
        
        if (token == null || token.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication error. Please login again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        // Backend API Call to save the image immediately
        final result = await ApiService.updateProfileWithImage(
          name: userName,
          phoneNumber: userPhone == 'Add phone number' ? '' : userPhone,
          imageFile: pickedFile,
          token: token,
        );

        if (result['success']) {
          await userManager.saveUser(result['data']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to sync with server: ${result['message']}'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
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
    final phoneController = TextEditingController(text: userPhone == 'Add phone number' ? '' : userPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final colorScheme = Theme.of(context).colorScheme;
            return Padding(
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
                    decoration: _inputDecoration('Full Name', Icons.person_outline),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    readOnly: true,
                    enabled: false,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    decoration: _inputDecoration('Email Address', Icons.email_outlined).copyWith(
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final newName = nameController.text.trim();
                    final newPhone = phoneController.text.trim();

                    if (newName.isNotEmpty) {
                      setModalState(() => isSaving = true);
                      
                      // Ensure token is loaded
                      await userManager.init();
                      final token = userManager.token;
                      
                      if (token == null || token.isEmpty) {
                        setModalState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Authentication error. Please login again.'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }
                      
                      final result = await ApiService.updateProfileWithImage(
                        name: newName,
                        phoneNumber: newPhone,
                        imageFile: _pickedImage, // Use the currently picked image if any
                        token: token,
                      );

                      if (result['success']) {
                        // Backend returns the new user data including image URL
                        await userManager.saveUser(result['data']);
                        
                        setState(() {
                          userName = userManager.userName ?? newName;
                          userEmail = userManager.userEmail ?? userEmail;
                          userPhone = userManager.userPhone ?? (newPhone.isEmpty ? 'Add phone number' : newPhone);
                        });
                        
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        setModalState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSaving 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
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
                          child: _pickedImage == null && userManager.profilePicture == null
                              ? Text(
                                  _getInitials(userName),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : ClipOval(
                                  child: _pickedImage != null
                                      ? (kIsWeb
                                          ? Image.network(
                                              _pickedImage!.path,
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                            )
                                          : Image.file(
                                              File(_pickedImage!.path),
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                            ))
                                      : Image.network(
                                          userManager.profilePicture!,
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
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userPhone,
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    ThemeManager().isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  ThemeManager().isDarkMode ? 'Currently Dark' : 'Currently Light',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Switch(
                  value: ThemeManager().isDarkMode,
                  onChanged: (value) async {
                    await ThemeManager().toggleTheme();
                    setState(() {});
                  },
                  activeTrackColor: colorScheme.primary,
                ),
              ),
            ),
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
                  onPressed: () async {
                    await userManager.logout();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                        (route) => false,
                      );
                    }
                  },
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap ?? () {},
      ),
    );
  }
}
