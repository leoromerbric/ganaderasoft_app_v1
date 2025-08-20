import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/screens/login_screen.dart';
import 'package:ganaderasoft_app_v1/screens/splash_screen.dart';

void main() {
  group('Logo Widget Tests', () {
    testWidgets('LoginScreen should build with logo image', (WidgetTester tester) async {
      // Build the LoginScreen widget
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify that an Image widget is present (our logo)
      expect(find.byType(Image), findsOneWidget);
      
      // Verify that the old null Icon is no longer present
      expect(find.byIcon(Icons.agriculture), findsNothing);
      
      // Verify app name and subtitle are still present
      expect(find.text('GanaderaSoft'), findsOneWidget);
      expect(find.text('Gestión de Fincas Ganaderas'), findsOneWidget);
    });

    testWidgets('SplashScreen should build with logo image', (WidgetTester tester) async {
      // Build the SplashScreen widget
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verify that an Image widget is present (our logo)
      expect(find.byType(Image), findsOneWidget);
      
      // Verify that the old agriculture Icon is no longer present
      expect(find.byIcon(Icons.agriculture), findsNothing);
      
      // Verify app name and subtitle are still present
      expect(find.text('GanaderaSoft'), findsOneWidget);
      expect(find.text('Gestión de Fincas Ganaderas'), findsOneWidget);
      
      // Verify loading indicator is present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Logo image should have correct properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find the Image widget
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      // Get the Image widget
      final Image imageWidget = tester.widget(imageFinder);
      
      // Verify it's an AssetImage
      expect(imageWidget.image, isA<AssetImage>());
      
      // Verify the asset path
      final AssetImage assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'lib/media/ganadera_logo_v1.png');
      
      // Verify dimensions
      expect(imageWidget.width, 80);
      expect(imageWidget.height, 80);
      expect(imageWidget.fit, BoxFit.contain);
    });
  });
}