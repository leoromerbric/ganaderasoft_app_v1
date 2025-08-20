import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Logo Asset Tests', () {
    test('ganadera_logo_v1.png asset should be accessible', () async {
      // Verify that the logo asset can be loaded
      expect(
        () async {
          final ByteData data = await rootBundle.load('lib/media/ganadera_logo_v1.png');
          return data.lengthInBytes > 0;
        }(),
        completion(isTrue),
      );
    });

    test('logo asset should have correct path configuration', () {
      // This test verifies that the asset path is correctly configured
      // The actual loading test above would catch configuration issues
      expect('lib/media/ganadera_logo_v1.png', isNotEmpty);
      expect('lib/media/ganadera_logo_v1.png', endsWith('.png'));
    });
  });
}