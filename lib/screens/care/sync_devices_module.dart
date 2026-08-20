import 'package:flutter/material.dart';
import 'dart:async';
import '../../managers/care_manager.dart';

class SyncDevicesModule extends StatefulWidget {
  const SyncDevicesModule({super.key});

  @override
  State<SyncDevicesModule> createState() => _SyncDevicesModuleState();
}

class _SyncDevicesModuleState extends State<SyncDevicesModule> {
  bool _isScanning = false;
  String? _statusMessage;

  void _startScan() {
    setState(() {
      _isScanning = true;
      _statusMessage = "Searching for nearby Bluetooth/NFC devices...";
    });

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = "Found 2 new devices.";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final manager = CareManager();

    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(colorScheme),
            const SizedBox(height: 32),
            const Text('Your Devices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ...List.generate(manager.devices.length, (index) {
              final device = manager.devices[index];
              return _buildDeviceCard(device, index, colorScheme, manager);
            }),
            const SizedBox(height: 32),
            _buildNfcSyncSection(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.bluetooth_searching, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Seamless Hardware Sync',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Auto-sync your glucose and activity data from your favorite wearables.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isScanning ? null : _startScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
          ),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_statusMessage!, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device, int index, ColorScheme colorScheme, CareManager manager) {
    final bool connected = device['connected'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: connected ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: connected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            child: Icon(device['icon'], color: connected ? colorScheme.primary : Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(device['type'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: connected,
            onChanged: (val) => manager.toggleDeviceConnection(index),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNfcSyncSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.nfc, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('One-Tap NFC Sync', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Hold your phone near your CGM sensor to sync instantly.', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NFC Ready... Hold near sensor')));
            },
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}
