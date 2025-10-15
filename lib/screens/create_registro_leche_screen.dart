import 'package:flutter/material.dart';
import 'package:ganaderasoft_app_v1/constants/app_constants.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import '../services/database_service.dart';

class CreateRegistroLecheScreen extends StatefulWidget {
  final Finca finca;
  final List<Animal> animales;
  final Animal? selectedAnimal;
  final Lactancia? selectedLactancia;

  const CreateRegistroLecheScreen({
    super.key,
    required this.finca,
    required this.animales,
    this.selectedAnimal,
    this.selectedLactancia,
  });

  @override
  State<CreateRegistroLecheScreen> createState() =>
      _CreateRegistroLecheScreenState();
}

class _CreateRegistroLecheScreenState extends State<CreateRegistroLecheScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Form controllers
  final _fechaPesajeController = TextEditingController();
  final _pesajeTotalController = TextEditingController();

  // Form data
  Animal? _selectedAnimal;
  Lactancia? _selectedLactancia;
  List<Lactancia> _availableLactancias = [];

  // Loading states
  bool _isLoading = false;
  bool _isLoadingLactancias = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _selectedAnimal = widget.selectedAnimal;
    _selectedLactancia = widget.selectedLactancia;

    if (_selectedAnimal != null) {
      _loadLactanciasForAnimal(_selectedAnimal!);
    }
  }

  @override
  void dispose() {
    _fechaPesajeController.dispose();
    _pesajeTotalController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadLactanciasForAnimal(Animal animal) async {
    setState(() {
      _isLoadingLactancias = true;
      _availableLactancias = [];
      _selectedLactancia = null;
    });

    try {
      final lactanciaResponse = await _authService.getLactancia(
        animalId: animal.idAnimal,
      );

      setState(() {
        _availableLactancias = lactanciaResponse.data;
        // Auto-select if there's only one lactancia or if we have a pre-selected one
        if (widget.selectedLactancia != null &&
            _availableLactancias.any(
              (l) => l.lactanciaId == widget.selectedLactancia!.lactanciaId,
            )) {
          _selectedLactancia = _availableLactancias.firstWhere(
            (l) => l.lactanciaId == widget.selectedLactancia!.lactanciaId,
          );
        } else if (_availableLactancias.length == 1) {
          _selectedLactancia = _availableLactancias.first;
        }
      });
    } catch (e) {
      LoggingService.error(
        'Error loading lactancias for animal',
        'CreateRegistroLecheScreen',
        e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar lactancias: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLactancias = false;
      });
    }
  }

  Future<void> _selectFechaPesaje() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaPesajeController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveRegistroLeche() async {
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

    if (_selectedLactancia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una lactancia'),
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
          'Creating registro leche offline',
          'CreateRegistroLecheScreen',
        );

        await DatabaseService.savePendingRegistroLecheOffline(
          lecheFechaPesaje: _fechaPesajeController.text,
          lechePesajeTotal: _pesajeTotalController.text,
          lecheLactanciaId: _selectedLactancia!.lactanciaId,
        );

        LoggingService.info(
          'Registro leche saved offline successfully',
          'CreateRegistroLecheScreen',
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
        final registro = RegistroLechero(
          lecheId: 0, // Will be assigned by server
          lecheFechaPesaje: _fechaPesajeController.text,
          lechePesajeTotal: _pesajeTotalController.text,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          lecheLactanciaId: _selectedLactancia!.lactanciaId,
        );

        LoggingService.info(
          'Creating registro leche',
          'CreateRegistroLecheScreen',
        );
        await _authService.createRegistroLechero(registro);

        LoggingService.info(
          'Registro leche created successfully',
          'CreateRegistroLecheScreen',
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
        'Error creating registro leche',
        'CreateRegistroLecheScreen',
        e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear registro: ${e.toString()}'),
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
          children: [const Text("Registrar Leche")],
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
                initialValue: _selectedAnimal,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecciona un animal hembra',
                  prefixIcon: Icon(Icons.pets),
                ),
                items: widget.animales.map((animal) {
                  return DropdownMenuItem<Animal>(
                    value: animal,
                    child: Text('${animal.nombre} (${animal.codigoAnimal})'),
                  );
                }).toList(),
                onChanged: (Animal? animal) {
                  setState(() {
                    _selectedAnimal = animal;
                    _selectedLactancia = null;
                    _availableLactancias = [];
                  });
                  if (animal != null) {
                    _loadLactanciasForAnimal(animal);
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

              // Lactancia selection
              Text(
                'Lactancia *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Lactancia>(
                initialValue: _selectedLactancia,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _selectedAnimal == null
                      ? 'Primero selecciona un animal'
                      : _isLoadingLactancias
                      ? 'Cargando lactancias...'
                      : 'Selecciona una lactancia',
                  prefixIcon: const Icon(Icons.local_drink),
                ),
                items: _availableLactancias.map((lactancia) {
                  final fechaInicio = DateTime.parse(
                    lactancia.lactanciaFechaInicio,
                  ).toLocal();
                  final fechaFin = lactancia.lactanciaFechaFin != null
                      ? DateTime.parse(lactancia.lactanciaFechaFin!).toLocal()
                      : null;
                  final estado = fechaFin == null ? 'Activa' : 'Finalizada';

                  return DropdownMenuItem<Lactancia>(
                    value: lactancia,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lactancia ${lactancia.lactanciaId} ($estado) - ${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _selectedAnimal == null || _isLoadingLactancias
                    ? null
                    : (Lactancia? lactancia) {
                        setState(() {
                          _selectedLactancia = lactancia;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor selecciona una lactancia';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha de pesaje
              Text(
                'Fecha de Pesaje *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fechaPesajeController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Selecciona la fecha de pesaje',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: _selectFechaPesaje,
                  ),
                ),
                readOnly: true,
                onTap: _selectFechaPesaje,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona la fecha de pesaje';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pesaje total
              Text(
                'Pesaje Total (litros) *',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pesajeTotalController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ingresa la cantidad de leche en litros',
                  prefixIcon: Icon(Icons.scale),
                  suffixText: 'L',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el pesaje total';
                  }
                  final double? pesaje = double.tryParse(value);
                  if (pesaje == null || pesaje <= 0) {
                    return 'Por favor ingresa un número válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRegistroLeche,
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
