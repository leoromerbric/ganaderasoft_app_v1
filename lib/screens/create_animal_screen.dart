import 'package:flutter/material.dart';
import 'package:ganaderasoft_app_v1/constants/app_constants.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/configuration_models.dart';
import '../services/auth_service.dart';
import '../services/configuration_service.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';

class CreateAnimalScreen extends StatefulWidget {
  final Finca finca;
  final List<Rebano> rebanos;
  final Rebano? selectedRebano;

  const CreateAnimalScreen({
    super.key,
    required this.finca,
    required this.rebanos,
    this.selectedRebano,
  });

  @override
  State<CreateAnimalScreen> createState() => _CreateAnimalScreenState();
}

class _CreateAnimalScreenState extends State<CreateAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Form controllers
  final _nombreController = TextEditingController();
  final _codigoAnimalController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _procedenciaController = TextEditingController();

  // Form data
  final String _procedencia = '';
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

  // Data lists
  List<Rebano> _rebanos = [];
  List<ComposicionRaza> _composicionRaza = [];
  List<EstadoSalud> _estadosSalud = [];
  List<Etapa> _etapas = [];
  List<TipoAnimal> _tiposAnimal = [];
  final List<String> _sexoOptions = ['M', 'F'];

  @override
  void initState() {
    super.initState();
    _rebanos = widget.rebanos;
    _selectedRebano = widget.selectedRebano;
    _procedenciaController.text =
        _procedencia; // Initialize controller with default value
    _checkConnectivity();
    _loadConfigurationData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoAnimalController.dispose();
    _fechaNacimientoController.dispose();
    _procedenciaController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadConfigurationData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      // Load all configuration data
      await Future.wait([
        _loadComposicionRaza(),
        _loadEstadosSalud(),
        _loadEtapas(),
        _loadTiposAnimal(),
      ]);

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      LoggingService.error(
        'Error loading configuration data',
        'CreateAnimalScreen',
        e,
      );
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos de configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadComposicionRaza() async {
    try {
      if (_isOffline) {
        final composicionRaza =
            await DatabaseService.getComposicionRazaOffline();
        setState(() {
          _composicionRaza = composicionRaza;
        });
      } else {
        final response = await ConfigurationService.getComposicionRaza();
        setState(() {
          _composicionRaza = response.data.data;
        });
      }
    } catch (e) {
      LoggingService.error(
        'Error loading composicion raza',
        'CreateAnimalScreen',
        e,
      );
      // Try offline fallback
      final composicionRaza = await DatabaseService.getComposicionRazaOffline();
      setState(() {
        _composicionRaza = composicionRaza;
      });
    }
  }

  Future<void> _loadEstadosSalud() async {
    try {
      if (_isOffline) {
        final estadosSalud = await DatabaseService.getEstadosSaludOffline();
        setState(() {
          _estadosSalud = estadosSalud;
        });
      } else {
        final response = await ConfigurationService.getEstadosSalud();
        setState(() {
          _estadosSalud = response.data.data;
        });
      }
    } catch (e) {
      LoggingService.error(
        'Error loading estados salud',
        'CreateAnimalScreen',
        e,
      );
      // Try offline fallback
      final estadosSalud = await DatabaseService.getEstadosSaludOffline();
      setState(() {
        _estadosSalud = estadosSalud;
      });
    }
  }

  Future<void> _loadEtapas() async {
    try {
      if (_isOffline) {
        final etapas = await DatabaseService.getEtapasOffline();
        setState(() {
          _etapas = etapas;
        });
      } else {
        final etapas = await ConfigurationService.getEtapas();
        setState(() {
          _etapas = etapas;
        });
      }
    } catch (e) {
      LoggingService.error('Error loading etapas', 'CreateAnimalScreen', e);
      // Try offline fallback
      final etapas = await DatabaseService.getEtapasOffline();
      setState(() {
        _etapas = etapas;
      });
    }
  }

  Future<void> _loadTiposAnimal() async {
    try {
      if (_isOffline) {
        final tiposAnimal = await DatabaseService.getTiposAnimalOffline();
        setState(() {
          _tiposAnimal = tiposAnimal;
        });
      } else {
        final response = await ConfigurationService.getTiposAnimal();
        setState(() {
          _tiposAnimal = response.data.data;
        });
      }
    } catch (e) {
      LoggingService.error(
        'Error loading tipos animal',
        'CreateAnimalScreen',
        e,
      );
      // Try offline fallback
      final tiposAnimal = await DatabaseService.getTiposAnimalOffline();
      setState(() {
        _tiposAnimal = tiposAnimal;
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
        _fechaNacimientoController.text = _formatDateForInput(picked);
      });
    }
  }

  String _formatDateForInput(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Etapa> _getFilteredEtapas() {
    if (_selectedSexo == null || _selectedTipoAnimal == null) return [];

    // Convert F to H for API filtering
    String sexoForFiltering = _selectedSexo == 'F' ? 'H' : _selectedSexo!;

    return _etapas
        .where(
          (etapa) =>
              etapa.etapaSexo == sexoForFiltering &&
              etapa.etapaFkTipoAnimalId == _selectedTipoAnimal!.tipoAnimalId,
        )
        .toList();
  }

  Future<void> _createAnimal() async {
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
      if (_isOffline) {
        // Save locally for later sync
        await DatabaseService.savePendingAnimalOffline(
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
              content: Text(
                'Guardado en modo offline. Se sincronizará cuando tengas conexión.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Create online as usual
        final animal = await _authService.createAnimal(
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
              content: Text('Guardado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(animal);
        }
      }
    } catch (e) {
      LoggingService.error('Error creating animal', 'CreateAnimalScreen', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear animal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crear Animal'),
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
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rebaño
                    Text(
                      'Rebaño *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Rebano>(
                      initialValue: _selectedRebano,
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
                      initialValue: _selectedTipoAnimal,
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
                        hintText: 'YYYY-MM-DD',
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
                        hintText: 'Ingresa la procedencia del animal',
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
                      items: _composicionRaza.map((composicion) {
                        return DropdownMenuItem<ComposicionRaza>(
                          value: composicion,
                          child: Text(
                            '${composicion.nombre} (${composicion.siglas})',
                          ),
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
                          child: Text(
                            '${etapa.etapaNombre} (${etapa.etapaEdadIni}-${etapa.etapaEdadFin ?? "∞"} días)',
                          ),
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
                        onPressed: _isLoading ? null : _createAnimal,
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
