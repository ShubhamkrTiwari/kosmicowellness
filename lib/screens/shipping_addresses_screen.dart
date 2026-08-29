import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';

import '../managers/user_manager.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
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
                              setModalState(() {
                                String street = result['street']?.toString().trim() ?? '';
                                String city = result['city']?.toString().trim() ?? '';
                                String pincode = result['pincode']?.toString().trim() ?? '';
                                String fullAddr = result['address']?.toString().trim() ?? '';

                                // Fallback parser if city or pincode is empty
                                if ((city.isEmpty || pincode.isEmpty) && fullAddr.isNotEmpty) {
                                  final parsed = LocationService.parseAddressText(fullAddr);
                                  if (street.isEmpty) street = parsed['street'] ?? '';
                                  if (city.isEmpty) city = parsed['city'] ?? '';
                                  if (pincode.isEmpty) pincode = parsed['pincode'] ?? '';
                                }

                                // Placemark fallback
                                if (result['placemark'] != null) {
                                  Placemark place = result['placemark'];
                                  if (street.isEmpty) {
                                    String landmark = place.name ?? '';
                                    String pStreet = place.street ?? '';
                                    List<String> addressParts = [];
                                    if (landmark.isNotEmpty && landmark != pStreet) {
                                      addressParts.add(landmark);
                                    }
                                    if (pStreet.isNotEmpty) {
                                      addressParts.add(pStreet);
                                    }
                                    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
                                      addressParts.add(place.subLocality!);
                                    }
                                    street = addressParts.join(', ');
                                  }
                                  if (city.isEmpty) {
                                    city = place.locality ?? place.subAdministrativeArea ?? '';
                                  }
                                  if (pincode.isEmpty) {
                                    pincode = place.postalCode ?? '';
                                  }
                                }

                                if (street.isNotEmpty) {
                                  addressController.text = street;
                                } else if (fullAddr.isNotEmpty) {
                                  addressController.text = fullAddr;
                                }

                                if (city.isNotEmpty) {
                                  cityController.text = city;
                                }

                                if (pincode.isNotEmpty) {
                                  final pinMatch = RegExp(r'\b([1-9][0-9]{5})\b').firstMatch(pincode);
                                  pincodeController.text = pinMatch != null ? pinMatch.group(1)! : pincode;
                                }
                              });
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
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                            ],
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
    final String label = address['label'] ?? 'Home';
    final IconData labelIcon = label.toLowerCase().contains('home') 
        ? Icons.home_rounded 
        : label.toLowerCase().contains('office') 
            ? Icons.business_rounded 
            : Icons.location_on_rounded;

    return InkWell(
      onTap: widget.isSelectionMode ? () {
        Navigator.pop(context, address);
      } : null,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDefault ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.1),
            width: isDefault ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDefault 
                ? colorScheme.primary.withValues(alpha: 0.08) 
                : Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (isDefault)
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: colorScheme.primary.withValues(alpha: 0.05),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDefault 
                                ? colorScheme.primary 
                                : colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                labelIcon, 
                                size: 14, 
                                color: isDefault ? Colors.white : colorScheme.primary
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label.toUpperCase(),
                                style: TextStyle(
                                  color: isDefault ? Colors.white : colorScheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.isSelectionMode)
                          Material(
                            color: Colors.transparent,
                            child: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                      final result = await ApiService.deleteAddress(addressId, token);
                                      if (result['success']) {
                                        setState(() => _addresses.removeAt(index));
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Address deleted successfully!'), behavior: SnackBarBehavior.floating),
                                          );
                                        }
                                        _loadAddresses();
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
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 12), Text('Edit')])),
                                if (!isDefault) const PopupMenuItem(value: 'default', child: Row(children: [Icon(Icons.check_circle_outline, size: 18), SizedBox(width: 12), Text('Set as Default')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      address['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.map_outlined, size: 16, color: colorScheme.primary.withValues(alpha: 0.5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${address['address']!}, ${address['city']!} - ${address['pincode']!}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_iphone_rounded, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            address['phone']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
