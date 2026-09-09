// ============================================================
// EduAcademy - خدمة الجلسة (من المسجّل دخوله حالياً)
// تُحفظ في SharedPreferences وتُنسخ إلى StorageService لتصفية البيانات
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class AuthService {
  static const _kEmail = 'session_email';
  static const _kName = 'session_name';
  static const _kRole = 'session_role';

  /// يقرأ الجلسة المحفوظة ويُحمّلها في StorageService؛ يعيد true إذا كان مسجّلاً
  static Future<bool> restore() async {
    final p = await SharedPreferences.getInstance();
    final email = p.getString(_kEmail);
    if (email == null) return false;
    StorageService.instance.setSession(
      email,
      p.getString(_kName) ?? 'المستخدم',
      (p.getInt(_kRole) ?? 0) == 1,
    );
    return true;
  }

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail) != null;
  }

  static Future<void> saveSession(
    String email,
    String name, {
    int role = 0,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kEmail, email);
    await p.setString(_kName, name);
    await p.setInt(_kRole, role);
    StorageService.instance.setSession(email, name, role == 1);
  }

  static Future<String> currentEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail) ?? '';
  }

  /// true إذا كان المستخدم الحالي معلماً
  static Future<bool> isTeacher() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(_kRole) ?? 0) == 1;
  }

  static Future<String> currentName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kName) ?? 'المستخدم';
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kEmail);
    await p.remove(_kName);
    await p.remove(_kRole);
    StorageService.instance.clearSession();
  }
}
