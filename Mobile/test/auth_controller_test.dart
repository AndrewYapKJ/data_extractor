import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_extractor_scanner/controllers/auth_controller.dart';

void main() {
  group('AuthController Tests', () {
    late AuthController authController;

    setUp(() {
      authController = AuthController();
    });

    test('Initial state should be not logged in', () {
      expect(authController.isLoggedIn, false);
      expect(authController.currentUser, null);
      expect(authController.isLoading, false);
    });

    test('Login with correct credentials should succeed', () async {
      final result = await authController.login('admin', '0000');
      
      expect(result, true);
      expect(authController.isLoggedIn, true);
      expect(authController.currentUser, isNotNull);
      expect(authController.currentUser!.username, 'admin');
      expect(authController.currentUser!.role, 'admin');
      expect(authController.isLoading, false);
    });

    test('Login with incorrect credentials should fail', () async {
      final result = await authController.login('wrong', 'wrong');
      
      expect(result, false);
      expect(authController.isLoggedIn, false);
      expect(authController.currentUser, null);
      expect(authController.isLoading, false);
    });

    test('Logout should clear user data', () async {
      // First login
      await authController.login('admin', '0000');
      expect(authController.isLoggedIn, true);
      
      // Then logout
      await authController.logout();
      expect(authController.isLoggedIn, false);
      expect(authController.currentUser, null);
    });
  });
}
