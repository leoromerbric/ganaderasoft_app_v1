import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import '../services/database_service.dart';

class CreatePesoCorporalScreen extends StatefulWidget {
  final Finca finca;
  final List<Animal> animales;
  final Animal? selectedAnimal;

  const CreatePesoCorporalScreen({
    super.key,
    required this.finca,
    required this.animales,
    this.selectedAnimal,
  });

  @override
  State<CreatePesoCorporalScreen> createState() =>
      _CreatePesoCorporalScreenState();
}

class _CreatePesoCorporalScreenState extends State<CreatePesoCorporalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Form controllers
  final _fechaPesoController = TextEditingController();
  final _pesoController = TextEditingController();
  final _comentarioController = TextEditingController();

  // Form data
  Animal? _selectedAnimal;
  AnimalDetail? _selectedAnimalDetail;
  EtapaAnimal? _selectedEtapaAnimal;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingAnimalDetail = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _selectedAnimal = widget.selectedAnimal;
    _fechaPesoController.text = DateTime.now().toIso8601String().split('T')[0];
    _checkConnectivity();

    // Load animal detail if an animal is pre-selected
    if (_selectedAnimal != null) {
      _loadAnimalDetail(_selectedAnimal!.idAnimal);
    }
  }

  @override
  void dispose() {
    _fechaPesoController.dispose();
    _pesoController.dispose();
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
        // Set current stage as default selection, but find the matching item from the list
        if (_selectedAnimalDetail?.etapaActual != null) {
          _selectedEtapaAnimal = _selectedAnimalDetail!.etapaAnimales
              .where((etapa) => etapa == _selectedAnimalDetail!.etapaActual!)
              .firstOrNull;
        } else {
          _selectedEtapaAnimal = null;
        }
      });
    } catch (e) {
      LoggingService.error(
        'Error loading animal detail',
        'CreatePesoCorporalScreen',
        e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar detalle del animal: ${e.toString()}',
            ),
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
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _fechaPesoController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _savePesoCorporal() async {
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

    if (_selectedEtapaAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la etapa del animal'),
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
          'Creating peso corporal offline',
          'CreatePesoCorporalScreen',
        );
        
        await DatabaseService.savePendingPesoCorporalOffline(
          fechaPeso: _fechaPesoController.text,
          peso: double.parse(_pesoController.text),
          comentario: _comentarioController.text,
          pesoEtapaAnid: _selectedAnimal!.idAnimal,
          pesoEtapaEtid: _selectedEtapaAnimal!.etanEtapaId,
        );

        LoggingService.info(
          'Peso corporal saved offline successfully',
          'CreatePesoCorporalScreen',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Peso guardado offline. Se sincronizará cuando tengas conexión.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Save online
        final pesoCorporal = PesoCorporal(
          idPeso: 0, // Will be assigned by server
          fechaPeso: _fechaPesoController.text,
          peso: double.parse(_pesoController.text),
          comentario: _comentarioController.text,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          pesoEtapaAnid: _selectedAnimal!.idAnimal,
          pesoEtapaEtid: _selectedEtapaAnimal!.etanEtapaId,
        );

        LoggingService.info('Creating peso corporal', 'CreatePesoCorporalScreen');
        await _authService.createPesoCorporal(pesoCorporal);

        LoggingService.info(
          'Peso corporal created successfully',
          'CreatePesoCorporalScreen',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Peso registrado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      LoggingService.error(
        'Error creating peso corporal',
        'CreatePesoCorporalScreen',
        e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar peso: ${e.toString()}'),
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
        title: const Text('Registrar Peso Corporal'),
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Registro de peso corporal',
                              style: Theme.of(context).textTheme.bodyMedium
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Animal>(
                value: _selectedAnimal,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecciona el animal',
                  prefixIcon: Icon(Icons.pets),
                ),
                items: widget.animales.map((animal) {
                  return DropdownMenuItem<Animal>(
                    value: animal,
                    child: Text('${animal.nombre} (${animal.codigoAnimal})'),
                  );
                }).toList(),
                onChanged: (Animal? value) {
                  setState(() {
                    _selectedAnimal = value;
                    _selectedAnimalDetail = null;
                    _selectedEtapaAnimal = null;
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

              // Etapa selection
              Text(
                'Etapa del Animal *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EtapaAnimal>(
                value: _selectedEtapaAnimal,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _isLoadingAnimalDetail
                      ? 'Cargando etapas...'
                      : 'Selecciona la etapa del animal',
                  prefixIcon: const Icon(Icons.timeline),
                ),
                items:
                    _selectedAnimalDetail?.etapaAnimales.map((etapaAnimal) {
                      return DropdownMenuItem<EtapaAnimal>(
                        value: etapaAnimal,
                        child: Text(
                          '${etapaAnimal.etapa.etapaNombre}${etapaAnimal.etanFechaFin == null ? ' (Actual)' : ''}',
                        ),
                      );
                    }).toList() ??
                    [],
                onChanged: _isLoadingAnimalDetail
                    ? null
                    : (EtapaAnimal? value) {
                        setState(() {
                          _selectedEtapaAnimal = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor selecciona la etapa del animal';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha peso
              Text(
                'Fecha del Pesaje *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fechaPesoController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Selecciona la fecha',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: _selectDate,
                  ),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona la fecha del pesaje';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Peso
              Text(
                'Peso (kg) *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pesoController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ingresa el peso en kilogramos',
                  prefixIcon: Icon(Icons.monitor_weight),
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el peso';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingresa un número válido';
                  }
                  final peso = double.parse(value);
                  if (peso <= 0) {
                    return 'El peso debe ser mayor a 0';
                  }
                  if (peso > 2000) {
                    return 'El peso parece excesivo. Verifica el valor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Comentario
              Text(
                'Comentario',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _comentarioController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Comentarios adicionales sobre el pesaje',
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 32),

              // Tips card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Consejos para el pesaje',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Pese al animal en ayunas para mayor precisión\n'
                        '• Registre el peso a la misma hora cada vez\n'
                        '• Anote condiciones especiales en comentarios',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePesoCorporal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Registrar Peso',
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
