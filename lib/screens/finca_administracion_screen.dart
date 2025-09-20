import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'animales_list_screen.dart';
import 'rebanos_list_screen.dart';
import 'cambios_animal_list_screen.dart';
import 'personal_finca_list_screen.dart';
import 'peso_corporal_list_screen.dart';
import 'lactancia_list_screen.dart';
import 'registros_leche_list_screen.dart';

class FarmDetailsScreen extends StatefulWidget {
  final Finca finca;

  const FarmDetailsScreen({super.key, required this.finca});

  @override
  State<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  final _authService = AuthService();
  bool _isOffline = false;
  List<Rebano> _rebanos = [];
  List<Animal> _animales = [];
  bool _isLoadingRebanos = false;
  bool _isLoadingAnimales = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadData();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadData() async {
    await Future.wait([_loadRebanos(), _loadAnimales()]);
  }

  Future<void> _loadRebanos() async {
    setState(() {
      _isLoadingRebanos = true;
    });

    try {
      final rebanosResponse = await _authService.getRebanos(
        idFinca: widget.finca.idFinca,
      );
      setState(() {
        _rebanos = rebanosResponse.rebanos;
        _isLoadingRebanos = false;
      });
    } catch (e) {
      LoggingService.error('Error loading rebanos', 'FarmDetailsScreen', e);
      setState(() {
        _isLoadingRebanos = false;
      });
    }
  }

  Future<void> _loadAnimales() async {
    setState(() {
      _isLoadingAnimales = true;
    });

    try {
      final animalesResponse = await _authService.getAnimales(
        idFinca: widget.finca.idFinca,
      );
      setState(() {
        _animales = animalesResponse.animales;
        _isLoadingAnimales = false;
      });
    } catch (e) {
      LoggingService.error('Error loading animales', 'FarmDetailsScreen', e);
      setState(() {
        _isLoadingAnimales = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.finca.nombre),
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farm Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.agriculture,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.finca.nombre,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Tipo de Explotación',
                        widget.finca.explotacionTipo,
                        Icons.category,
                      ),
                      if (widget.finca.propietario != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Propietario',
                          '${widget.finca.propietario!.nombre} ${widget.finca.propietario!.apellido}',
                          Icons.person,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Teléfono',
                          widget.finca.propietario!.telefono,
                          Icons.phone,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateInfo(
                              'Creado',
                              _formatDate(widget.finca.createdAt),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateInfo(
                              'Actualizado',
                              _formatDate(widget.finca.updatedAt),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Navigation Section
              Text(
                'Gestión de la Finca',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Navigation Cards
              Row(
                children: [
                  Expanded(
                    child: _buildNavigationCard(
                      context,
                      'Rebaños',
                      Icons.groups,
                      '${_rebanos.length} rebaño${_rebanos.length != 1 ? 's' : ''}',
                      _isLoadingRebanos,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RebanosListScreen(finca: widget.finca),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNavigationCard(
                      context,
                      'Animales',
                      Icons.pets,
                      '${_animales.length} animal${_animales.length != 1 ? 'es' : ''}',
                      _isLoadingAnimales,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimalesListScreen(
                            finca: widget.finca,
                            rebanos: _rebanos,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Additional Management Cards
              Text(
                'Gestión Avanzada',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // First row of management cards
              Row(
                children: [
                  Expanded(
                    child: _buildNavigationCard(
                      context,
                      'Cambios de Animales',
                      Icons.update,
                      'Cambios de etapa',
                      false,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CambiosAnimalListScreen(
                            finca: widget.finca,
                            animales: _animales,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNavigationCard(
                      context,
                      'Peso Corporal',
                      Icons.monitor_weight,
                      'Control de peso',
                      false,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PesoCorporalListScreen(
                            finca: widget.finca,
                            animales: _animales,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Second row of management cards
              Row(
                children: [
                  Expanded(
                    child: _buildNavigationCard(
                      context,
                      'Personal de Finca',
                      Icons.people,
                      'Gestión de empleados',
                      false,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PersonalFincaListScreen(finca: widget.finca),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNavigationCard(
                      context,
                      'Lactancia',
                      Icons.local_drink,
                      'Control de lactancia',
                      false,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LactanciaListScreen(
                            finca: widget.finca,
                            animales: _animales,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Third row of management cards
              Row(
                children: [
                  Expanded(
                    child: _buildNavigationCard(
                      context,
                      'Registros de Leche',
                      Icons.local_drink_outlined,
                      'Control de producción',
                      false,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrosLecheListScreen(
                            finca: widget.finca,
                            animales: _animales,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(), // Empty space for symmetry
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Stats
              if (_rebanos.isNotEmpty || _animales.isNotEmpty) ...[
                Text(
                  'Estadísticas Rápidas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatRow(
                          'Total Rebaños',
                          _rebanos.length.toString(),
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          'Total Animales',
                          _animales.length.toString(),
                        ),
                        if (_animales.isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildStatRow(
                            'Animales Hembras',
                            _animales
                                .where((a) => a.sexo.toUpperCase() == 'F')
                                .length
                                .toString(),
                          ),
                          const Divider(height: 24),
                          _buildStatRow(
                            'Animales Machos',
                            _animales
                                .where((a) => a.sexo.toUpperCase() == 'M')
                                .length
                                .toString(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(date, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    bool isLoading,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isLoading
                    ? Colors.grey[400]
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (isLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
