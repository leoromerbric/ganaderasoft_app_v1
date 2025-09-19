import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'create_lactancia_screen.dart';

class LactanciaListScreen extends StatefulWidget {
  final Finca finca;
  final List<Animal> animales;
  final Animal? selectedAnimal;

  const LactanciaListScreen({
    super.key,
    required this.finca,
    required this.animales,
    this.selectedAnimal,
  });

  @override
  State<LactanciaListScreen> createState() => _LactanciaListScreenState();
}

class _LactanciaListScreenState extends State<LactanciaListScreen> {
  final _authService = AuthService();
  List<Lactancia> _lactancias = [];
  List<Lactancia> _filteredLactancias = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _dataSourceMessage;
  Animal? _selectedAnimal;
  List<Animal> _animales = [];
  String _selectedStatus = 'todas'; // 'todas', 'activas', 'finalizadas'

  @override
  void initState() {
    super.initState();
    _selectedAnimal = widget.selectedAnimal;
    _animales = widget.animales;
    _checkConnectivity();
    _loadLactancias();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadLactancias() async {
    try {
      LoggingService.info(
        'Loading lactancias for finca ${widget.finca.idFinca}',
        'LactanciaListScreen',
      );

      setState(() {
        _isLoading = true;
        _error = null;
        _dataSourceMessage = null;
      });

      await _checkConnectivity();

      // Determine activa parameter based on selected status
      int? activaParam;
      if (_selectedStatus == 'activas') {
        activaParam = 1;
      } else if (_selectedStatus == 'finalizadas') {
        activaParam = 0;
      }
      // If 'todas', leave activaParam as null to get all lactations

      final lactanciaResponse = await _authService.getLactancia(
        animalId: _selectedAnimal?.idAnimal,
        activa: activaParam,
        fechaInicio: '2023-01-01',
        fechaFin: DateTime.now()
            .add(const Duration(days: 365))
            .toIso8601String()
            .split('T')[0],
      );

      LoggingService.info(
        'Lactancias loaded successfully (${lactanciaResponse.data.length} items)',
        'LactanciaListScreen',
      );

      setState(() {
        _lactancias = lactanciaResponse.data;
        _isLoading = false;
        _dataSourceMessage = lactanciaResponse.message;

        _applyFilters();
      });
    } catch (e) {
      LoggingService.error(
        'Error loading lactancias',
        'LactanciaListScreen',
        e,
      );
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredLactancias = _lactancias;

    // First, filter by finca animals (only show lactations for animals that belong to this finca)
    final fincaAnimalIds = _animales.map((animal) => animal.idAnimal).toSet();
    _filteredLactancias = _filteredLactancias
        .where(
          (lactancia) => fincaAnimalIds.contains(lactancia.lactanciaEtapaAnid),
        )
        .toList();

    // Apply animal filter if one is selected
    if (_selectedAnimal != null) {
      _filteredLactancias = _filteredLactancias
          .where(
            (lactancia) =>
                lactancia.lactanciaEtapaAnid == _selectedAnimal!.idAnimal,
          )
          .toList();
    }

    // Apply status filter if not showing all
    if (_selectedStatus == 'activas') {
      _filteredLactancias = _filteredLactancias
          .where((lactancia) => _isLactanciaActive(lactancia))
          .toList();
    } else if (_selectedStatus == 'finalizadas') {
      _filteredLactancias = _filteredLactancias
          .where((lactancia) => !_isLactanciaActive(lactancia))
          .toList();
    }

    // Sort by start date descending (most recent first)
    _filteredLactancias.sort(
      (a, b) => DateTime.parse(
        b.lactanciaFechaInicio,
      ).compareTo(DateTime.parse(a.lactanciaFechaInicio)),
    );
  }

  void _filterByAnimal(Animal? animal) {
    setState(() {
      _selectedAnimal = animal;
      _applyFilters();
    });
  }

  void _filterByStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadLactancias(); // Reload data with new status filter
  }

  String _getEmptyStateTitle() {
    switch (_selectedStatus) {
      case 'activas':
        return 'No hay lactancias activas';
      case 'finalizadas':
        return 'No hay lactancias finalizadas';
      default:
        return 'No hay lactancias registradas';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedStatus) {
      case 'activas':
        return 'No se encontraron lactancias en curso';
      case 'finalizadas':
        return 'No se encontraron lactancias terminadas';
      default:
        return 'Agrega el primer período de lactancia';
    }
  }

  String _getCountDisplayText() {
    final count = _filteredLactancias.length;
    final plural = count != 1;

    String statusText = '';
    switch (_selectedStatus) {
      case 'activas':
        statusText = ' activa${plural ? 's' : ''}';
        break;
      case 'finalizadas':
        statusText = ' finalizada${plural ? 's' : ''}';
        break;
      default:
        statusText = '';
    }

    return '$count lactancia${plural ? 's' : ''}$statusText${plural ? ' encontradas' : ' encontrada'}';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getAnimalName(int animalId) {
    try {
      final animal = _animales.firstWhere((a) => a.idAnimal == animalId);
      return animal.nombre;
    } catch (e) {
      return 'Animal #$animalId';
    }
  }

  bool _isLactanciaActive(Lactancia lactancia) {
    return lactancia.lactanciaFechaFin == null;
  }

  int _getLactanciaDuration(Lactancia lactancia) {
    final startDate = DateTime.parse(lactancia.lactanciaFechaInicio);
    final endDate = lactancia.lactanciaFechaFin != null
        ? DateTime.parse(lactancia.lactanciaFechaFin!)
        : DateTime.now();
    return endDate.difference(startDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedAnimal != null
                  ? 'Lactancias de ${_selectedAnimal!.nombre}'
                  : 'Lactancias',
            ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar lactancias',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadLactancias,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Data source info banner
                if (_dataSourceMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(16).copyWith(bottom: 8),
                    decoration: BoxDecoration(
                      color: _isOffline
                          ? Colors.orange[100]
                          : Color.fromARGB(255, 192, 212, 59),
                      border: Border.all(
                        color: _isOffline
                            ? Colors.orange
                            : Color.fromARGB(255, 192, 212, 59),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isOffline ? Icons.cloud_off : Icons.cloud_done,
                          color: _isOffline
                              ? Colors.orange[800]
                              : Colors.green[800],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dataSourceMessage!,
                            style: TextStyle(
                              color: _isOffline
                                  ? Colors.orange[800]
                                  : Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Filter section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      // Status filter
                      Row(
                        children: [
                          const Icon(Icons.filter_alt, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                hintText: 'Filtrar por estado',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem<String>(
                                  value: 'todas',
                                  child: Text('Todas las lactancias'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'activas',
                                  child: Text('Lactancias activas'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'finalizadas',
                                  child: Text('Lactancias finalizadas'),
                                ),
                              ],
                              onChanged: (String? value) {
                                if (value != null) {
                                  _filterByStatus(value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      // Animal filter (only show if there are animals)
                      if (_animales.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.pets, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<Animal?>(
                                value: _selectedAnimal,
                                decoration: const InputDecoration(
                                  hintText: 'Filtrar por animal',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<Animal?>(
                                    value: null,
                                    child: Text('Todos los animales'),
                                  ),
                                  ..._animales.map((animal) {
                                    return DropdownMenuItem<Animal>(
                                      value: animal,
                                      child: Text(
                                        '${animal.nombre} (${animal.codigoAnimal})',
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: _filterByAnimal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Count info
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_drink,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getCountDisplayText(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _filteredLactancias.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_drink,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getEmptyStateTitle(),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getEmptyStateSubtitle(),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadLactancias,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredLactancias.length,
                            itemBuilder: (context, index) {
                              final lactancia = _filteredLactancias[index];
                              return _buildLactanciaCard(lactancia);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_animales.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No hay animales disponibles. Crea un animal primero.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateLactanciaScreen(
                finca: widget.finca,
                animales: _animales,
                selectedAnimal: _selectedAnimal,
              ),
            ),
          );

          if (result == true) {
            _loadLactancias();
          }
        },
        backgroundColor: const Color.fromARGB(255, 192, 212, 59),
        tooltip: 'Agregar lactancia',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLactanciaCard(Lactancia lactancia) {
    final isActive = _isLactanciaActive(lactancia);
    final duration = _getLactanciaDuration(lactancia);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animal name and status
            Row(
              children: [
                Icon(
                  Icons.local_drink,
                  color: isActive ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAnimalName(lactancia.lactanciaEtapaAnid),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Inicio: ${_formatDate(lactancia.lactanciaFechaInicio)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isActive ? 'Activa' : 'Finalizada',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Duration and end date
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Duración',
                    '$duration días',
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: lactancia.lactanciaFechaFin != null
                      ? _buildInfoChip(
                          'Fin',
                          _formatDate(lactancia.lactanciaFechaFin!),
                          Icons.event_busy,
                          Colors.red,
                        )
                      : _buildInfoChip(
                          'Estado',
                          'En curso',
                          Icons.play_arrow,
                          Colors.green,
                        ),
                ),
              ],
            ),

            // Secado info if available
            if (lactancia.lactanciaSecado != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secado: ${lactancia.lactanciaSecado}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            // Footer with created date
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Registrado: ${_formatDate(lactancia.createdAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
