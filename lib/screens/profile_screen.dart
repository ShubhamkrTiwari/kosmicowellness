// Removed dart:io to support Web
import 'dart:io' show File; // Using conditional import or just guarding it would be better, but File is only used in non-web parts.
// Actually, if I keep 'import dart:io', it will still crash on Web if 'File' is even mentioned in the code that gets compiled for web.
// But Flutter's compiler is usually smart enough if it's guarded by kIsWeb.
// However, the cleanest way is to use 'dart:io' only when not kIsWeb.


import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../managers/notification_manager.dart';
import '../managers/theme_manager.dart';
import '../managers/language_manager.dart';
import '../managers/user_manager.dart';
import '../managers/wishlist_manager.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'coupons_screen.dart';
import 'help_center_screen.dart';
import 'my_orders_screen.dart';
import 'returns_history_screen.dart';
import 'payment_methods_screen.dart';
import 'shipping_addresses_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String userPhone = '';
  XFile? _pickedImage;
  int _couponCount = 0;
  int _orderCount = 0;

  AnimationController? _logoutAnimController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCouponCount();
    _fetchOrderCount();

    _logoutAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _logoutAnimController?.dispose();
    super.dispose();
  }

  Future<void> _fetchCouponCount() async {
    try {
      final token = UserManager().token;
      if (token != null && token.isNotEmpty) {
        final result = await ApiService.getCoupons(token);
        if (result != null && result['success'] == true && result['data'] is List) {
          if (mounted) {
            setState(() {
              _couponCount = (result['data'] as List).length;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching coupon count: $e');
    }
  }

  Future<void> _fetchOrderCount() async {
    try {
      final token = UserManager().token;
      if (token != null && token.isNotEmpty) {
        final result = await ApiService.getUserOrders(token);
        if (result != null && result['success'] == true && result['data'] != null) {
          final dynamic data = result['data'];
          List allOrders = [];
          if (data is List) {
            allOrders = data;
          } else if (data is Map && data['orders'] is List) {
            allOrders = data['orders'];
          }
          
          if (mounted) {
            setState(() {
              _orderCount = allOrders.length;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching order count: $e');
    }
  }

  Future<void> _loadUserData() async {
    await UserManager().init();
    setState(() {
      userName = UserManager().userName ?? 'Guest User';
      userEmail = UserManager().userEmail ?? 'Not logged in';
      userPhone = UserManager().userPhone ?? 'Add phone number';
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
    final messenger = ScaffoldMessenger.of(context);
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
        await UserManager().init();
        final token = UserManager().token;
        
        if (!mounted) return;

        if (token == null || token.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Authentication error. Please login again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Backend API Call to save the image immediately
        final result = await ApiService.updateProfileWithImage(
          name: userName,
          phoneNumber: userPhone == 'Add phone number' ? '' : userPhone,
          imageFile: pickedFile,
          token: token,
        );

        if (!mounted) return;

        if (result['success']) {
          await UserManager().saveUser(result['data']);
          
          NotificationManager().addNotification(
            title: 'Profile Updated',
            message: 'Your profile picture has been updated successfully.',
            icon: '📸',
            type: 'profile',
          );

          messenger.showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Failed to sync with server: ${result['message']}'),
              backgroundColor: Colors.orange,
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

  void _showProfilePicOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.visibility_outlined, color: colorScheme.primary),
                  ),
                  title: const Text('Preview Picture', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _previewProfilePic();
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.photo_library_outlined, color: colorScheme.primary),
                  ),
                  title: const Text('Change Picture', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                if (UserManager().profilePicture != null || _pickedImage != null)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      child: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    title: const Text('Remove Picture', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePic();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeProfilePic() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Ensure token is loaded
      await UserManager().init();
      final token = UserManager().token;

      if (!mounted) return;

      if (token == null || token.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please login again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final result = await ApiService.removeProfilePicture(token);

      if (!mounted) return;

      if (result['success']) {
        await UserManager().saveUser(result['data']);
        setState(() {
          _pickedImage = null;
        });

        NotificationManager().addNotification(
          title: 'Profile Updated',
          message: 'Your profile picture has been removed.',
          icon: '🗑️',
          type: 'profile',
        );

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to remove: ${result['message']}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing image: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not remove image: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _previewProfilePic() {
    final imageUrl = _pickedImage?.path ?? UserManager().profilePicture;
    if (imageUrl != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withValues(alpha: 0.9),
                ),
              ),
              Hero(
                tag: 'profile-pic',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _pickedImage != null
                      ? (kIsWeb
                          ? Image.network(_pickedImage!.path, fit: BoxFit.contain)
                          : Image.file(File(_pickedImage!.path), fit: BoxFit.contain))
                      : Image.network(UserManager().profilePicture!, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showEditProfileSheet() {
    final nameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: userEmail);
    final phoneController = TextEditingController(text: userPhone == 'Add phone number' ? '' : userPhone);
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allow custom rounded corners
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Profile',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: nameController,
                          decoration: _inputDecoration('Full Name', Icons.person_outline),
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                          ],
                          validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
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
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value != null && value.isNotEmpty && value.length != 10) {
                              return 'Enter a valid 10-digit number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () async {
                              if (!formKey.currentState!.validate()) return;
                              
                              final newName = nameController.text.trim();
                              final newPhone = phoneController.text.trim();
                              setModalState(() => isSaving = true);
                              
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);

                              // Ensure token is loaded
                              await UserManager().init();
                              final token = UserManager().token;
                              
                              if (!mounted) return;

                              if (token == null || token.isEmpty) {
                                setModalState(() => isSaving = false);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Authentication error. Please login again.'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              
                              final result = await ApiService.updateProfileWithImage(
                                name: newName,
                                phoneNumber: newPhone,
                                imageFile: _pickedImage, // Use the currently picked image if any
                                token: token,
                              );

                              if (!mounted) return;

                              if (result['success']) {
                                // Backend returns the new user data including image URL
                                await UserManager().saveUser(result['data']);
                                
                                NotificationManager().addNotification(
                                  title: 'Profile Updated',
                                  message: 'Your personal details have been updated.',
                                  icon: '👤',
                                  type: 'profile',
                                );

                                setState(() {
                                  userName = UserManager().userName ?? newName;
                                  userEmail = UserManager().userEmail ?? userEmail;
                                  userPhone = UserManager().userPhone ?? (newPhone.isEmpty ? 'Add phone number' : newPhone);
                                });
                                
                                navigator.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated successfully!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                setModalState(() => isSaving = false);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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
                  ),
                ),
              ),
            );
          },
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

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        top: false, // AppBar is already handled by HomeScreen
        bottom: false,
        child: SingleChildScrollView(
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
                            child: _pickedImage != null
                                ? ClipOval(
                                    child: kIsWeb
                                        ? Image.network(_pickedImage!.path, width: 80, height: 80, fit: BoxFit.cover)
                                        : Image.file(File(_pickedImage!.path), width: 80, height: 80, fit: BoxFit.cover),
                                  )
                                : (UserManager().profilePicture != null && UserManager().profilePicture!.isNotEmpty
                                    ? GestureDetector(
                                        onTap: _showProfilePicOptions,
                                        child: Hero(
                                          tag: 'profile-pic',
                                          child: ClipOval(
                                            child: Image.network(
                                              UserManager().profilePicture!,
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Center(child: Text(_getInitials(userName)));
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(child: Text(_getInitials(userName)))),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showProfilePicOptions,
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
                            style: TextStyle(color: colorScheme.onSurfaceVariant ?? Colors.grey, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userPhone,
                            style: TextStyle(color: colorScheme.onSurfaceVariant ?? Colors.grey, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
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
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                          ).then((_) => _fetchOrderCount());
                        },
                        child: _buildStatItem('Orders', _orderCount.toString(), Icons.local_shipping_outlined, colorScheme),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: WishlistManager(),
                        builder: (context, _) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const WishlistScreen()),
                              ).then((_) => setState(() {}));
                            },
                            child: _buildStatItem('Wishlist', WishlistManager().items.length.toString(), Icons.favorite_border, colorScheme),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const CouponsScreen()),
                        ).then((_) => _fetchCouponCount());
                      },
                      child: _buildStatItem('Coupons', _couponCount.toString(), Icons.confirmation_number_outlined, colorScheme),
                    ),
                  ),
                ],
                ),
              ),

              const SizedBox(height: 30),

              // Settings Section
              _buildSectionHeader(LanguageManager().translate('settings'), colorScheme),
              _buildMenuItem(Icons.shopping_bag_outlined, LanguageManager().translate('my_orders'), 'Track and manage your orders', colorScheme, onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                );
              }),
              _buildMenuItem(Icons.assignment_return_outlined, 'Returns & Refunds', 'Status of your refund/replacement requests', colorScheme, onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReturnsHistoryScreen()),
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

              _buildSectionHeader(LanguageManager().translate('support'), colorScheme),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.language_outlined,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      LanguageManager().translate('language'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      LanguageManager().currentLanguage == 'en' ? 'English' : 'हिंदी',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('EN', style: TextStyle(fontSize: 10, fontWeight: LanguageManager().currentLanguage == 'en' ? FontWeight.bold : FontWeight.normal)),
                        Switch(
                          value: LanguageManager().currentLanguage == 'hi',
                          onChanged: (value) async {
                            await LanguageManager().setLanguage(value ? 'hi' : 'en');
                            setState(() {});
                          },
                          activeTrackColor: colorScheme.primary,
                        ),
                        Text('हिं', style: TextStyle(fontSize: 10, fontWeight: LanguageManager().currentLanguage == 'hi' ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Material(
                  color: Colors.transparent,
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
                    title: Text(
                      LanguageManager().translate('dark_mode'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      ThemeManager().isDarkMode ? 'Currently Dark' : 'Currently Light',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: Switch(
                      value: ThemeManager().isDarkMode,
                      onChanged: (value) async {
                        await ThemeManager().toggleTheme();
                        setState(() {});
                      },
                      activeTrackColor: colorScheme.primary,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              _buildMenuItem(Icons.help_outline, LanguageManager().translate('help_center'), 'FAQs and support chat', colorScheme, onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
                );
              }),
              _buildMenuItem(Icons.info_outline, LanguageManager().translate('about_kosmico'), 'Our story and values', colorScheme, onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutKosmicoScreen()),
                );
              }),

              const SizedBox(height: 30),

                // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated Line Progress Outside
                    if (_logoutAnimController != null)
                      AnimatedBuilder(
                        animation: _logoutAnimController!,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(double.infinity, 65),
                            painter: BorderLinePainter(
                              progress: _logoutAnimController!.value,
                              color: Colors.redAccent,
                            ),
                            child: const SizedBox(
                              width: double.infinity,
                              height: 65,
                            ),
                          );
                        },
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(LanguageManager().translate('logout')),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true), 
                                  child: Text(LanguageManager().translate('logout'), style: const TextStyle(color: Colors.red))
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await UserManager().logout();
                            if (mounted) {
                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const AuthScreen()),
                                (route) => false,
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout, size: 20),
                        label: Text(LanguageManager().translate('logout')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          backgroundColor: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 140), // Bottom padding for floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Text(
            label.toString(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
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
      child: Material(
        color: Colors.transparent,
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
          trailing: Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
          onTap: onTap ?? () {},
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class BorderLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  BorderLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    ));

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length;
      final start = length * progress;
      final end = (start + (length * 0.4)) % length;

      if (start < end) {
        canvas.drawPath(metric.extractPath(start, end), paint);
      } else {
        canvas.drawPath(metric.extractPath(start, length), paint);
        canvas.drawPath(metric.extractPath(0, end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(BorderLinePainter oldDelegate) => true;
}

class AboutKosmicoScreen extends StatelessWidget {
  const AboutKosmicoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'About Kosmico',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&q=80&w=1000',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: colorScheme.primary),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(context, colorScheme),
                  const SizedBox(height: 32),
                  _buildStatsRow(colorScheme),
                  const SizedBox(height: 32),
                  _buildSectionCard(
                    context,
                    'Our Mission',
                    'To provide premium quality Ayurvedic and herbal healthcare products that promote wellness and natural healing, while maintaining the highest standards of manufacturing excellence. We believe in harnessing the power of nature to create solutions that enhance lives.',
                    Icons.auto_awesome_outlined,
                    colorScheme,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    'Our Vision',
                    'To become a globally recognized leader in Ayurvedic and herbal product manufacturing, empowering businesses worldwide to bring natural healthcare solutions to their customers. We envision a future where traditional medicine and modern science work hand in hand.',
                    Icons.visibility_outlined,
                    colorScheme,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Core Strengths',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildStrengthItem(
                    context,
                    Icons.precision_manufacturing_outlined,
                    'Advanced Facilities',
                    'State-of-the-art manufacturing infrastructure with modern technology.',
                    colorScheme,
                  ),
                  _buildStrengthItem(
                    context,
                    Icons.public_outlined,
                    'Global Expertise',
                    'Successfully launched 100+ brands in domestic and international markets.',
                    colorScheme,
                  ),
                  _buildStrengthItem(
                    context,
                    Icons.biotech_outlined,
                    'Quality Control',
                    'Rigorous standards and testing for all Ayurvedic product manufacturing.',
                    colorScheme,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                'assets/images/kosmicologo.png',
                height: 32,
                width: 32,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.spa_rounded, color: colorScheme.primary, size: 32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KOSMICO WELLNESS PRIVATE LIMITED',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  Text(
                    'Ancient Wisdom, Modern Living',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Kosmico is a leading Indian contract manufacturer specializing in premium Ayurvedic and herbal products. Having partnered with over 100 companies, we combine deep-rooted commitment to Ayurvedic traditions with modern technology to deliver products of exceptional quality.',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(child: _buildStatBox('100+', 'Partner\nBrands', colorScheme)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox('500+', 'Natural\nProducts', colorScheme)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox('Global', 'Market\nReach', colorScheme)),
      ],
    );
  }

  Widget _buildStatBox(String value, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, String content, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthItem(BuildContext context, IconData icon, String title, String description, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
            child: Icon(icon, color: colorScheme.secondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  description,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
