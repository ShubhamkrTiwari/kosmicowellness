import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';

import '../managers/user_manager.dart';
import '../services/api_service.dart';
import 'map_picker_screen.dart';

class ShippingAddressesScreen extends StatefulWidget {
  final bool isSelectionMode;
  const ShippingAddressesScreen({super.key, this.isSelectionMode = false});

  @override
  State<ShippingAddressesScreen> createState() => _ShippingAddressesScreenState();
}

class _ShippingAddressesScreenState extends State<ShippingAddressesScreen> {
  final List<Map<String, String>> _addresses = [];
  final userManager = UserManager();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    if (mounted) setState(() => isLoading = true);
    await userManager.init();
    final token = userManager.token;
    
    if (token != null && token.isNotEmpty) {
      final result = await ApiService.getAddresses(token);
      if (result['success'] && mounted) {
        setState(() {
          _addresses.clear();
          if (result['data'] is List) {
            for (var addr in result['data']) {
              _addresses.add({
                'id': addr['_id'] is Map ? addr['_id']['\$oid']?.toString() ?? '' : addr['_id']?.toString() ?? addr['id']?.toString() ?? '',
                'label': addr['addressLabel']?.toString() ?? 'Home',
                'name': addr['fullName']?.toString() ?? '',
                'address': addr['streetAddress']?.toString() ?? '',
                'city': addr['city']?.toString() ?? '',
                'pincode': addr['pincode']?.toString() ?? '',
                'phone': addr['phoneNumber']?.toString() ?? '',
                'isDefault': addr['isDefault']?.toString() ?? 'false',
              });
            }
          }
        });
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _showAddressBottomSheet({int? index}) {
    final isEditing = index != null;
    final address = isEditing ? _addresses[index] : null;

    final labelController = TextEditingController(text: address?['label'] ?? 'Home');
    final nameController = TextEditingController(text: address?['name'] ?? '');
    final addressController = TextEditingController(text: address?['address'] ?? '');
    final cityController = TextEditingController(text: address?['city'] ?? '');
    final pincodeController = TextEditingController(text: address?['pincode'] ?? '');
    final phoneController = TextEditingController(text: address?['phone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        bool isSaving = false;
        bool isDefaultValue = address?['isDefault'] == 'true';
        final formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 30,
              left: 24,
              right: 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Address' : 'Add New Address',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MapPickerScreen()),
                            );

                            if (result != null && result is Map) {
                              if (result['placemark'] != null) {
                                Placemark place = result['placemark'];
                                setModalState(() {
                                  // Intelligent merging of Landmark (name) and Street
                                  String landmark = place.name ?? '';
                                  String street = place.street ?? '';
                                  
                                  List<String> addressParts = [];
                                  
                                  // If name is same as street or house number, don't duplicate
                                  if (landmark.isNotEmpty && landmark != street) {
                                    addressParts.add(landmark);
                                  }
                                  
                                  if (street.isNotEmpty) {
                                    addressParts.add(street);
                                  }
                                  
                                  if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                                    addressParts.add(place.subLocality!);
                                  }

                                  addressController.text = addressParts.join(', ');
                                  cityController.text = place.locality ?? place.subAdministrativeArea ?? '';
                                  pincodeController.text = place.postalCode ?? '';
                                });
                              } else if (result['address'] != null) {
                                // Web fallback
                                setModalState(() {
                                  addressController.text = result['address'];
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text("Locate on Map", style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: labelController,
                      decoration: _inputDecoration('Address Label (e.g. Home, Office)'),
                      validator: (value) => value?.isEmpty == true ? 'Label is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: _inputDecoration('Full Name'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      ],
                      validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: _inputDecoration('Street Address / Landmark'),
                      validator: (value) => value?.isEmpty == true ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityController,
                            decoration: _inputDecoration('City'),
                            validator: (value) => value?.isEmpty == true ? 'City required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Pincode'),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Pincode required';
                              if (value.length != 6) return 'Enter 6 digits';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Phone Number'),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Phone required';
                        if (value.length != 10) return 'Enter 10 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Set as Default Address'),
                      value: isDefaultValue,
                      onChanged: (val) {
                        setModalState(() => isDefaultValue = val);
                      },
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          final label = labelController.text.trim();
                          final name = nameController.text.trim();
                          final street = addressController.text.trim();
                          final city = cityController.text.trim();
                          final pincode = pincodeController.text.trim();
                          final phone = phoneController.text.trim();

                          setModalState(() => isSaving = true);
                          
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

                          final Map<String, dynamic> result;
                          if (isEditing) {
                            result = await ApiService.updateAddress(
                              addressId: address!['id']!,
                              addressLabel: label,
                              fullName: name,
                              streetAddress: street,
                              city: city,
                              pincode: pincode,
                              phoneNumber: phone,
                              token: token,
                              isDefault: isDefaultValue,
                            );
                          } else {
                            result = await ApiService.saveAddress(
                              addressLabel: label,
                              fullName: name,
                              streetAddress: street,
                              city: city,
                              pincode: pincode,
                              phoneNumber: phone,
                              token: token,
                              isDefault: isDefaultValue,
                            );
                          }

                          if (result['success']) {
                            await _loadAddresses();
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEditing ? 'Address updated successfully!' : 'Address saved successfully!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            setModalState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Failed to save address'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
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
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(isEditing ? 'Update Address' : 'Save Address'),
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
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Shipping Addresses',
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved Addresses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_addresses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'No saved addresses found',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                  ...List.generate(_addresses.length, (index) {
                    return _buildAddressCard(_addresses[index], index, colorScheme);
                  }),
                  const SizedBox(height: 24),
                  _buildAddAddressButton(colorScheme),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressCard(Map<String, String> address, int index, ColorScheme colorScheme) {
    final bool isDefault = address['isDefault'] == 'true';
    return InkWell(
      onTap: widget.isSelectionMode ? () {
        Navigator.pop(context, address);
      } : null,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDefault ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.1),
            width: isDefault ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDefault ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    address['label']!,
                    style: TextStyle(
                      color: isDefault ? Colors.white : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!widget.isSelectionMode)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showAddressBottomSheet(index: index);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Address'),
                            content: const Text('Are you sure you want to delete this address?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await userManager.init();
                          final token = userManager.token;
                          final addressId = address['id'];

                          if (token != null && token.isNotEmpty && addressId != null && addressId.isNotEmpty) {
                            debugPrint('Deleting Address with ID: $addressId'); // Debug print
                            final result = await ApiService.deleteAddress(addressId, token);
                            
                            if (result['success']) {
                              setState(() => _addresses.removeAt(index));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Address deleted successfully!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              // Optional: Refresh from server to be 100% sure
                              _loadAddresses();
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Failed to delete address'),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid address ID or not logged in'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      } else if (value == 'default') {
                        await userManager.init();
                        final token = userManager.token;
                        final addressId = address['id'];

                        if (token != null && token.isNotEmpty && addressId != null && addressId.isNotEmpty) {
                          final result = await ApiService.setDefaultAddress(addressId, token);
                          if (result['success']) {
                            _loadAddresses();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Default address updated!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Failed to set default address'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (!isDefault) const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${address['address']!}, ${address['city']!} - ${address['pincode']!}',
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              address['phone']!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAddressButton(ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _showAddressBottomSheet(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 1.5, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Add New Address',
              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
