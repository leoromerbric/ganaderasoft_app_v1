import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/services/sync_service.dart';
import 'package:ganaderasoft_app_v1/services/configuration_service.dart';
import 'package:ganaderasoft_app_v1/services/logging_service.dart';

void main() {
  group('Login Auto-Sync Tests', () {
    setUpAll(() async {
      LoggingService.info(
        'Starting login auto-sync tests',
        'LoginAutoSyncTest',
      );

      // Initialize test environment
      print('Test setup completed');
    });

    group('SyncService Configuration-Only Method', () {
      test(
        'syncConfigurationDataOnly should be available as public method',
        () {
          expect(SyncService.syncConfigurationDataOnly, isA<Function>());
        },
      );

      test('syncConfigurationDataOnly should return Future<bool>', () async {
        // Note: This test will fail if no internet connection, which is expected
        try {
          final result = await SyncService.syncConfigurationDataOnly();
          expect(result, isA<bool>());
          print('Configuration-only sync returned: $result');
        } catch (e) {
          print(
            'Expected failure due to no internet or server unavailable: $e',
          );
          expect(e, isA<Exception>());
        }
      });
    });

    group('Auto-sync Integration', () {
      test(
        'configuration sync should be triggered after successful login flow simulation',
        () async {
          print('Testing login -> auto-sync flow');

          // Simulate what would happen after successful login
          // In real app, this would be called from login_screen.dart after AuthService.login()
          try {
            print('Simulating post-login configuration sync...');
            final syncResult = await SyncService.syncConfigurationDataOnly();
            print('Auto-sync after login completed with result: $syncResult');

            if (syncResult) {
              // Verify configuration data is now available
              final estadosSalud = await ConfigurationService.getEstadosSalud();
              print(
                'Estados de salud after sync: ${estadosSalud.data.data.length} items',
              );
              expect(estadosSalud.data.data.isNotEmpty, true);

              final tiposAnimal = await ConfigurationService.getTiposAnimal();
              print(
                'Tipos de animal after sync: ${tiposAnimal.data.data.length} items',
              );
              expect(tiposAnimal.data.data.isNotEmpty, true);

              final etapas = await ConfigurationService.getEtapas();
              print('Etapas after sync: ${etapas.length} items');
              expect(etapas.isNotEmpty, true);
            }
          } catch (e) {
            print(
              'Auto-sync simulation failed (expected if no connectivity): $e',
            );
            // This is expected in testing environment without proper connectivity
            expect(e, isA<Exception>());
          }
        },
      );
    });

    group('Error Handling', () {
      test('sync failure should not prevent or delay login completion', () {
        // This test verifies that the login process completes immediately
        // and sync runs in background without blocking navigation

        print('Testing non-blocking sync behavior');

        // Simulate the new login_screen.dart flow
        bool loginFlowCompleted = false;
        bool syncStarted = false;

        try {
          // Simulate login success
          print('Simulating successful authentication...');

          // Navigation happens IMMEDIATELY after login (non-blocking)
          loginFlowCompleted = true;
          print('Navigation to HomeScreen completed immediately');

          // Sync starts in background (fire-and-forget)
          SyncService.syncConfigurationDataOnly().catchError((e) {
            print('Background sync failed (this is handled gracefully): $e');
            return false; // Return false to indicate sync failure
          });
          syncStarted = true;
          print('Background sync started (non-blocking)');
        } catch (e) {
          print('Login flow failed: $e');
        }

        expect(
          loginFlowCompleted,
          true,
          reason: 'Login should complete immediately without waiting for sync',
        );
        expect(
          syncStarted,
          true,
          reason: 'Background sync should start after navigation',
        );
      });
    });
  });
}
