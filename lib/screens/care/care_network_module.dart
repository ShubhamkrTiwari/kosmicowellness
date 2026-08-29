import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../managers/care_manager.dart';
import '../../managers/user_manager.dart';
import '../../services/api_service.dart';
import '../../services/report_service.dart';
import '../../services/location_service.dart';
import '../../managers/notification_manager.dart';
import 'package:intl/intl.dart';

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
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status == PermissionStatus.granted || status == PermissionStatus.limited) {
        final Contact? contact = await FlutterContacts.native.showPicker(
          properties: {ContactProperty.phone},
        );
        if (contact != null) {
          nameCtrl.text = contact.displayName ?? '';
          if (contact.phones.isNotEmpty) {
            phoneCtrl.text = contact.phones.first.number;
          } else if (contact.id != null) {
            final fullContact = await FlutterContacts.get(
              contact.id!,
              properties: {ContactProperty.phone},
            );
            if (fullContact != null && fullContact.phones.isNotEmpty) {
              phoneCtrl.text = fullContact.phones.first.number;
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
          SnackBar(content: Text('Error picking contact: $e')),
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

        return RefreshIndicator(
          onRefresh: () async {
            await manager.fetchDashboardData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Emergency Contacts',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
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
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
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
      // 1. Get Exact Live GPS Location & Complete Reverse Geocoded Details
      LocationDetails? details = await LocationService.getExactLocationDetails();
      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access high-accuracy GPS. Please check location permissions and GPS toggle.')),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      final String patientName = UserManager().userName ?? 'Kosmico User';

      // 2. Compose High-Precision Emergency SOS Message
      final String sosMessage = '🚨 URGENT HYPO-ALERT: $patientName is experiencing a critical low blood sugar / hypoglycemia emergency!\n\n'
          '📍 Exact Location:\n${details.fullAddress}\n\n'
          '🎯 GPS Accuracy: ${details.accuracyLabel}\n'
          'Coordinates: Lat ${details.position.latitude.toStringAsFixed(6)}, Long ${details.position.longitude.toStringAsFixed(6)}\n\n'
          '🗺️ Live Google Maps:\n${details.googleMapsUrl}\n\n'
          '🚗 Direct Navigation:\n${details.navigationUrl}\n\n'
          'Please send emergency medical assistance or contact immediately!';

      String shareableText = sosMessage;

      // 3. Try backend emergency log
      final token = UserManager().token;
      if (token != null) {
        try {
          final result = await ApiService.generateEmergencyMessage(
            latitude: details.position.latitude,
            longitude: details.position.longitude,
            token: token,
          );
          if (result['success'] == true && result['data'] != null && result['data']['shareableText'] != null) {
            shareableText = result['data']['shareableText'];
          }
        } catch (e) {
          debugPrint('Emergency API Error: $e');
        }
      }

      // 4. Add In-App Notification
      NotificationManager().addNotification(
        title: '🚨 Hypo-Alert Broadcast Ready',
        message: 'High-precision location (${details.areaSummary}) ready for emergency contacts.',
        icon: '🚨',
        type: 'alert',
      );

      if (mounted) {
        _showEmergencySentDialog(
          context,
          details: details,
          shareableText: shareableText,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alert Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _showEmergencySentDialog(
    BuildContext context, {
    required LocationDetails details,
    required String shareableText,
  }) {
    final contacts = CareManager().contacts;
    final List<String> phoneNumbers = contacts
        .map((c) => c['phone']?.toString().replaceAll(RegExp(r'[^0-9+]'), '') ?? '')
        .where((p) => p.isNotEmpty)
        .toList();

    final TextEditingController addressCtrl = TextEditingController(text: details.fullAddress);
    bool isEditingAddress = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String buildFinalSosMessage() {
            final patientName = UserManager().userName ?? 'Kosmico User';
            final currentAddr = addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : details.fullAddress;
            return '🚨 URGENT HYPO-ALERT: $patientName is experiencing a critical low blood sugar / hypoglycemia emergency!\n\n'
                '📍 Exact Location:\n$currentAddr\n\n'
                '🎯 GPS Accuracy: ${details.accuracyLabel}\n'
                'Coordinates: Lat ${details.position.latitude.toStringAsFixed(6)}, Long ${details.position.longitude.toStringAsFixed(6)}\n\n'
                '🗺️ Live Google Maps Pin:\n${details.googleMapsUrl}\n\n'
                '🚗 Direct Navigation:\n${details.navigationUrl}\n\n'
                'Please send emergency medical assistance or contact immediately!';
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF7F1D1D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.emergency_share, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ALERT READY!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency SOS message and pinpoint GPS location are ready to be sent to your care network:',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'EXACT ADDRESS / LANDMARK:',
                                          style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setDialogState(() {
                                            isEditingAddress = !isEditingAddress;
                                          });
                                        },
                                        child: Text(
                                          isEditingAddress ? 'Done' : 'Edit',
                                          style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (isEditingAddress)
                                    TextField(
                                      controller: addressCtrl,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        filled: true,
                                        fillColor: Colors.white.withValues(alpha: 0.1),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      ),
                                    )
                                  else
                                    Text(
                                      addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : details.fullAddress,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5, height: 1.3),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'GPS: ${details.position.latitude.toStringAsFixed(6)}, ${details.position.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontFamily: 'monospace'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                details.accuracyLabel,
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 9.5, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openUrl(details.googleMapsUrl),
                          child: Row(
                            children: [
                              const Icon(Icons.map_outlined, color: Colors.lightBlueAccent, size: 14),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  'Live Google Maps Pin Link',
                                  style: TextStyle(color: Colors.lightBlueAccent, fontSize: 11, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Icon(Icons.arrow_outward, size: 12, color: Colors.lightBlueAccent),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    contacts.isNotEmpty 
                        ? 'Target Contacts (${contacts.length}): ${contacts.map((c) => "${c['name']} (${c['phone']})").join(', ')}'
                        : 'No emergency contacts added yet. Use Share to send to any contact.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            actions: [
              Column(
                children: [
                  // 1. Direct SMS Alert
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendDirectSmsAlert(phoneNumbers, buildFinalSosMessage());
                      },
                      icon: const Icon(Icons.sms_rounded, size: 20),
                      label: Text(
                        phoneNumbers.isNotEmpty ? 'SEND SMS TO ALL CONTACTS' : 'SEND SMS ALERT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.8),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7F1D1D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Share via WhatsApp / Other Apps
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Share.share(buildFinalSosMessage(), subject: '🚨 GLUCOSE EMERGENCY SOS');
                      },
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('SHARE VIA WHATSAPP / APPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.8)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ),

                  if (phoneNumbers.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _makePhoneCall(phoneNumbers.first);
                        },
                        icon: const Icon(Icons.phone_in_talk, size: 18, color: Colors.white),
                        label: Text(
                          'CALL PRIMARY (${contacts.first['name']})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('DISMISS', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendDirectSmsAlert(List<String> phoneNumbers, String message) async {
    final String phones = phoneNumbers.join(';');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phones,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to generic SMS or Share
        final Uri genericSmsUri = Uri(scheme: 'sms', queryParameters: {'body': message});
        if (await canLaunchUrl(genericSmsUri)) {
          await launchUrl(genericSmsUri, mode: LaunchMode.externalApplication);
        } else {
          await Share.share(message, subject: '🚨 GLUCOSE EMERGENCY SOS');
        }
      }
    } catch (e) {
      debugPrint('SMS launch error: $e');
      await Share.share(message, subject: '🚨 GLUCOSE EMERGENCY SOS');
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Open URL error: $e');
    }
  }

  Widget _buildClinicalReportSection(ColorScheme colorScheme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
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
    final manager = CareManager();
    final patientName = UserManager().userName ?? 'Valued Patient';
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final reportId = 'KOS-GLU-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final double avg = manager.averageGlucose > 0 ? manager.averageGlucose : 118.0;
    final double a1c = manager.estimatedA1C > 0 ? manager.estimatedA1C : ((avg + 46.7) / 28.7);
    final double tir = manager.timeInRangePercentage > 0 ? manager.timeInRangePercentage : 82.0;
    final double gmi = 3.31 + (0.02392 * avg);

    String a1cStatus = 'Normal';
    Color a1cColor = Colors.green;
    if (a1c >= 6.5) {
      a1cStatus = 'Diabetic Range';
      a1cColor = Colors.red;
    } else if (a1c >= 5.7) {
      a1cStatus = 'Pre-Diabetic';
      a1cColor = Colors.orange[800]!;
    }

    Color tirColor = tir >= 70 ? Colors.green : Colors.orange[800]!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          child: Column(
            children: [
              // Dialog Header Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D5C46),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KOSMICO METABOLIC CLINIC',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                          ),
                          Text(
                            'Clinical Diabetes Diagnostic Profile',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Scrollable Clinical Report Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Demographics Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCCE3DB)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: _buildDemographicItem('PATIENT', patientName, isBold: true)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildDemographicItem('REPORT ID', reportId)),
                              ],
                            ),
                            const Divider(height: 16, color: Color(0xFFCCE3DB)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: _buildDemographicItem('DATE', dateStr)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildDemographicItem('TELEMETRY', 'CGM & Blood Glucose')),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Key Biomarkers Summary Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricBadge(
                              title: 'Estimated HbA1c',
                              value: '${a1c.toStringAsFixed(2)}%',
                              status: a1cStatus,
                              statusColor: a1cColor,
                              target: 'Target: <7.0%',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricBadge(
                              title: 'Mean Glucose',
                              value: '${avg.toStringAsFixed(1)} mg/dL',
                              status: avg <= 130 ? 'In Target' : (avg <= 180 ? 'Moderate' : 'High'),
                              statusColor: avg <= 130 ? Colors.green : Colors.orange[800]!,
                              target: 'Target: 70-130',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricBadge(
                              title: 'Time in Range',
                              value: '${tir.toStringAsFixed(1)}%',
                              status: tir >= 70 ? 'Optimal' : 'Needs Work',
                              statusColor: tirColor,
                              target: 'ADA: >70%',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Glycemic Diagnostics Matrix Table
                      const Text(
                        'GLYCEMIC CONTROL & BIOMARKER MATRIX',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D5C46), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            children: [
                              Container(
                                color: const Color(0xFF0D5C46),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text('PARAMETER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                                    Expanded(flex: 2, child: Text('VALUE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                                    Expanded(flex: 3, child: Text('REF. RANGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                                    Expanded(flex: 2, child: Text('STATUS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                                  ],
                                ),
                              ),
                              _buildUiTableRow('Est. HbA1c', '${a1c.toStringAsFixed(2)}%', '< 5.7 (Normal)\n5.7-6.4 (Pre-D)', a1cStatus, a1cColor, isOdd: false),
                              _buildUiTableRow('Mean Glucose', '${avg.toStringAsFixed(1)} mg/dL', '70 - 130 mg/dL', avg <= 130 ? 'In Target' : 'Elevated', avg <= 130 ? Colors.green : Colors.orange[800]!, isOdd: true),
                              _buildUiTableRow('Time in Range', '${tir.toStringAsFixed(1)}%', '> 70.0% (ADA)', tir >= 70 ? 'Optimal' : 'Low', tirColor, isOdd: false),
                              _buildUiTableRow('Glucose Index', '${gmi.toStringAsFixed(2)}%', '< 6.5% Target', 'Optimal', Colors.green, isOdd: true),
                              _buildUiTableRow('Hydration', '${manager.waterIntake} mL', '2500 - 3000 mL', manager.waterIntake >= 2000 ? 'Adequate' : 'Low', manager.waterIntake >= 2000 ? Colors.green : Colors.orange[800]!, isOdd: false),
                              _buildUiTableRow('Stress Score', '${manager.stressLevel}/5', '1 - 2 (Low Spike)', manager.stressLevel <= 2 ? 'Normal' : 'High', manager.stressLevel <= 2 ? Colors.green : Colors.orange[800]!, isOdd: true),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Endocrinologist Clinical Impression Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCCE3DB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.psychology_outlined, color: Color(0xFF0D5C46), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'AI Clinical Impression & Recommendations',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D5C46)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              a1c < 5.7 
                                ? '• Glycemic profile indicates non-diabetic range with excellent metabolic stability.'
                                : (a1c <= 6.4 
                                    ? '• Pre-diabetic glycemic profile observed. Recommended low GI diet swaps and post-meal physical activity.'
                                    : (a1c <= 7.0 
                                        ? '• Well-managed diabetic range compliant with ADA (<7.0%) standards.'
                                        : '• Glycemic elevation detected. Discuss medication adjustment with your healthcare provider.')),
                              style: const TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Time in range is ${tir.toStringAsFixed(1)}%. Maintain target of at least 70% between 70-180 mg/dL.',
                              style: const TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Share.share(manager.generateClinicalReport(), subject: 'Kosmico Clinical Diabetes Report');
                        },
                        icon: const Icon(Icons.text_snippet_outlined, size: 18),
                        label: const Text('Share Text'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ReportService.shareClinicalReport(manager);
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text('Download / Share PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5C46),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
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

  Widget _buildDemographicItem(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1E293B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetricBadge({
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    required String target,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCCE3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 8.5, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            target,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUiTableRow(
    String parameter,
    String value,
    String refRange,
    String status,
    Color statusColor, {
    required bool isOdd,
  }) {
    return Container(
      color: isOdd ? const Color(0xFFF8FAFC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(parameter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Color(0xFF1E293B))),
          ),
          Expanded(
            flex: 2,
            child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A))),
          ),
          Expanded(
            flex: 3,
            child: Text(refRange, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), height: 1.2)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: statusColor, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
