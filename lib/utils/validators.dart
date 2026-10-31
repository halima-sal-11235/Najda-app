class Validators {
  static const String _req = 'هذا الحقل مطلوب';

  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? _req : null;

  static String? email(String? v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '')
          ? null
          : 'بريد إلكتروني غير صحيح';

  static String? password(String? v) =>
      (v == null || v.length < 6) ? 'كلمة السر 6 أحرف على الأقل' : null;

  static String? phone(String? v) =>
      RegExp(r'^0[5-7]\d{8}$').hasMatch(v ?? '')
          ? null
          : 'رقم غير صحيح (05 / 06 / 07 + 8 أرقام)';

  static String? vin(String? v) =>
      (v == null || v.length != 17) ? 'يجب أن يتكون من 17 رمزًا' : null;

  static String? plate(String? v) =>
      RegExp(r'^\d{3,6}-\d{3}-\d{2}$').hasMatch(v ?? '')
          ? null
          : 'الصيغة: xxxxx-yyy-zz';
}
