import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';

class CreateRegistroLecheroScreen extends StatefulWidget {
  final Finca finca;

  const CreateRegistroLecheroScreen({
    super.key,
    required this.finca,
  });

  @override
  State<CreateRegistroLecheroScreen> createState() => _CreateRegistroLecheroScreenState();
}

class _CreateRegistroLecheroScreenState extends State<CreateRegistroLecheroScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isOffline = false;

  final TextEditingController _fechaPesajeController = TextEditingController();
  final TextEditingController _cantidadTotalController = TextEditingController();
  final TextEditingController _lactanciaIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _fechaPesajeController.dispose();
    _cantidadTotalController.dispose();
    _lactanciaIdController.dispose();
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

  Future<void> _createRegistroLechero() async {
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
            content: Text('Registro lechero creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      LoggingService.error('Error creating registro lechero', 'CreateRegistroLecheroScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear registro lechero: $e'),
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
            const Text('Registrar Producción de Leche'),
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
              // Lactancia ID Field
              TextFormField(
                controller: _lactanciaIdController,
                decoration: const InputDecoration(
                  labelText: 'ID de la Lactancia *',
                  hintText: 'Ingrese el ID de la lactancia',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pregnant_woman),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el ID de la lactancia';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Fecha Pesaje Field
              TextFormField(
                controller: _fechaPesajeController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Pesaje *',
                  hintText: 'Seleccione la fecha de pesaje',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                readOnly: true,
                onTap: () => _selectDate(_fechaPesajeController),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor seleccione la fecha de pesaje';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Cantidad Total Field
              TextFormField(
                controller: _cantidadTotalController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad Total (Litros) *',
                  hintText: 'Ingrese la cantidad total en litros',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_drink),
                  suffixText: 'L',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese la cantidad total';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  if (double.parse(value.trim()) <= 0) {
                    return 'La cantidad debe ser mayor a 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRegistroLechero,
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
                          'Registrar Producción',
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
                        '• La cantidad se registra en litros\n'
                        '• La fecha no puede ser futura\n'
                        '• Debe existir una lactancia activa para el animal',
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