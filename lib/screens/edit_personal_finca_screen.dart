import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
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
  State<EditPersonalFincaScreen> createState() => _EditPersonalFincaScreenState();
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

      LoggingService.info('Personal finca updated successfully', 'EditPersonalFincaScreen');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empleado actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      LoggingService.error('Error updating personal finca', 'EditPersonalFincaScreen', e);
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
        title: const Text('Editar Empleado'),
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
      body: Column(
        children: [
          // Offline warning banner
          if (_isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange[100],
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo offline. Los cambios se sincronizarán cuando tengas conexión.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with farm info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 192, 212, 59),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Finca',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.finca.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                          backgroundColor: const Color.fromARGB(255, 192, 212, 59),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                                'Actualizar Empleado',
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
          ),
        ],
      ),
    );
  }
}