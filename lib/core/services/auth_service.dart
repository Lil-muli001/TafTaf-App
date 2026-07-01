import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:taftaf/core/constants/api_keys.dart';
import 'package:taftaf/core/models/user_model.dart';

class AuthService {
  static const _usersKey   = 'taftaf_users';
  static const _sessionKey = 'taftaf_session';
  static const _otpKey     = 'taftaf_reset_otp';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel> login(String identifier, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) throw Exception('Invalid username or password');
    final allUsers = (jsonDecode(usersJson) as List).cast<Map<String, dynamic>>();

    final identifierLower = identifier.toLowerCase();
    final userJson = allUsers.firstWhere(
      (u) =>
          (u['username'].toString().toLowerCase() == identifierLower ||
              u['email'].toString().toLowerCase() == identifierLower) &&
          u['password'] == password,
      orElse: () => {},
    );

    if (userJson.isEmpty) throw Exception('Invalid username or password');

    _currentUser = UserModel.fromJson(userJson);
    await prefs.setString(_sessionKey, jsonEncode(userJson));
    return _currentUser!;
  }

  Future<UserModel> signup(
    String username,
    String email,
    String phone,
    UserRole role,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    List<Map<String, dynamic>> storedUsers = [];
    List<Map<String, dynamic>> allUsers = [];
    if (usersJson != null) {
      storedUsers = (jsonDecode(usersJson) as List).cast<Map<String, dynamic>>();
      allUsers = storedUsers;
    }

    final usernameLower = username.toLowerCase();
    final emailLower = email.toLowerCase();
    final exists = allUsers.any(
      (u) =>
          u['username'].toString().toLowerCase() == usernameLower ||
          u['email'].toString().toLowerCase() == emailLower,
    );
    if (exists) throw Exception('Username or email already taken');

    final newUser = UserModel(
      id: const Uuid().v4(),
      username: username,
      email: email,
      phone: phone,
      role: role,
      createdAt: DateTime.now(),
    );

    final userJson = {...newUser.toJson(), 'password': password};
    storedUsers.add(userJson);
    await prefs.setString(_usersKey, jsonEncode(storedUsers));

    _currentUser = newUser;
    await prefs.setString(_sessionKey, jsonEncode(userJson));
    return newUser;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<UserModel?> getPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson == null) return null;

    try {
      _currentUser = UserModel.fromJson(jsonDecode(sessionJson) as Map<String, dynamic>);
      return _currentUser;
    } catch (_) {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) throw Exception('Not logged in');
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) throw Exception('Unable to update password. Please contact support.');

    final users = (jsonDecode(usersJson) as List).cast<Map<String, dynamic>>();
    final idx = users.indexWhere((u) => u['id'] == _currentUser!.id);
    if (idx == -1) throw Exception('Unable to update password. Please contact support.');
    if (users[idx]['password'] != currentPassword) throw Exception('Current password is incorrect');

    users[idx]['password'] = newPassword;
    await prefs.setString(_usersKey, jsonEncode(users));

    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null) {
      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      sessionMap['password'] = newPassword;
      await prefs.setString(_sessionKey, jsonEncode(sessionMap));
    }
  }

  // ── Password reset via OTP email ─────────────────────────────────────────

  Future<void> sendPasswordResetOtp(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) throw Exception('No account found with that email address.');

    final users = (jsonDecode(usersJson) as List).cast<Map<String, dynamic>>();
    final emailLower = email.trim().toLowerCase();
    final userExists = users.any((u) => u['email'].toString().toLowerCase() == emailLower);
    if (!userExists) throw Exception('No account found with that email address.');

    final otp = (100000 + Random().nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    await prefs.setString(_otpKey, jsonEncode({
      'email': emailLower,
      'otp': otp,
      'expiresAt': expiresAt.toIso8601String(),
    }));

    await _sendOtpEmail(email: email.trim(), otp: otp);
  }

  Future<void> _sendOtpEmail({required String email, required String otp}) async {
    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id':   ApiKeys.emailjsServiceId,
        'template_id':  ApiKeys.emailjsTemplateId,
        'user_id':      ApiKeys.emailjsPublicKey,
        'accessToken':  ApiKeys.emailjsPrivateKey,
        'template_params': {
          'to_email':   email,
          'reset_code': otp,
          'app_name':   'TafTaf',
        },
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Email service error (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final otpJson = prefs.getString(_otpKey);
    if (otpJson == null) throw Exception('No reset request found. Please request a new code.');

    final data = jsonDecode(otpJson) as Map<String, dynamic>;
    final storedEmail  = data['email'].toString();
    final storedOtp    = data['otp'].toString();
    final expiresAt    = DateTime.parse(data['expiresAt'].toString());

    if (storedEmail != email.trim().toLowerCase()) {
      throw Exception('Invalid request. Please request a new reset code.');
    }
    if (DateTime.now().isAfter(expiresAt)) {
      await prefs.remove(_otpKey);
      throw Exception('Reset code has expired. Please request a new one.');
    }
    if (storedOtp != otp.trim()) {
      throw Exception('Incorrect reset code. Please check your email and try again.');
    }

    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) throw Exception('Unable to reset password. Please contact support.');

    final users = (jsonDecode(usersJson) as List).cast<Map<String, dynamic>>();
    final idx = users.indexWhere(
      (u) => u['email'].toString().toLowerCase() == email.trim().toLowerCase(),
    );
    if (idx == -1) throw Exception('Account not found. Please contact support.');

    users[idx]['password'] = newPassword;
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.remove(_otpKey);
  }

  Future<void> updateProfile({
    String? username,
    String? profilePic,
    String? coverPhoto,
    String? email,
    String? phone,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      username: username,
      profilePic: profilePic,
      coverPhoto: coverPhoto,
      email: email,
      phone: phone,
    );

    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null) {
      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      if (username != null)   sessionMap['username']   = username;
      if (profilePic != null) sessionMap['profilePic'] = profilePic;
      if (coverPhoto != null) sessionMap['coverPhoto'] = coverPhoto;
      if (email != null)      sessionMap['email']      = email;
      if (phone != null)      sessionMap['phone']      = phone;
      await prefs.setString(_sessionKey, jsonEncode(sessionMap));
    }

    // Also update stored users list
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final users = (jsonDecode(usersJson) as List).cast<Map<String, dynamic>>();
      final idx = users.indexWhere((u) => u['id'] == _currentUser!.id);
      if (idx != -1) {
        if (username != null)   users[idx]['username']   = username;
        if (profilePic != null) users[idx]['profilePic'] = profilePic;
        if (coverPhoto != null) users[idx]['coverPhoto'] = coverPhoto;
        if (email != null)      users[idx]['email']      = email;
        if (phone != null)      users[idx]['phone']      = phone;
        await prefs.setString(_usersKey, jsonEncode(users));
      }
    }
  }
}
