import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';

class CreateLactanciaScreen extends StatefulWidget {
  final Finca finca;

  const CreateLactanciaScreen({
    super.key,
    required this.finca,
  });

  @override
  State<CreateLactanciaScreen> createState() => _CreateLactanciaScreenState();
}

class _CreateLactanciaScreenState extends State<CreateLactanciaScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isOffline = false;

  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  final TextEditingController _secadoController = TextEditingController();
  final TextEditingController _animalIdController = TextEditingController();
  final TextEditingController _etapaIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _secadoController.dispose();
    _animalIdController.dispose();
    _etapaIdController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      controller.text = date.toIso8601String().split('T')[0];
    }
  }

  Future<void> _createLactancia() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // This would need to be implemented in AuthService
      // For now, simulate creation
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lactancia registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      LoggingService.error('Error creating lactancia', 'CreateLactanciaScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar lactancia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrar Lactancia'),
            Text(
              widget.finca.nombre,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Sin conexión',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animal ID Field
              TextFormField(
                controller: _animalIdController,
                decoration: const InputDecoration(
                  labelText: 'ID del Animal *',
                  hintText: 'Ingrese el ID del animal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el ID del animal';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Etapa ID Field
              TextFormField(
                controller: _etapaIdController,
                decoration: const InputDecoration(
                  labelText: 'ID de la Etapa *',
                  hintText: 'Ingrese el ID de la etapa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timeline),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el ID de la etapa';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Fecha Inicio Field
              TextFormField(
                controller: _fechaInicioController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Inicio *',
                  hintText: 'Seleccione la fecha de inicio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                readOnly: true,
                onTap: () => _selectDate(_fechaInicioController),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor seleccione la fecha de inicio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Fecha Fin Field (Optional)
              TextFormField(
                controller: _fechaFinController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Fin (Opcional)',
                  hintText: 'Seleccione la fecha de fin',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                readOnly: true,
                onTap: () => _selectDate(_fechaFinController),
              ),

              const SizedBox(height: 16),

              // Secado Field (Optional)
              TextFormField(
                controller: _secadoController,
                decoration: const InputDecoration(
                  labelText: 'Secado (Opcional)',
                  hintText: 'Información sobre el secado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createLactancia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 192, 212, 59),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Registrar Lactancia',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 38, 39, 37),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Información',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Los campos marcados con * son obligatorios\n'
                        '• La fecha de fin es opcional si la lactancia está activa\n'
                        '• El secado incluye información adicional sobre el proceso',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}