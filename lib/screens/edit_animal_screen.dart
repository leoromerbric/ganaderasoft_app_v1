import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/configuration_models.dart';
import '../services/auth_service.dart';
import '../services/configuration_service.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';

class EditAnimalScreen extends StatefulWidget {
  final Finca finca;
  final List<Rebano> rebanos;
  final Animal animal;

  const EditAnimalScreen({
    super.key,
    required this.finca,
    required this.rebanos,
    required this.animal,
  });

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Form controllers
  final _nombreController = TextEditingController();
  final _codigoAnimalController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _procedenciaController = TextEditingController();

  // Form data
  Rebano? _selectedRebano;
  String? _selectedSexo;
  TipoAnimal? _selectedTipoAnimal;
  ComposicionRaza? _selectedComposicionRaza;
  EstadoSalud? _selectedEstadoSalud;
  Etapa? _selectedEtapa;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isOffline = false;

  // Configuration data
  List<TipoAnimal> _tiposAnimal = [];
  List<ComposicionRaza> _composicionesRaza = [];
  List<EstadoSalud> _estadosSalud = [];
  List<Etapa> _etapas = [];
  List<Rebano> _rebanos = [];

  final List<String> _sexoOptions = ['M', 'F'];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _populateFormWithAnimalData();
  }

  void _populateFormWithAnimalData() {
    _nombreController.text = widget.animal.nombre;
    _codigoAnimalController.text = widget.animal.codigoAnimal;
    _fechaNacimientoController.text = _formatDateForInput(widget.animal.fechaNacimiento);
    _procedenciaController.text = widget.animal.procedencia;
    _selectedSexo = widget.animal.sexo;
    
    // Find and set the selected rebano
    _selectedRebano = widget.rebanos.firstWhere(
      (rebano) => rebano.idRebano == widget.animal.idRebano,
      orElse: () => widget.rebanos.first,
    );
  }

  String _formatDateForInput(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoAnimalController.dispose();
    _fechaNacimientoController.dispose();
    _procedenciaController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      _rebanos = widget.rebanos;

      // Check connectivity
      final isConnected = await ConnectivityService.isConnected();
      setState(() {
        _isOffline = !isConnected;
      });

      if (isConnected) {
        // Load configuration data from server
        await _loadConfigurationData();
      } else {
        // Load from local database
        await _loadOfflineConfigurationData();
      }

      // Set the selected composition race based on animal data
      if (_composicionesRaza.isNotEmpty) {
        _selectedComposicionRaza = _composicionesRaza.firstWhere(
          (comp) => comp.idComposicion == widget.animal.fkComposicionRaza,
          orElse: () => _composicionesRaza.first,
        );
      }

    } catch (e) {
      LoggingService.error('Error loading configuration data', 'EditAnimalScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos de configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _loadConfigurationData() async {
    try {
      final responses = await Future.wait([
        ConfigurationService.getTiposAnimal(),
        ConfigurationService.getComposicionesRaza(),
        ConfigurationService.getEstadosSalud(),
        ConfigurationService.getEtapas(),
      ]);

      setState(() {
        _tiposAnimal = responses[0] as List<TipoAnimal>;
        _composicionesRaza = responses[1] as List<ComposicionRaza>;
        _estadosSalud = responses[2] as List<EstadoSalud>;
        _etapas = responses[3] as List<Etapa>;
      });
    } catch (e) {
      LoggingService.error('Error loading server configuration', 'EditAnimalScreen', e);
      await _loadOfflineConfigurationData();
    }
  }

  Future<void> _loadOfflineConfigurationData() async {
    try {
      final responses = await Future.wait([
        DatabaseService.getTiposAnimalOffline(),
        DatabaseService.getComposicionesRazaOffline(),
        DatabaseService.getEstadosSaludOffline(),
        DatabaseService.getEtapasOffline(),
      ]);

      setState(() {
        _tiposAnimal = responses[0] as List<TipoAnimal>;
        _composicionesRaza = responses[1] as List<ComposicionRaza>;
        _estadosSalud = responses[2] as List<EstadoSalud>;
        _etapas = responses[3] as List<Etapa>;
      });
    } catch (e) {
      LoggingService.error('Error loading offline configuration', 'EditAnimalScreen', e);
      rethrow;
    }
  }

  List<Etapa> _getFilteredEtapas() {
    if (_selectedTipoAnimal == null) return [];
    return _etapas
        .where((etapa) =>
            etapa.fkTipoAnimalId == _selectedTipoAnimal!.tipoAnimalId)
        .toList();
  }

  Future<void> _updateAnimal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRebano == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un rebaño'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSexo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona el sexo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTipoAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona el tipo de animal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedComposicionRaza == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la composición de raza'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedEstadoSalud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona el estado de salud'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedEtapa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la etapa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isConnected = await ConnectivityService.isConnected();

      if (!isConnected) {
        // For offline mode, you might want to implement local storage updates
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sin conexión. La actualización requiere conexión a internet.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Update online
      final updatedAnimal = await _authService.updateAnimal(
        idAnimal: widget.animal.idAnimal,
        idRebano: _selectedRebano!.idRebano,
        nombre: _nombreController.text.trim(),
        codigoAnimal: _codigoAnimalController.text.trim(),
        sexo: _selectedSexo!,
        fechaNacimiento: _fechaNacimientoController.text,
        procedencia: _procedenciaController.text.trim(),
        fkComposicionRaza: _selectedComposicionRaza!.idComposicion,
        estadoId: _selectedEstadoSalud!.estadoId,
        etapaId: _selectedEtapa!.etapaId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      LoggingService.error('Error updating animal', 'EditAnimalScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar animal: $e'),
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

  Future<void> _selectDate() async {
    try {
      DateTime initialDate = DateTime.now();
      try {
        // Try to parse existing date if any
        if (_fechaNacimientoController.text.isNotEmpty) {
          final parts = _fechaNacimientoController.text.split('/');
          if (parts.length == 3) {
            initialDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      } catch (e) {
        // If parsing fails, use current date
        initialDate = DateTime.now();
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (picked != null) {
        setState(() {
          _fechaNacimientoController.text =
              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        });
      }
    } catch (e) {
      LoggingService.error('Error selecting date', 'EditAnimalScreen', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Animal'),
        backgroundColor: const Color.fromARGB(255, 192, 212, 59),
        foregroundColor: const Color.fromARGB(255, 38, 39, 37),
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
                    // Offline indicator
                    if (_isOffline)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off, color: Colors.orange[800]),
                            const SizedBox(width: 8),
                            Text(
                              'Modo offline - La actualización requiere conexión',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Rebaño
                    Text(
                      'Rebaño *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Rebano>(
                      value: _selectedRebano,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona un rebaño',
                      ),
                      items: _rebanos.map((rebano) {
                        return DropdownMenuItem<Rebano>(
                          value: rebano,
                          child: Text(rebano.nombre),
                        );
                      }).toList(),
                      onChanged: (Rebano? value) {
                        setState(() {
                          _selectedRebano = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona un rebaño';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre
                    Text(
                      'Nombre *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingresa el nombre del animal',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el nombre del animal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Código Animal
                    Text(
                      'Código Animal *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codigoAnimalController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: ANIMAL-001',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el código del animal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sexo
                    Text(
                      'Sexo *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSexo,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona el sexo',
                      ),
                      items: _sexoOptions.map((sexo) {
                        return DropdownMenuItem<String>(
                          value: sexo,
                          child: Text(sexo == 'M' ? 'Macho (M)' : 'Hembra (F)'),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedSexo = value;
                          _selectedTipoAnimal =
                              null; // Reset tipo animal when sexo changes
                          _selectedEtapa =
                              null; // Reset etapa when sexo changes
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona el sexo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tipo Animal
                    Text(
                      'Tipo de Animal *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TipoAnimal>(
                      value: _selectedTipoAnimal,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona el tipo de animal',
                      ),
                      items: _selectedSexo == null
                          ? []
                          : _tiposAnimal.map((tipoAnimal) {
                              return DropdownMenuItem<TipoAnimal>(
                                value: tipoAnimal,
                                child: Text(tipoAnimal.tipoAnimalNombre),
                              );
                            }).toList(),
                      onChanged: _selectedSexo == null
                          ? null
                          : (TipoAnimal? value) {
                              setState(() {
                                _selectedTipoAnimal = value;
                                _selectedEtapa =
                                    null; // Reset etapa when tipo animal changes
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona el tipo de animal';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha de Nacimiento
                    Text(
                      'Fecha de Nacimiento *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fechaNacimientoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'DD/MM/YYYY',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor selecciona la fecha de nacimiento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Procedencia
                    Text(
                      'Procedencia *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _procedenciaController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Local, Compra, etc.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa la procedencia';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Composición de Raza
                    Text(
                      'Composición de Raza *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ComposicionRaza>(
                      value: _selectedComposicionRaza,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona la composición de raza',
                      ),
                      items: _composicionesRaza.map((composicion) {
                        return DropdownMenuItem<ComposicionRaza>(
                          value: composicion,
                          child: Text(
                              '${composicion.nombre} (${composicion.siglas})'),
                        );
                      }).toList(),
                      onChanged: (ComposicionRaza? value) {
                        setState(() {
                          _selectedComposicionRaza = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona la composición de raza';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Estado de Salud
                    Text(
                      'Estado de Salud *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<EstadoSalud>(
                      value: _selectedEstadoSalud,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona el estado de salud',
                      ),
                      items: _estadosSalud.map((estado) {
                        return DropdownMenuItem<EstadoSalud>(
                          value: estado,
                          child: Text(estado.estadoNombre),
                        );
                      }).toList(),
                      onChanged: (EstadoSalud? value) {
                        setState(() {
                          _selectedEstadoSalud = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona el estado de salud';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Etapa
                    Text(
                      'Etapa *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Etapa>(
                      value: _selectedEtapa,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona la etapa',
                      ),
                      items: _getFilteredEtapas().map((etapa) {
                        return DropdownMenuItem<Etapa>(
                          value: etapa,
                          child: Text(etapa.etapaNombre),
                        );
                      }).toList(),
                      onChanged: (Etapa? value) {
                        setState(() {
                          _selectedEtapa = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona la etapa';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateAnimal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            192,
                            212,
                            59,
                          ),
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
                                'Actualizar Animal',
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