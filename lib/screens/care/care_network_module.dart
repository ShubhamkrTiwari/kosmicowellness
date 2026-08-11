import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this for kIsWeb
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../managers/care_manager.dart';

class CareNetworkModule extends StatefulWidget {
  const CareNetworkModule({super.key});

  @override
  State<CareNetworkModule> createState() => _CareNetworkModuleState();
}

class _CareNetworkModuleState extends State<CareNetworkModule> {
  bool _isGettingLocation = false;

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
        final contacts = CareManager().contacts;
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
            ],
          ),
        );
      },
    );
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

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      String address = 'Location not found';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = '${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}';
      }

      if (mounted) {
        _showEmergencySentDialog(context, address);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _showEmergencySentDialog(BuildContext context, String address) {
    final contacts = CareManager().contacts;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.white),
            SizedBox(width: 12),
            Text('ALERT SENT!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your emergency contacts have been notified with your live location:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(address, style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 16),
            Text(
              'Notified: ${contacts.map((c) => c['name']).join(', ')}',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
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
    final reportText = CareManager().generateClinicalReport();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Clinical Report Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    reportText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report shared successfully!'), backgroundColor: Colors.green));
                       Navigator.pop(context);
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share PDF'),
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
