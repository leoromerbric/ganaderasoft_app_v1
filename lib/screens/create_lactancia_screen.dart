import 'package:flutter/material.dart';
import 'package:ganaderasoft_app_v1/constants/app_constants.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import '../services/database_service.dart';

class CreateLactanciaScreen extends StatefulWidget {
  final Finca finca;
  final List<Animal> animales;
  final Animal? selectedAnimal;

  const CreateLactanciaScreen({
    super.key,
    required this.finca,
    required this.animales,
    this.selectedAnimal,
  });

  @override
  State<CreateLactanciaScreen> createState() => _CreateLactanciaScreenState();
}

class _CreateLactanciaScreenState extends State<CreateLactanciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Form controllers
  final _fechaInicioController = TextEditingController();
  final _fechaFinController = TextEditingController();
  final _fechaSecadoController = TextEditingController();

  // Form data
  Animal? _selectedAnimal;
  AnimalDetail? _selectedAnimalDetail;
  EtapaAnimal? _selectedEtapaAnimal;
  bool _isActive = true;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingAnimalDetail = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _selectedAnimal = widget.selectedAnimal;
    _fechaInicioController.text = DateTime.now().toIso8601String().split(
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
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _fechaSecadoController.dispose();
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
        'CreateLactanciaScreen',
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

  Future<void> _selectFechaInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _fechaInicioController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectFechaFin() async {
    if (_fechaInicioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero selecciona la fecha de inicio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final fechaInicio = DateTime.parse(_fechaInicioController.text);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaInicio.add(const Duration(days: 30)),
      firstDate: fechaInicio,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fechaFinController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectFechaSecado() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fechaSecadoController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveLactancia() async {
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
          'Creating lactancia offline',
          'CreateLactanciaScreen',
        );

        await DatabaseService.savePendingLactanciaOffline(
          lactanciaFechaInicio: _fechaInicioController.text,
          lactanciaFechaFin: _isActive
              ? null
              : (_fechaFinController.text.isNotEmpty
                    ? _fechaFinController.text
                    : null),
          lactanciaSecado: _fechaSecadoController.text.isNotEmpty
              ? _fechaSecadoController.text
              : null,
          lactanciaEtapaAnid: _selectedAnimal!.idAnimal,
          lactanciaEtapaEtid: _selectedEtapaAnimal!.etanEtapaId,
        );

        LoggingService.info(
          'Lactancia saved offline successfully',
          'CreateLactanciaScreen',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Guardado en modo offline. Se sincronizará cuando tengas conexión.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Save online
        final lactancia = Lactancia(
          lactanciaId: 0, // Will be assigned by server
          lactanciaFechaInicio: _fechaInicioController.text,
          lactanciaFechaFin: _isActive
              ? null
              : (_fechaFinController.text.isNotEmpty
                    ? _fechaFinController.text
                    : null),
          lactanciaSecado: _fechaSecadoController.text.isNotEmpty
              ? _fechaSecadoController.text
              : null,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          lactanciaEtapaAnid: _selectedAnimal!.idAnimal,
          lactanciaEtapaEtid: _selectedEtapaAnimal!.etanEtapaId,
        );

        LoggingService.info('Creating lactancia', 'CreateLactanciaScreen');
        await _authService.createLactancia(lactancia);

        LoggingService.info(
          'Lactancia created successfully',
          'CreateLactanciaScreen',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guardado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      LoggingService.error(
        'Error creating lactancia',
        'CreateLactanciaScreen',
        e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar lactancia: ${e.toString()}'),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
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
                AppConstants.offlineMode,
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
              // Animal selection
              Text(
                'Animal *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Animal>(
                initialValue: _selectedAnimal,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecciona el animal',
                  prefixIcon: Icon(Icons.pets),
                ),
                items: widget.animales
                    .where((animal) => animal.sexo.toUpperCase() == 'F')
                    .map((animal) {
                      return DropdownMenuItem<Animal>(
                        value: animal,
                        child: Text(
                          '${animal.nombre} (${animal.codigoAnimal})',
                        ),
                      );
                    })
                    .toList(),
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
                initialValue: _selectedEtapaAnimal,
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

              // Estado de lactancia
              Text(
                'Estado de la Lactancia *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Activa'),
                      subtitle: const Text('En curso'),
                      value: true,
                      // ignore: deprecated_member_use
                      groupValue: _isActive,
                      // ignore: deprecated_member_use
                      onChanged: (bool? value) {
                        setState(() {
                          _isActive = value ?? true;
                          if (_isActive) {
                            _fechaFinController.clear();
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Finalizada'),
                      subtitle: const Text('Terminada'),
                      value: false,
                      groupValue: _isActive,
                      onChanged: (bool? value) {
                        setState(() {
                          _isActive = value ?? true;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fecha inicio
              Text(
                'Fecha de Inicio *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fechaInicioController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Selecciona la fecha de inicio',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: _selectFechaInicio,
                  ),
                ),
                readOnly: true,
                onTap: _selectFechaInicio,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona la fecha de inicio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha fin - Always show
              Text(
                'Fecha de Fin',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fechaFinController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Selecciona la fecha de fin (opcional)',
                  prefixIcon: const Icon(Icons.event_busy),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: _selectFechaFin,
                  ),
                ),
                readOnly: true,
                onTap: _selectFechaFin,
              ),
              const SizedBox(height: 16),

              // Fecha de secado - Always show as date picker
              Text(
                'Fecha de Secado',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fechaSecadoController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Selecciona la fecha de secado (opcional)',
                  prefixIcon: const Icon(Icons.water_drop),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: _selectFechaSecado,
                  ),
                ),
                readOnly: true,
                onTap: _selectFechaSecado,
              ),
              const SizedBox(height: 32),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLactancia,
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
                          'Guardar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 38, 39, 37),
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
