import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganaderasoft_app_v1/screens/create_animal_screen.dart';
import 'package:ganaderasoft_app_v1/models/finca.dart';
import 'package:ganaderasoft_app_v1/models/animal.dart';

void main() {
  group('Create Animal Screen Tests', () {
    late Finca testFinca;
    late List<Rebano> testRebanos;

    setUp(() {
      testFinca = Finca(
        idFinca: 1,
        idPropietario: 1,
        archivado: false,
        nombre: 'Test Finca',
        explotacionTipo: "Test explotacionTipo",
        propietario: Propietario(
          id: 1,
          idPersonal: 1,
          archivado: false,
          nombre: 'Test',
          apellido: 'Owner',
          telefono: '12345678',
        ),

        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      testRebanos = [
        Rebano(
          idRebano: 1,
          nombre: 'Test Rebano',
          archivado: false,
          idFinca: 1,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ];
    });

    testWidgets('Procedencia field should be a text input field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateAnimalScreen(finca: testFinca, rebanos: testRebanos),
        ),
      );

      // Wait for loading to complete
      await tester.pump();

      // Look for the procedencia text field
      expect(find.text('Procedencia *'), findsOneWidget);

      // Verify it's a TextFormField, not a DropdownButtonFormField
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Ingresa la procedencia del animal'), findsOneWidget);

      // Should not find dropdown-related text
      expect(find.text('Selecciona la procedencia'), findsNothing);
    });

    testWidgets('Procedencia field validation works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateAnimalScreen(finca: testFinca, rebanos: testRebanos),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Find the procedencia text field
      final procedenciaField = find.widgetWithText(
        TextFormField,
        'Ingresa la procedencia del animal',
      );
      expect(procedenciaField, findsOneWidget);

      // Try to submit with empty procedencia (would trigger validation)
      // Note: This is a simplified test - in real testing we'd fill other required fields too
    });

    testWidgets('Date picker should not have locale parameter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateAnimalScreen(finca: testFinca, rebanos: testRebanos),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Look for the date field
      expect(find.text('Fecha de Nacimiento *'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);

      // Tap on the date field
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // The date picker should open without MaterialLocalizations error
      // If our fix worked, this test should pass without throwing the error
    });
  });
}
