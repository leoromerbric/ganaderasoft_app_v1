import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/farm_management_models.dart';
import '../models/configuration_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import '../services/database_service.dart';

class CreateCambiosAnimalScreen extends StatefulWidget {
  final Finca finca;
  final List<Animal> animales;
  final Animal? selectedAnimal;

  const CreateCambiosAnimalScreen({
    super.key,
    required this.finca,
    required this.animales,
    this.selectedAnimal,
  });

  @override
  State<CreateCambiosAnimalScreen> createState() =>
      _CreateCambiosAnimalScreenState();
}

class _CreateCambiosAnimalScreenState extends State<CreateCambiosAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Form controllers
  final _fechaCambioController = TextEditingController();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _comentarioController = TextEditingController();

  // Form data
  Animal? _selectedAnimal;
  AnimalDetail? _selectedAnimalDetail;
  Etapa? _selectedEtapa;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingAnimalDetail = false;
  bool _isOffline = false;

  // Data lists
  List<Animal> _animales = [];

  @override
  void initState() {
    super.initState();
    _animales = widget.animales;
    _selectedAnimal = widget.selectedAnimal;
    _fechaCambioController.text = DateTime.now().toIso8601String().split(
      'T',
    )[0];
    _checkConnectivity();

    // Load animal detail if an animal is pre-selected
    if (_selectedAnimal != null) {
      _loadAnimalDetail(_selectedAnimal!.idAnimal);
    }
  }

  @override
  void dispose() {
    _fechaCambioController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadAnimalDetail(int animalId) async {
    setState(() {
      _isLoadingAnimalDetail = true;
    });

    try {
      final animalDetailResponse = await _authService.getAnimalDetail(animalId);
      setState(() {
        _selectedAnimalDetail = animalDetailResponse.data;
        // Clear selected etapa when loading new animal detail
        _selectedEtapa = null;
      });
    } catch (e) {
      LoggingService.error('Error loading animal detail', 'CreateCambiosAnimalScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalle del animal: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingAnimalDetail = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fechaCambioController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveCambiosAnimal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un animal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedEtapa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una etapa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check connectivity first
      await _checkConnectivity();

      if (_isOffline) {
        // Save offline
        LoggingService.info(
          'Creating cambios animal offline',
          'CreateCambiosAnimalScreen',
        );
        
        await DatabaseService.savePendingCambiosAnimalOffline(
          fechaCambio: _fechaCambioController.text,
          etapaCambio: _selectedEtapa!.etapaNombre,
          peso: double.parse(_pesoController.text),
          altura: double.parse(_alturaController.text),
          comentario: _comentarioController.text,
          cambiosEtapaAnid: _selectedAnimal!.idAnimal,
          cambiosEtapaEtid: _selectedEtapa!.etapaId,
        );

        LoggingService.info(
          'Cambios animal saved offline successfully',
          'CreateCambiosAnimalScreen',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cambio de animal guardado offline. Se sincronizará cuando tengas conexión.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Save online
        final cambiosAnimal = CambiosAnimal(
          idCambio: 0, // Will be assigned by server
          fechaCambio: _fechaCambioController.text,
          etapaCambio: _selectedEtapa!.etapaNombre,
          peso: double.parse(_pesoController.text),
          altura: double.parse(_alturaController.text),
          comentario: _comentarioController.text,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          cambiosEtapaAnid: _selectedAnimal!.idAnimal,
          cambiosEtapaEtid: _selectedEtapa!.etapaId,
        );

        LoggingService.info(
          'Creating cambios animal',
          'CreateCambiosAnimalScreen',
        );
        await _authService.createCambiosAnimal(cambiosAnimal);

        LoggingService.info(
          'Cambios animal created successfully',
          'CreateCambiosAnimalScreen',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cambio de animal registrado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      LoggingService.error(
        'Error creating cambios animal',
        'CreateCambiosAnimalScreen',
        e,
      );
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
        title: const Text('Registrar Cambio de Animal'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    // Farm info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.agriculture,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.finca.nombre,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Registro de cambio de animal',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Animal selection
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
                        hintText: 'Selecciona el animal',
                      ),
                      items: _animales.map((animal) {
                        return DropdownMenuItem<Animal>(
                          value: animal,
                          child: Text(
                            '${animal.nombre} (${animal.codigoAnimal})',
                          ),
                        );
                      }).toList(),
                      onChanged: (Animal? value) {
                        setState(() {
                          _selectedAnimal = value;
                          _selectedAnimalDetail = null;
                          _selectedEtapa = null;
                        });
                        
                        if (value != null) {
                          _loadAnimalDetail(value.idAnimal);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona un animal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha cambio
                    Text(
                      'Fecha del Cambio *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fechaCambioController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Selecciona la fecha',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDate,
                        ),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor selecciona la fecha del cambio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Etapa
                    Text(
                      'Nueva Etapa *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Etapa>(
                      value: _selectedEtapa,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: _isLoadingAnimalDetail 
                            ? 'Cargando etapas...' 
                            : 'Selecciona la nueva etapa',
                        prefixIcon: const Icon(Icons.timeline),
                      ),
                      items: _selectedAnimalDetail?.etapaAnimales.map((etapaAnimal) {
                        return DropdownMenuItem<Etapa>(
                          value: etapaAnimal.etapa,
                          child: Text(
                            '${etapaAnimal.etapa.etapaNombre}${etapaAnimal.etanFechaFin == null ? ' (Actual)' : ''}',
                          ),
                        );
                      }).toList() ?? [],
                      onChanged: _isLoadingAnimalDetail ? null : (Etapa? value) {
                        setState(() {
                          _selectedEtapa = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona la nueva etapa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Peso
                    Text(
                      'Peso (kg) *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pesoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingresa el peso en kilogramos',
                        suffixText: 'kg',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el peso';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor ingresa un número válido';
                        }
                        if (double.parse(value) <= 0) {
                          return 'El peso debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Altura
                    Text(
                      'Altura (cm) *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _alturaController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingresa la altura en centímetros',
                        suffixText: 'cm',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la altura';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor ingresa un número válido';
                        }
                        if (double.parse(value) <= 0) {
                          return 'La altura debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Comentario
                    Text(
                      'Comentario',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _comentarioController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Comentarios adicionales sobre el cambio',
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCambiosAnimal,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
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
