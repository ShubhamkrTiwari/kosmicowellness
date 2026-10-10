import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../services/razorpay_service.dart';
import '../widgets/subscription_paywall_sheet.dart';


/// Every user gets [SubscriptionManager.maxTrialUses] free uses per feature,
/// after which the feature stays locked until the subscription is purchased.
enum PremiumFeature {
  plateScan('plate_scan', 'AI Plate Scan', 'Scan your meal plate with AI vision'),
  bpScan('bp_scan', 'BP Scan', 'Camera-based PPG blood pressure measurement'),
  communityPost('community_post', 'Community Post', 'Share posts with the Care Community'),
  smartwatchConnect('smartwatch_connect', 'Smartwatch Connect', 'Pair & stream vitals from smartwatches');

  const PremiumFeature(this.id, this.label, this.description);
  final String id;
  final String label;
  final String description;
}

class SubscriptionManager extends ChangeNotifier {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  /// Monthly subscription price in INR (dynamically fetched from API)
  static double _subscriptionPrice = 149.0;
  static double get subscriptionPrice => _subscriptionPrice;

  /// Free trials allowed per premium feature before locking
  static const int maxTrialUses = 2;

  SharedPreferences? _prefs;
  String? _userId;
  bool _isSubscribed = false;
  bool _paywallShowing = false;
  final Map<PremiumFeature, int> _remainingTrials = {};

  bool get isSubscribed => _isSubscribed;

  // Subscription state is stored per user id so it survives restarts and is
  // restored automatically when the same user logs in again.
  String get _uid => _userId ?? 'guest';
  String _subscribedKey() => 'subscribed_$_uid';
  String _expiryKey() => 'sub_expiry_$_uid';
  String _trialKey(PremiumFeature f) => 'trial_${f.id}_$_uid';

  int get daysLeft {
    if (!_isSubscribed || _prefs == null) return 0;
    final expiryStr = _prefs!.getString(_expiryKey());
    if (expiryStr == null) return 30;
    final expiryDate = DateTime.tryParse(expiryStr);
    if (expiryDate == null) return 30;
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _userId = _prefs!.getString('user_id');
    await _loadState();
    await _fetchSubscriptionAmount();
  }

  Future<void> _fetchSubscriptionAmount() async {
    try {
      final res = await ApiService.getSubscriptionAmount();
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final amount = data is Map ? (data['subscriptionAmount'] ?? data['amount'] ?? 149) : data;
        final parsed = double.tryParse(amount.toString()) ?? 149.0;
        if (parsed > 0) {
          _subscriptionPrice = parsed;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching subscription amount: $e');
    }
  }

  /// Reload subscription + trial counters for the given user id.
  /// Called on login (saveUser) and logout.
  Future<void> loadForUser(String? userId) async {
    _prefs ??= await SharedPreferences.getInstance();
    _userId = userId;
    await _loadState();
  }

  Future<void> _loadState() async {
    final prefs = _prefs;
    if (prefs == null) return;
    _isSubscribed = prefs.getBool(_subscribedKey()) ?? false;

    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      try {
        final statusResult = await ApiService.getSubscriptionStatus(token);
        if (statusResult['success'] == true && statusResult['data'] != null) {
          final data = statusResult['data'];
          syncFromProfile(data is Map ? Map<String, dynamic>.from(data) : null);
        }
      } catch (e) {
        debugPrint('Error fetching subscription status from server: $e');
      }
    }

    if (_isSubscribed) {
      final expiryStr = prefs.getString(_expiryKey());
      if (expiryStr != null) {
        final expiryDate = DateTime.tryParse(expiryStr);
        if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
          _isSubscribed = false;
          await prefs.setBool(_subscribedKey(), false);
        }
      }
    }

    for (final f in PremiumFeature.values) {
      _remainingTrials[f] ??= prefs.getInt(_trialKey(f)) ?? maxTrialUses;
    }
    notifyListeners();
  }

  int remainingTrials(PremiumFeature feature) {
    if (_isSubscribed) return 1 << 30; // unlimited once subscribed
    return (_remainingTrials[feature] ?? maxTrialUses).clamp(0, maxTrialUses);
  }

  bool hasAccess(PremiumFeature feature) {
    return _isSubscribed || remainingTrials(feature) > 0;
  }

  /// Registers one paid use of a feature (no-op when subscribed).
  Future<void> recordUse(PremiumFeature feature) async {
    if (_isSubscribed || _prefs == null) return;
    final token = _prefs!.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      try {
        final result = await ApiService.consumeTrialFeature(feature: feature.id, token: token);
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'];
          if (data['remaining'] != null) {
            final int remaining = (data['remaining'] is int) ? data['remaining'] : int.tryParse(data['remaining'].toString()) ?? 0;
            _remainingTrials[feature] = remaining.clamp(0, maxTrialUses);
            await _prefs!.setInt(_trialKey(feature), _remainingTrials[feature]!);
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        debugPrint('Error consuming trial feature on server: $e');
      }
    }
    // Fallback local
    final current = _remainingTrials[feature] ?? maxTrialUses;
    final newRemaining = (current - 1).clamp(0, maxTrialUses);
    _remainingTrials[feature] = newRemaining;
    await _prefs!.setInt(_trialKey(feature), newRemaining);
    notifyListeners();
  }

  /// Non-consuming pre-check: returns true if the action may start.
  /// When trials are exhausted the ₹99 paywall is shown and true is
  /// returned only after a successful purchase.
  Future<bool> ensureAccess(BuildContext context, PremiumFeature feature) async {
    if (_isSubscribed) return true;
    if (remainingTrials(feature) > 0) return true;
    return await showPaywall(context, feature);
  }

  /// Check + consume one trial use in a single step. Use this when the
  /// feature "use" is exactly the action being gated (e.g. a BP measurement).
  Future<bool> requestAccess(BuildContext context, PremiumFeature feature) async {
    if (_isSubscribed) return true;
    if (remainingTrials(feature) > 0) {
      await recordUse(feature);
      return true;
    }
    return await showPaywall(context, feature);
  }

  /// Shows the locked-content paywall. Returns true if the user is
  /// subscribed after the sheet closes (i.e. they paid ₹99).
  Future<bool> showPaywall(BuildContext context, PremiumFeature feature) async {
    if (_paywallShowing) return false;
    _paywallShowing = true;
    bool purchased = false;
    try {
      purchased = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SubscriptionPaywallSheet(feature: feature),
      ) ?? false;
    } finally {
      _paywallShowing = false;
    }
    return _isSubscribed || purchased;
  }

  /// Opens Razorpay checkout for ₹99. On success the subscription is saved
  /// against the current user id, so it stays unlocked on next login.
  ///
  /// Flow (matches the backend contract):
  /// 1. POST /api/subscription/create-order → server fixes price & returns order id
  /// 2. Razorpay checkout with that order id
  /// 3. POST /api/subscription/verify → backend flags the user id as subscribed
  /// If the backend routes aren't deployed yet, it gracefully falls back to a
  /// direct checkout + local-only flag (still per user id on this device).
  Future<bool> payAndUnlock() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final completer = Completer<bool>();

    // 1. Server-side order (optional — falls back to direct checkout)
    String? serverOrderId;
    if (token != null && token.isNotEmpty) {
      final orderResult = await ApiService.createSubscriptionOrder(token: token);
      if (orderResult['success'] == true && orderResult['data'] != null) {
        final dynamic d = orderResult['data'];
        if (d is Map) {
          serverOrderId = (d['razorpay_order_id'] ??
                  d['orderId'] ??
                  d['order_id'] ??
                  d['id'] ??
                  (d['order'] is Map
                      ? (d['order']['razorpay_order_id'] ?? d['order']['orderId'] ?? d['order']['id'])
                      : null))
              ?.toString();
        }
      }
    }

    // 2. Checkout + verification
    final service = RazorpayService(
      onSuccess: (PaymentSuccessResponse resp) async {
        String? paymentId = resp.paymentId;

        // Verify server-side when we have an order id + signature (direct
        // checkout may return no signature — then we keep the local flag only)
        if (token != null &&
            token.isNotEmpty &&
            serverOrderId != null &&
            resp.orderId != null &&
            resp.signature != null &&
            paymentId != null) {
          final verifyResult = await ApiService.verifySubscriptionPayment(
            paymentId: paymentId,
            orderId: resp.orderId!,
            signature: resp.signature!,
            token: token,
          );
          if (verifyResult['success'] != true) {
            debugPrint('Subscription verify failed: ${verifyResult['message']}');
            // Payment genuinely succeeded in Razorpay, so still unlock for the
            // user; backend catches up via the payment.captured webhook.
          }
        }

        await _markSubscribed(paymentId: paymentId);
        if (!completer.isCompleted) completer.complete(true);
      },
      onFailure: (PaymentFailureResponse resp) {
        debugPrint('Subscription payment failed: ${resp.message} (code ${resp.code})');
        if (!completer.isCompleted) completer.complete(false);
      },
      onExternalWallet: (ExternalWalletResponse resp) {
        // Wallet selection cannot be completed client-side for subscriptions.
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    service.openCheckout(
      amount: subscriptionPrice,
      contact: (prefs.getString('user_phone') ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
      email: prefs.getString('user_email') ?? '',
      description: 'Kosmico Wellness Monthly Subscription',
      orderId: serverOrderId,
      items: const [
        {'name': 'Premium Subscription (Monthly)', 'qty': 1},
      ],
    );

    final result = await completer.future;
    service.dispose();
    return result;
  }

  Future<void> _markSubscribed({String? paymentId, String? expiryDateStr}) async {
    _isSubscribed = true;
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setBool(_subscribedKey(), true);
      final expiryDate = expiryDateStr != null 
          ? (DateTime.tryParse(expiryDateStr) ?? DateTime.now().add(const Duration(days: 30)))
          : DateTime.now().add(const Duration(days: 30));
      await prefs.setString(_expiryKey(), expiryDate.toIso8601String());

      if (paymentId != null && paymentId.isNotEmpty) {
        await prefs.setString('sub_payment_$_uid', paymentId);
      }
    }
    notifyListeners();
  }

  /// If the backend user payload ever starts carrying a subscription flag
  /// (isSubscribed / premium), honour it so the state follows the user id
  /// across devices without a re-purchase.
  void syncFromProfile(Map<String, dynamic>? user) {
    if (user == null || _prefs == null) return;
    
    // 1. Subscription status (check all casing variants)
    final value = user['isSubscribed'] ?? 
                  user['issubscribed'] ?? 
                  user['is_subscribed'] ?? 
                  user['subscription'] ?? 
                  user['premium'] ?? 
                  user['subscribed'];
    final bool flag = value == true || value?.toString().toLowerCase() == 'true';
    _isSubscribed = flag;
    _prefs!.setBool(_subscribedKey(), _isSubscribed);

    if (_isSubscribed) {
      final daysLeftVal = user['subscriptionDaysLeft'] ?? 
                          user['subscription_days_left'] ?? 
                          user['daysLeft'] ?? 
                          user['days_left'] ?? 
                          user['validity'];
      if (daysLeftVal != null) {
        final days = int.tryParse(daysLeftVal.toString()) ?? 30;
        final expiryDate = DateTime.now().add(Duration(days: days));
        _prefs!.setString(_expiryKey(), expiryDate.toIso8601String());
      } else {
        final expiry = user['subscriptionExpiry'] ?? user['subscription_expiry'] ?? user['expiryDate'];
        if (expiry != null) {
          _markSubscribed(expiryDateStr: expiry.toString());
        } else {
          _markSubscribed();
        }
      }
    }

    // 2. Trial usage / remaining trials
    final trialData = user['trialUsage'] ?? 
                      user['trial_usage'] ?? 
                      user['trials'] ?? 
                      user['trial'];
    if (trialData is Map) {
      for (final f in PremiumFeature.values) {
        final val = trialData[f.id] ?? trialData[f.id.replaceAll('_', '')] ?? trialData[f.name];
        if (val != null) {
          final int rawVal = int.tryParse(val.toString()) ?? 0;
          int remaining;
          if (user.containsKey('trialUsage') || user.containsKey('trial_usage')) {
            remaining = (maxTrialUses - rawVal).clamp(0, maxTrialUses);
          } else {
            remaining = rawVal.clamp(0, maxTrialUses);
          }
          _remainingTrials[f] = remaining;
          _prefs!.setInt(_trialKey(f), remaining);
        }
      }
    }
    notifyListeners();
  }
}
