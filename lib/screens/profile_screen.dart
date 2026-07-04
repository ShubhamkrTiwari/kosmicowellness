import 'package:flutter/material.dart';
import 'help_center_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.1),
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'JS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shubham Tiwari',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                        Text(
                          'shubham.tiwari@example.com',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.secondary.withOpacity(0.5)),
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
                    onPressed: () {},
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
                  _buildStatItem('Wishlist', '5', Icons.favorite_border, colorScheme),
                  _buildStatItem('Coupons', '3', Icons.confirmation_number_outlined, colorScheme),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Settings Section
            _buildSectionHeader('Account Settings', colorScheme),
            _buildMenuItem(Icons.shopping_bag_outlined, 'My Orders', 'Track and manage your orders', colorScheme),
            _buildMenuItem(Icons.location_on_outlined, 'Shipping Addresses', 'Manage your delivery locations', colorScheme),
            _buildMenuItem(Icons.payment_outlined, 'Payment Methods', 'Saved cards and UPI', colorScheme),
            
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
        border: Border.all(color: colorScheme.primary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.03),
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
            color: colorScheme.primary.withOpacity(0.7),
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
            color: colorScheme.primary.withOpacity(0.05),
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
