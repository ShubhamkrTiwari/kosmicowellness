import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShippingAddressesScreen extends StatefulWidget {
  const ShippingAddressesScreen({super.key});

  @override
  State<ShippingAddressesScreen> createState() => _ShippingAddressesScreenState();
}

class _ShippingAddressesScreenState extends State<ShippingAddressesScreen> {
  final List<Map<String, String>> _addresses = [
    {
      'id': '1',
      'label': 'Home',
      'name': 'Shubham Tiwari',
      'address': '123 Ayurveda Street, Wellness District',
      'city': 'Mumbai',
      'pincode': '400001',
      'phone': '+91 98765 43210',
      'isDefault': 'true',
    },
    {
      'id': '2',
      'label': 'Office',
      'name': 'Shubham Tiwari',
      'address': 'Green Tower, 4th Floor, Tech Park',
      'city': 'Mumbai',
      'pincode': '400076',
      'phone': '+91 98765 43211',
      'isDefault': 'false',
    },
  ];

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
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 30,
          left: 24,
          right: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Address' : 'Add New Address',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: labelController,
                decoration: _inputDecoration('Address Label (e.g. Home, Office)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: _inputDecoration('Full Name'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: _inputDecoration('Street Address / Landmark'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityController,
                      decoration: _inputDecoration('City'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Pincode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Phone Number'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      final newData = {
                        'id': isEditing ? address!['id']! : DateTime.now().toString(),
                        'label': labelController.text,
                        'name': nameController.text,
                        'address': addressController.text,
                        'city': cityController.text,
                        'pincode': pincodeController.text,
                        'phone': phoneController.text,
                        'isDefault': isEditing ? address!['isDefault']! : 'false',
                      };
                      if (isEditing) {
                        _addresses[index] = newData;
                      } else {
                        _addresses.add(newData);
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isEditing ? 'Update Address' : 'Save Address'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saved Addresses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: isDefault ? colorScheme.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  address['label']!,
                  style: TextStyle(
                    color: isDefault ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddressBottomSheet(index: index);
                  } else if (value == 'delete') {
                    setState(() => _addresses.removeAt(index));
                  } else if (value == 'default') {
                    setState(() {
                      for (var a in _addresses) {
                        a['isDefault'] = 'false';
                      }
                      address['isDefault'] = 'true';
                    });
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
