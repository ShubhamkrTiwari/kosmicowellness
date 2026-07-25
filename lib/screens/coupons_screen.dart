import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../managers/user_manager.dart';

class CouponsScreen extends StatefulWidget {
  final bool isSelectionMode;
  const CouponsScreen({super.key, this.isSelectionMode = false});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = UserManager().token;
      if (token == null) {
        setState(() => _errorMessage = 'Please login to view coupons');
        return;
      }

      final result = await ApiService.getCoupons(token);
      if (result['success'] && result['data'] != null) {
        setState(() {
          _coupons = List<Map<String, dynamic>>.from(result['data']);
        });
      } else {
        setState(() => _errorMessage = result['message'] ?? 'Failed to load coupons');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code "$code" copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Coupons', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchCoupons, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCoupons,
                  child: _coupons.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.confirmation_number_outlined, size: 80, color: colorScheme.primary.withValues(alpha: 0.1)),
                                const SizedBox(height: 16),
                                Text('No coupons available', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _coupons.length,
                          itemBuilder: (context, index) {
                            final coupon = _coupons[index];
                            return _buildCouponCard(coupon, colorScheme);
                          },
                        ),
                ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon, ColorScheme colorScheme) {
    final String code = coupon['code'] ?? '';
    final String title = coupon['title'] ?? 'OFFER';
    final String description = coupon['description'] ?? '';
    final String type = coupon['discountType'] ?? 'fixed';
    
    Color cardColor = colorScheme.primary;
    IconData iconData = Icons.eco_outlined;

    if (type == 'percentage') {
      cardColor = const Color(0xFF00833E);
      iconData = Icons.eco_outlined;
    } else if (type == 'fixed') {
      cardColor = const Color(0xFF1B264F);
      iconData = Icons.spa_outlined;
    } else if (type == 'free_gift') {
      cardColor = const Color(0xFF4CBB17);
      iconData = Icons.card_giftcard_outlined;
    }

    String expiryText = 'Unlimited';
    if (coupon['validUntil'] != null) {
      try {
        DateTime expiry = DateTime.parse(coupon['validUntil']);
        expiryText = 'Valid till ${DateFormat('dd MMM, yyyy').format(expiry)}';
      } catch (_) {}
    }

    return GestureDetector(
      onTap: widget.isSelectionMode ? () {
        Navigator.pop(context, coupon);
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: widget.isSelectionMode ? Border.all(color: cardColor.withValues(alpha: 0.3), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left Section (Color bar)
                Container(
                  width: 12,
                  color: cardColor,
                ),
                
                // Middle Section (Details)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(iconData, color: cardColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: cardColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                expiryText,
                                textAlign: TextAlign.end,
                                style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right Section (Copy Button / Select Button)
                InkWell(
                  onTap: widget.isSelectionMode 
                    ? () => Navigator.pop(context, coupon)
                    : () => _copyCode(code),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.05),
                      border: Border(left: BorderSide(color: colorScheme.outline.withValues(alpha: 0.05))),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isSelectionMode ? Icons.check_circle_outline : Icons.copy_rounded, 
                            color: cardColor, 
                            size: 20
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isSelectionMode ? 'USE' : 'COPY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cardColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
