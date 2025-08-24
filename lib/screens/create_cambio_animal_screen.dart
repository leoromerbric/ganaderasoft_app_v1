import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';

class CreateCambioAnimalScreen extends StatefulWidget {
  final Finca finca;

  const CreateCambioAnimalScreen({
    super.key,
    required this.finca,
  });

  @override
  State<CreateCambioAnimalScreen> createState() => _CreateCambioAnimalScreenState();
}

class _CreateCambioAnimalScreenState extends State<CreateCambioAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Form controllers
  final _fechaCambioController = TextEditingController();
  final _valorAnteriorController = TextEditingController();
  final _valorNuevoController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Form data
  Animal? _selectedAnimal;
  String? _selectedTipoCambio;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isOffline = false;

  // Data lists
  List<Animal> _animales = [];
  final List<String> _tiposCambio = [
    'Estado',
    'Etapa',
    'Rebano',
    'Peso',
    'Salud',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    _fechaCambioController.text = _formatDateForInput(DateTime.now());
    _checkConnectivity();
    _loadAnimales();
  }

  @override
  void dispose() {
    _fechaCambioController.dispose();
    _valorAnteriorController.dispose();
    _valorNuevoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadAnimales() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final animalesResponse = await _authService.getAnimales(
        idFinca: widget.finca.idFinca,
      );
      
      setState(() {
        _animales = animalesResponse.animales;
        _isLoadingData = false;
      });

      LoggingService.info(
        'Animales loaded for cambio form (${_animales.length} items)',
        'CreateCambioAnimalScreen',
      );
    } catch (e) {
      LoggingService.error('Error loading animales', 'CreateCambioAnimalScreen', e);
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _fechaCambioController.text = _formatDateForInput(picked);
      });
    }
  }

  String _formatDateForInput(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.createCambioAnimal(
        idAnimal: _selectedAnimal!.idAnimal,
        fechaCambio: _fechaCambioController.text,
        tipoCambio: _selectedTipoCambio!,
        valorAnterior: _valorAnteriorController.text,
        valorNuevo: _valorNuevoController.text,
        observaciones: _observacionesController.text.isEmpty 
            ? null 
            : _observacionesController.text,
      );

      LoggingService.info(
        'Cambio animal created successfully',
        'CreateCambioAnimalScreen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambio registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      LoggingService.error('Error creating cambio animal', 'CreateCambioAnimalScreen', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar cambio: ${e.toString()}'),
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
        title: const Text('Registrar Cambio'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animal
                    Text(
                      'Animal *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Animal>(
                      value: _selectedAnimal,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona un animal',
                      ),
                      items: _animales.map((animal) {
                        return DropdownMenuItem<Animal>(
                          value: animal,
                          child: Text('${animal.nombre} (${animal.codigoAnimal})'),
                        );
                      }).toList(),
                      onChanged: (Animal? value) {
                        setState(() {
                          _selectedAnimal = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona un animal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha de Cambio
                    Text(
                      'Fecha de Cambio *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fechaCambioController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'YYYY-MM-DD',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor selecciona la fecha del cambio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tipo de Cambio
                    Text(
                      'Tipo de Cambio *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTipoCambio,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona el tipo de cambio',
                      ),
                      items: _tiposCambio.map((tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedTipoCambio = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona el tipo de cambio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Valor Anterior
                    Text(
                      'Valor Anterior *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _valorAnteriorController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingresa el valor anterior',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el valor anterior';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Valor Nuevo
                    Text(
                      'Valor Nuevo *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _valorNuevoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingresa el valor nuevo',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el valor nuevo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Observaciones
                    Text(
                      'Observaciones',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _observacionesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Observaciones adicionales (opcional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 192, 212, 59),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Registrar Cambio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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