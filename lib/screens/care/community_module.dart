import 'package:flutter/material.dart';

class CommunityModule extends StatelessWidget {
  const CommunityModule({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostInput(colorScheme),
          const SizedBox(height: 24),
          const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          _buildPostCard(
            'Rohan M.', 
            '2 hours ago', 
            'Just tried the Almond Flour Roti from the Recipes tab! It actually tasted great and my post-meal glucose was only 132. Progress! 🎉', 
            'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=400&q=80',
            12, 
            colorScheme
          ),
          _buildPostCard(
            'Sneha K.', 
            '5 hours ago', 
            'Managed to walk 10k steps today. Feeling tired but seeing more stable trends in the morning. Anyone has tips for Dawn Phenomenon?', 
            null,
            24, 
            colorScheme
          ),
          _buildPostCard(
            'Rahul T.', 
            'Yesterday', 
            'Finally reached my 30-day goal of keeping A1C below 7! Thanks to the reminders in this app. 📈', 
            null,
            45, 
            colorScheme
          ),
        ],
      ),
    );
  }

  Widget _buildPostInput(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
          const SizedBox(width: 12),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Share a recipe or milestone...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.send, color: colorScheme.primary, size: 20)),
        ],
      ),
    );
  }

  Widget _buildPostCard(String user, String time, String content, String? image, int likes, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: colorScheme.primary.withValues(alpha: 0.1), child: Text(user[0], style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.5)),
          if (image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(image, height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(likes.toString(), style: TextStyle(color: colorScheme.primary, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Comment', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
