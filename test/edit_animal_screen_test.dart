import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ganaderasoft_app_v1/screens/edit_animal_screen.dart';
import 'package:ganaderasoft_app_v1/models/finca.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';

void main() {
  group('EditAnimalScreen Tests', () {
    testWidgets('EditAnimalScreen should display animal name in title', (WidgetTester tester) async {
      // Create test data
      final finca = Finca(
        idFinca: 1,
        idPropietario: 1,
        nombre: 'Test Finca',
        explotacionTipo: 'Bovinos',
        archivado: false,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final rebano = Rebano(
        idRebano: 1,
        idFinca: 1,
        nombre: 'Test Rebano',
        archivado: false,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final animal = Animal(
        idAnimal: 1,
        idRebano: 1,
        nombre: 'Test Animal',
        codigoAnimal: 'TEST-001',
        sexo: 'M',
        fechaNacimiento: DateTime.now().toIso8601String(),
        procedencia: 'Local',
        archivado: false,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        fkComposicionRaza: 1,
      );

      // Build our widget
      await tester.pumpWidget(
        MaterialApp(
          home: EditAnimalScreen(
            finca: finca,
            rebanos: [rebano],
            animal: animal,
          ),
        ),
      );

      // Verify the app bar title
      expect(find.text('Editar Animal'), findsOneWidget);
    });

    testWidgets('EditAnimalScreen should pre-populate form fields', (WidgetTester tester) async {
      // Create test data
      final finca = Finca(
        idFinca: 1,
        idPropietario: 1,
        nombre: 'Test Finca',
        explotacionTipo: 'Bovinos',
        archivado: false,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final rebano = Rebano(
        idRebano: 1,
        idFinca: 1,
        nombre: 'Test Rebano',
        archivado: false,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final animal = Animal(
        idAnimal: 1,
        idRebano: 1,
        nombre: 'Test Animal',
        codigoAnimal: 'TEST-001',
        sexo: 'M',
        fechaNacimiento: DateTime.now().toIso8601String(),
        procedencia: 'Local',
        archivado: false,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        fkComposicionRaza: 1,
      );

      // Build our widget
      await tester.pumpWidget(
        MaterialApp(
          home: EditAnimalScreen(
            finca: finca,
            rebanos: [rebano],
            animal: animal,
          ),
        ),
      );

      // Wait for the loading to complete
      await tester.pump(const Duration(seconds: 1));

      // Check that form fields are populated with animal data
      expect(find.text('Test Animal'), findsOneWidget);
      expect(find.text('TEST-001'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
    });
  });
}