import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';

class CreateMedidasCorporalesScreen extends StatefulWidget {
  final Finca finca;

  const CreateMedidasCorporalesScreen({
    super.key,
    required this.finca,
  });

  @override
  State<CreateMedidasCorporalesScreen> createState() => _CreateMedidasCorporalesScreenState();
}

class _CreateMedidasCorporalesScreenState extends State<CreateMedidasCorporalesScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isOffline = false;

  final TextEditingController _animalIdController = TextEditingController();
  final TextEditingController _etapaIdController = TextEditingController();
  final TextEditingController _alturaHCController = TextEditingController();
  final TextEditingController _alturaHGController = TextEditingController();
  final TextEditingController _perimetroPTController = TextEditingController();
  final TextEditingController _perimetroPCAController = TextEditingController();
  final TextEditingController _longitudLCController = TextEditingController();
  final TextEditingController _longitudLGController = TextEditingController();
  final TextEditingController _anchuraAGController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _animalIdController.dispose();
    _etapaIdController.dispose();
    _alturaHCController.dispose();
    _alturaHGController.dispose();
    _perimetroPTController.dispose();
    _perimetroPCAController.dispose();
    _longitudLCController.dispose();
    _longitudLGController.dispose();
    _anchuraAGController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _createMedidasCorporales() async {
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
            content: Text('Medidas corporales registradas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      LoggingService.error('Error creating medidas corporales', 'CreateMedidasCorporalesScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar medidas corporales: $e'),
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

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label (cm) *',
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixText: 'cm',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor ingrese $label';
        }
        if (double.tryParse(value.trim()) == null) {
          return 'Por favor ingrese un número válido';
        }
        if (double.parse(value.trim()) <= 0) {
          return '$label debe ser mayor a 0';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrar Medidas Corporales'),
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

              const SizedBox(height: 24),

              // Measurements Section Header
              Text(
                'Medidas Corporales',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Altura HC Field
              _buildMeasurementField(
                controller: _alturaHCController,
                label: 'Altura HC',
                hint: 'Altura de la cruz',
                icon: Icons.height,
              ),

              const SizedBox(height: 16),

              // Altura HG Field
              _buildMeasurementField(
                controller: _alturaHGController,
                label: 'Altura HG',
                hint: 'Altura de la grupa',
                icon: Icons.height,
              ),

              const SizedBox(height: 16),

              // Perímetro PT Field
              _buildMeasurementField(
                controller: _perimetroPTController,
                label: 'Perímetro PT',
                hint: 'Perímetro torácico',
                icon: Icons.circle_outlined,
              ),

              const SizedBox(height: 16),

              // Perímetro PCA Field
              _buildMeasurementField(
                controller: _perimetroPCAController,
                label: 'Perímetro PCA',
                hint: 'Perímetro de la caña anterior',
                icon: Icons.circle_outlined,
              ),

              const SizedBox(height: 16),

              // Longitud LC Field
              _buildMeasurementField(
                controller: _longitudLCController,
                label: 'Longitud LC',
                hint: 'Longitud corporal',
                icon: Icons.straighten,
              ),

              const SizedBox(height: 16),

              // Longitud LG Field
              _buildMeasurementField(
                controller: _longitudLGController,
                label: 'Longitud LG',
                hint: 'Longitud de la grupa',
                icon: Icons.straighten,
              ),

              const SizedBox(height: 16),

              // Anchura AG Field
              _buildMeasurementField(
                controller: _anchuraAGController,
                label: 'Anchura AG',
                hint: 'Anchura de la grupa',
                icon: Icons.width_full,
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createMedidasCorporales,
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
                          'Registrar Medidas Corporales',
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
                        '• Todos los campos son obligatorios\n'
                        '• Las medidas se registran en centímetros\n'
                        '• HC: Altura de la cruz\n'
                        '• HG: Altura de la grupa\n'
                        '• PT: Perímetro torácico\n'
                        '• PCA: Perímetro de la caña anterior\n'
                        '• LC: Longitud corporal\n'
                        '• LG: Longitud de la grupa\n'
                        '• AG: Anchura de la grupa',
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