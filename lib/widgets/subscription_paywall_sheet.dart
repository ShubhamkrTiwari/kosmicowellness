import 'package:flutter/material.dart';
import '../managers/subscription_manager.dart';

/// Locked-content paywall: explains the trial exhaustion and collects the
/// one-time ₹99 subscription payment via Razorpay. Pops `true` on success.
class SubscriptionPaywallSheet extends StatefulWidget {
  final PremiumFeature feature;
  const SubscriptionPaywallSheet({super.key, required this.feature});

  @override
  State<SubscriptionPaywallSheet> createState() => _SubscriptionPaywallSheetState();
}

class _SubscriptionPaywallSheetState extends State<SubscriptionPaywallSheet> {
  bool _isProcessing = false;
  String? _errorText;

  Future<void> _payAndUnlock() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    final success = await SubscriptionManager().payAndUnlock();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Premium unlocked! Enjoy unlimited access to all features.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _errorText = 'Payment could not be completed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSubscribed = SubscriptionManager().isSubscribed;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, const Color(0xFF1B264F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                isSubscribed ? 'Premium Unlocked' : 'Content Locked',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                isSubscribed
                    ? 'You already have the Premium subscription. Tap continue to use ${widget.feature.label}.'
                    : 'You have used all ${SubscriptionManager.maxTrialUses} free trials of ${widget.feature.label}. Unlock everything with a monthly subscription.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
            ..._buildBenefitRow(colorScheme, 'Unlimited AI Plate Scans'),
            ..._buildBenefitRow(colorScheme, 'Unlimited Camera BP Scans'),
            ..._buildBenefitRow(colorScheme, 'Unlimited Community Posts'),
            ..._buildBenefitRow(colorScheme, 'Unlimited Smartwatch Connections'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Premium',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text('₹99 / month • Cancel anytime', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${SubscriptionManager.subscriptionPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '/mo',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSubscribed
                    ? () => Navigator.pop(context, true)
                    : (_isProcessing ? null : _payAndUnlock),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(isSubscribed ? Icons.play_circle_rounded : Icons.lock_open_rounded, size: 20),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    isSubscribed
                        ? 'Continue'
                        : (_isProcessing
                            ? 'Processing Payment...'
                            : 'Pay ₹${SubscriptionManager.subscriptionPrice.toStringAsFixed(0)} & Unlock Everything'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Secured by Razorpay • UPI, Cards, Wallets & NetBanking',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBenefitRow(ColorScheme colorScheme, String text) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
