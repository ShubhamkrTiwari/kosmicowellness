/// Shared phone number utilities for consistent country code (+91) handling
/// across the app: input prefill, API payloads, and display formatting.
class PhoneUtils {
  /// Default country code used throughout the app (India).
  static const String countryCode = '+91';

  /// Strips formatting and keeps only the last 10 digits.
  /// Used for input prefill and services that require bare 10-digit numbers
  /// (Razorpay prefill, Shiprocket billing_phone, tel: dialer URIs).
  static String digits(String phone) {
    final d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length > 10) return d.substring(d.length - 10);
    return d;
  }

  /// Normalizes a phone number to E.164 format (+91XXXXXXXXXX).
  /// Prepends the country code when only a 10-digit number is given;
  /// leaves other formats (emails, short codes) untouched.
  static String normalize(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty || trimmed.contains('@')) return trimmed;
    final d = digits(trimmed);
    if (d.length == 10) return '$countryCode$d';
    return trimmed;
  }

  /// Pretty display format: "+91 XXXXX XXXXX".
  /// Falls back to the raw value when the number is not a 10-digit one
  /// (placeholders like "Add phone number" pass through unchanged).
  static String display(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty || trimmed.contains('@')) return trimmed;
    final d = digits(trimmed);
    if (d.length == 10) {
      return '$countryCode ${d.substring(0, 5)} ${d.substring(5)}';
    }
    return trimmed;
  }

  /// Safe value for `tel:` URIs — keeps only digits and the leading +.
  static String telSafe(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}
