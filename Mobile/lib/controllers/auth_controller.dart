import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  // Default admin credentials
  static const String _adminUsername = 'admin';
  static const String _adminPassword = '0000';

  AuthController() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (_isLoggedIn) {
      final username = prefs.getString('username');
      final role = prefs.getString('role');
      if (username != null && role != null) {
        _currentUser = User(
          username: username,
          password: '', // Don't store password
          role: role,
        );
      }
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    bool success = false;
    
    if (username == _adminUsername && password == _adminPassword) {
      _currentUser = User(
        username: username,
        password: password,
        role: 'admin',
      );
      _isLoggedIn = true;
      success = true;

      // Save login status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      await prefs.setString('role', 'admin');
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    
    // Clear login status
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}
