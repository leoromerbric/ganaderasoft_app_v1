import 'package:flutter/material.dart';
import 'package:ganaderasoft_app_v1/constants/app_constants.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_service.dart';
import '../services/logging_service.dart';

class EditPersonalFincaScreen extends StatefulWidget {
  final Finca finca;
  final PersonalFinca personal;

  const EditPersonalFincaScreen({
    super.key,
    required this.finca,
    required this.personal,
  });

  @override
  State<EditPersonalFincaScreen> createState() =>
      _EditPersonalFincaScreenState();
}

class _EditPersonalFincaScreenState extends State<EditPersonalFincaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Form controllers
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  // Form data
  String? _selectedTipoTrabajador;

  // Loading states
  bool _isLoading = false;
  bool _isOffline = false;

  // Options
  final List<String> _tiposTrabajador = [
    'Administrador',
    'Veterinario',
    'Tecnico',
    'Vigilante',
    'Operario',
    'Supervisor',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _checkConnectivity();
  }

  void _initializeFormData() {
    // Pre-fill form with existing data
    _cedulaController.text = widget.personal.cedula.toString();
    _nombreController.text = widget.personal.nombre;
    _apellidoController.text = widget.personal.apellido;
    _telefonoController.text = widget.personal.telefono;
    _correoController.text = widget.personal.correo;
    _selectedTipoTrabajador = widget.personal.tipoTrabajador;
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _updatePersonalFinca() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTipoTrabajador == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona el tipo de trabajador'),
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
        // Save the personal finca update offline
        await DatabaseService.savePendingPersonalFincaUpdateOffline(
          idTecnico: widget.personal.idTecnico,
          idFinca: widget.finca.idFinca,
          cedula: int.parse(_cedulaController.text),
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(),
          telefono: _telefonoController.text.trim(),
          correo: _correoController.text.trim(),
          tipoTrabajador: _selectedTipoTrabajador!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Actualizado en modo offline. Se sincronizará cuando tengas conexión.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pop(context, true);
        }
        return;
      }

      // Update online
      final updatedPersonal = PersonalFinca(
        idTecnico: widget.personal.idTecnico,
        idFinca: widget.finca.idFinca,
        cedula: int.parse(_cedulaController.text),
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        telefono: _telefonoController.text,
        correo: _correoController.text,
        tipoTrabajador: _selectedTipoTrabajador!,
        createdAt: widget.personal.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );

      LoggingService.info('Updating personal finca', 'EditPersonalFincaScreen');
      await _authService.updatePersonalFinca(updatedPersonal);

      LoggingService.info(
        'Personal finca updated successfully',
        'EditPersonalFincaScreen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualizado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      LoggingService.error(
        'Error updating personal finca',
        'EditPersonalFincaScreen',
        e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar empleado: ${e.toString()}'),
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
            const Text('Editar Empleado'),
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
      body: Column(
        children: [
          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form fields
                    // Cedula
                    Text(
                      'Cédula *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cedulaController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingresa el número de cédula',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la cédula';
                        }
                        if (int.tryParse(value) == null) {
                          return 'La cédula debe ser un número válido';
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
                        hintText: 'Ingresa el nombre',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre';
                        }
                        if (value.length < 2) {
                          return 'El nombre debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Apellido
                    Text(
                      'Apellido *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _apellidoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingresa el apellido',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el apellido';
                        }
                        if (value.length < 2) {
                          return 'El apellido debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Telefono
                    Text(
                      'Teléfono *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingresa el número de teléfono',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el teléfono';
                        }
                        if (value.length < 10) {
                          return 'El teléfono debe tener al menos 10 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Correo
                    Text(
                      'Correo Electrónico *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _correoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingresa el correo electrónico',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el correo electrónico';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Por favor ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tipo Trabajador
                    Text(
                      'Tipo de Trabajador *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTipoTrabajador,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Selecciona el tipo de trabajador',
                        prefixIcon: Icon(Icons.work),
                      ),
                      items: _tiposTrabajador.map((String tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTipoTrabajador = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor selecciona el tipo de trabajador';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updatePersonalFinca,
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
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Actualizar',
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
          ),
        ],
      ),
    );
  }
}
