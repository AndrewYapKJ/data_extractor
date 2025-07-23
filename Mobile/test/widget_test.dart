// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_extractor_scanner/main.dart';

void main() {
  group('PDF Extractor Scanner App Tests', () {
    testWidgets('App starts with login screen when not authenticated', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that login screen is displayed
      expect(find.text('PDF Extractor Scanner'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Login form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Try to submit empty form
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter username'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
    });

    testWidgets('Successful login navigates to home screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Enter correct credentials
      await tester.enterText(find.byType(TextFormField).first, 'admin');
      await tester.enterText(find.byType(TextFormField).last, '0000');
      
      // Submit form
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      
      // Wait for login process
      await tester.pump(const Duration(seconds: 2));

      // Should navigate to home screen
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload Photo'), findsOneWidget);
      expect(find.text('Upload PDF'), findsOneWidget);
    });

    testWidgets('Invalid login shows error message', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Enter incorrect credentials
      await tester.enterText(find.byType(TextFormField).first, 'wrong');
      await tester.enterText(find.byType(TextFormField).last, 'wrong');
      
      // Submit form
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      
      // Wait for login process
      await tester.pump(const Duration(seconds: 2));

      // Should show error message
      expect(find.text('Invalid credentials. Use admin/0000'), findsOneWidget);
    });
  });
}
