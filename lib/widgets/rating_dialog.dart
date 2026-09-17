import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../managers/user_manager.dart';

class RatingDialog extends StatefulWidget {
  final Map<String, dynamic> order;

  const RatingDialog({super.key, required this.order});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final List items = widget.order['full_order']?['items'] ?? 
                       widget.order['full_order']?['products'] ?? 
                       widget.order['full_order']?['orderItems'] ?? [];
    
    for (var item in items) {
      final String id = _getProductId(item);
      if (id.isNotEmpty) {
        _ratings[id] = 5.0; // Default 5 stars
        _controllers[id] = TextEditingController();
      }
    }
  }

  String _getProductId(dynamic item) {
    return (item['product']?['_id'] ?? 
            item['product']?['id'] ?? 
            item['productId'] ?? 
            item['_id'] ?? 
            item['id'] ?? '').toString();
  }

  String _getItemName(dynamic item) {
    return (item['name'] ?? 
            item['productName'] ?? 
            item['product']?['name'] ?? 
            'Wellness Product').toString();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReviews() async {
    final token = UserManager().token;
    if (token == null) return;

    setState(() => _isSubmitting = true);
    
    int successCount = 0;

    for (var entry in _ratings.entries) {
      final productId = entry.key;
      final rating = entry.value;
      final comment = _controllers[productId]?.text;

      final result = await ApiService.submitProductReview(
        productId: productId,
        rating: rating,
        comment: comment?.isNotEmpty == true ? comment : null,
        token: token,
      );

      if (result['success']) {
        successCount++;
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully submitted $successCount review(s)!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit reviews. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List items = widget.order['full_order']?['items'] ?? 
                       widget.order['full_order']?['products'] ?? 
                       widget.order['full_order']?['orderItems'] ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rate Your Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your experience with Kosmico Wellness',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final String id = _getProductId(item);
                  if (id.isEmpty) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getItemName(item),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (starIndex) {
                            final ratingValue = starIndex + 1.0;
                            return IconButton(
                              icon: Icon(
                                ratingValue <= (_ratings[id] ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                              ),
                              onPressed: () => setState(() => _ratings[id] = ratingValue),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controllers[id],
                          decoration: InputDecoration(
                            hintText: 'Add a comment (optional)',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            filled: true,
                            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReviews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Maybe Later', style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }
}
