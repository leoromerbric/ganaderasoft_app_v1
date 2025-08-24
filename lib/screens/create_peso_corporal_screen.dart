import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';

class CreatePesoCorporalScreen extends StatefulWidget {
  final Finca finca;

  const CreatePesoCorporalScreen({
    super.key,
    required this.finca,
  });

  @override
  State<CreatePesoCorporalScreen> createState() => _CreatePesoCorporalScreenState();
}

class _CreatePesoCorporalScreenState extends State<CreatePesoCorporalScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isOffline = false;

  final TextEditingController _fechaPesoController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  final TextEditingController _animalIdController = TextEditingController();
  final TextEditingController _etapaIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _fechaPesoController.dispose();
    _pesoController.dispose();
    _comentarioController.dispose();
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
      lastDate: DateTime.now(),
    );

    if (date != null) {
      controller.text = date.toIso8601String().split('T')[0];
    }
  }

  Future<void> _createPesoCorporal() async {
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
            content: Text('Peso corporal registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      LoggingService.error('Error creating peso corporal', 'CreatePesoCorporalScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar peso corporal: $e'),
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
            const Text('Registrar Peso Corporal'),
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

              // Fecha Peso Field
              TextFormField(
                controller: _fechaPesoController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Pesaje *',
                  hintText: 'Seleccione la fecha de pesaje',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                readOnly: true,
                onTap: () => _selectDate(_fechaPesoController),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor seleccione la fecha de pesaje';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Peso Field
              TextFormField(
                controller: _pesoController,
                decoration: const InputDecoration(
                  labelText: 'Peso (kg) *',
                  hintText: 'Ingrese el peso en kilogramos',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight),
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el peso';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  if (double.parse(value.trim()) <= 0) {
                    return 'El peso debe ser mayor a 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Comentario Field
              TextFormField(
                controller: _comentarioController,
                decoration: const InputDecoration(
                  labelText: 'Comentario *',
                  hintText: 'Observaciones sobre el peso',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese un comentario';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPesoCorporal,
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
                          'Registrar Peso Corporal',
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
                        '• El peso se registra en kilogramos\n'
                        '• La fecha no puede ser futura\n'
                        '• Incluya observaciones relevantes sobre el peso',
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