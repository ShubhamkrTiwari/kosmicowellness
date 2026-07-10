import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,

              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.support_agent, size: 60, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(height: 10),
                          Text(
                            'How can we help you today?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Quick Contact', colorScheme),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildContactGridItem(
                        Icons.phone_in_talk_outlined,
                        'Call Us',
                        'Mon-Sat\n9AM - 6PM',
                        colorScheme,
                      ),
                      _buildContactGridItem(
                        Icons.chat_bubble_outline_rounded,
                        'Live Chat',
                        'Instant\nSupport',
                        colorScheme,
                      ),
                      _buildContactGridItem(
                        Icons.mail_outline_rounded,
                        'Email Us',
                        'Response in\n24 hours',
                        colorScheme,
                      ),
                      _buildContactGridItem(
                        Icons.location_on_outlined,
                        'Visit Us',
                        'Wellness\nDistrict',
                        colorScheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Full Details', colorScheme),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoTile(
                  Icons.location_on_outlined,
                  'Main Office Address',
                  '123 Ayurveda Street, Wellness District,\nMumbai 400001, Maharashtra, India',
                  colorScheme,
                ),
                _buildInfoTile(
                  Icons.phone_outlined,
                  'Customer Support Lines',
                  '+91 98765 43210, +91 98765 43211',
                  colorScheme,
                ),
                _buildInfoTile(
                  Icons.email_outlined,
                  'Official Email Support',
                  'support@ayurvedashop.com\norders@ayurvedashop.com',
                  colorScheme,
                ),
                _buildInfoTile(
                  Icons.access_time_rounded,
                  'Operating Hours',
                  'Mon - Sat: 9:00 AM - 6:00 PM\nSunday: 10:00 AM - 4:00 PM',
                  colorScheme,
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: colorScheme.secondary,
        icon: const Icon(Icons.headset_mic_outlined, color: Colors.white),
        label: const Text('Start Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildContactGridItem(IconData icon, String title, String subtitle, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary.withOpacity(0.5), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary.withOpacity(0.6),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
