import 'package:flutter/material.dart';
import 'payment_screen.dart';
import '../managers/payment_manager.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final bool isSelectionMode;
  const PaymentMethodsScreen({super.key, this.isSelectionMode = false});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch methods from backend when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PaymentManager().fetchPaymentMethods();
    });
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
        title: const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: PaymentManager(),
        builder: (context, _) {
          final manager = PaymentManager();
          final paymentMethods = manager.paymentMethods;
          final bool isLoading = manager.isLoading == true;
          
          if (isLoading && paymentMethods.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => manager.fetchPaymentMethods(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (manager.lastError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              manager.lastError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saved Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const PaymentScreen()),
                          ).then((_) {
                            // Refresh list when returning from add screen
                            PaymentManager().fetchPaymentMethods();
                          });
                        },
                        child: Text('+ Add New', style: TextStyle(color: colorScheme.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (paymentMethods.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(Icons.payment_outlined, size: 80, color: colorScheme.outline.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'No Payment Methods Added',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a bank account or UPI ID to get started',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(paymentMethods.length, (index) {
                      final method = paymentMethods[index];
                      if (method == null) return const SizedBox.shrink();
                      return _buildPremiumPaymentCard(method, index, colorScheme);
                    }),
                  const SizedBox(height: 32),
                  _buildSecurityInfo(colorScheme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumPaymentCard(Map<String, dynamic> method, int index, ColorScheme colorScheme) {
    final String type = (method['type'] ?? '').toString();
    final bool isBank = type == 'BANK_ACCOUNT';
    final Color cardColor = isBank ? const Color(0xFF1B264F) : const Color(0xFF00833E);
    final bool isDefault = method['isDefault'] == true;

    return InkWell(
      onTap: widget.isSelectionMode ? () {
        Navigator.pop(context, method);
      } : null,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withValues(alpha: 0.05)),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: CircleAvatar(radius: 80, backgroundColor: Colors.black.withValues(alpha: 0.05)),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isBank ? 'BANK' : 'UPI',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                              ),
                            ),
                            if (isDefault)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check_circle, color: Colors.white.withValues(alpha: 0.9), size: 20),
                              ),
                          ],
                        ),
                        if (!widget.isSelectionMode)
                          IconButton(
                            icon: const Icon(Icons.more_horiz, color: Colors.white),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                builder: (context) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.check_circle_outline), 
                                      title: const Text('Set as Default'), 
                                      onTap: () { 
                                        final newMethod = Map<String, dynamic>.from(method);
                                        newMethod['isDefault'] = true;
                                        PaymentManager().updatePaymentMethod(index, newMethod);
                                        Navigator.pop(context); 
                                      }
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.edit_outlined), 
                                      title: const Text('Edit Details'), 
                                      onTap: () { 
                                        Navigator.pop(context); 
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => PaymentScreen(editMethod: method),
                                          ),
                                        );
                                      }
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete_outline, color: Colors.red), 
                                      title: const Text('Remove Method', style: TextStyle(color: Colors.red)), 
                                      onTap: () { 
                                        PaymentManager().removePaymentMethod(index);
                                        Navigator.pop(context); 
                                      }
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      isBank 
                          ? (method['accountNumber']?.toString() ?? 'XXXX-XXXX-XXXX') 
                          : (method['upiId']?.toString() ?? method['upild'] ?? 'name@bank').toString(),
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: isBank ? 20 : 18, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: isBank ? 2 : 1
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isBank ? 'ACCOUNT HOLDER' : 'DISPLAY NAME', style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(
                                (isBank ? (method['accountHolderName'] ?? 'NAME NOT SET') : (method['displayName'] ?? method['name'] ?? 'NAME NOT SET')).toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isBank) ...[
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('IFSC', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(
                                method['ifscCode']?.toString() ?? '', 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
                              ),
                            ],
                          ),
                        ],
                      ],
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

  Widget _buildSecurityInfo(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: colorScheme.primary, size: 30),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text('Your payment details are encrypted and stored securely.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
