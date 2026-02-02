import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _nameKey = 'profile_name';
  static const String _emailKey = 'profile_email';
  static const String _phoneKey = 'profile_phone';

  // Default values
  static const String defaultName = 'MotoFile User';
  static const String defaultEmail = 'user@motofile.app';
  static const String defaultPhone = '+880 1234 567890';

  // Get profile data
  Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey) ?? defaultName,
      'email': prefs.getString(_emailKey) ?? defaultEmail,
      'phone': prefs.getString(_phoneKey) ?? defaultPhone,
    };
  }

  // Save profile data
  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_phoneKey, phone);
  }

  // Get individual fields
  Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? defaultName;
  }

  Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? defaultEmail;
  }

  Future<String> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey) ?? defaultPhone;
  }
}
