import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/main.dart';
import 'package:ganaderasoft_app_v1/constants/app_constants.dart';

void main() {
  group('GanaderaSoft App Tests', () {
    testWidgets('App starts with splash screen', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const GanaderaSoftApp());

      // Verify that splash screen is displayed
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appSubtitle), findsOneWidget);
      expect(find.byIcon(Icons.agriculture), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('App shows loading indicator on splash', (WidgetTester tester) async {
      await tester.pumpWidget(const GanaderaSoftApp());

      // Verify loading indicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('App Constants Tests', () {
    test('App constants are properly defined', () {
      expect(AppConstants.appName, 'GanaderaSoft');
      expect(AppConstants.appSubtitle, 'Gestión de Fincas Ganaderas');
      expect(AppConstants.tokenKey, 'auth_token');
      expect(AppConstants.userKey, 'user_data');
    });

    test('App constants have proper default values', () {
      expect(AppConstants.defaultPadding, 16.0);
      expect(AppConstants.defaultBorderRadius, 8.0);
      expect(AppConstants.logoutConfirmTitle, isNotEmpty);
      expect(AppConstants.logoutConfirmMessage, isNotEmpty);
    });
  });
}