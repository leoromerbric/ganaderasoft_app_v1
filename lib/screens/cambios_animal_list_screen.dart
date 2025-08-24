import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'create_cambios_animal_screen.dart';

class CambiosAnimalListScreen extends StatefulWidget {
  final Finca finca;
  final List<Animal> animales;
  final Animal? selectedAnimal;

  const CambiosAnimalListScreen({
    super.key,
    required this.finca,
    required this.animales,
    this.selectedAnimal,
  });

  @override
  State<CambiosAnimalListScreen> createState() => _CambiosAnimalListScreenState();
}

class _CambiosAnimalListScreenState extends State<CambiosAnimalListScreen> {
  final _authService = AuthService();
  List<CambiosAnimal> _cambios = [];
  List<CambiosAnimal> _filteredCambios = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _dataSourceMessage;
  Animal? _selectedAnimal;
  List<Animal> _animales = [];

  @override
  void initState() {
    super.initState();
    _selectedAnimal = widget.selectedAnimal;
    _animales = widget.animales;
    _checkConnectivity();
    _loadCambios();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadCambios() async {
    try {
      LoggingService.info(
        'Loading cambios animal for finca ${widget.finca.idFinca}',
        'CambiosAnimalListScreen',
      );

      setState(() {
        _isLoading = true;
        _error = null;
        _dataSourceMessage = null;
      });

      await _checkConnectivity();

      final cambiosResponse = await _authService.getCambiosAnimal(
        animalId: _selectedAnimal?.idAnimal,
        fechaInicio: '2023-01-01',
        fechaFin: DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
      );

      LoggingService.info(
        'Cambios animal loaded successfully (${cambiosResponse.data.length} items)',
        'CambiosAnimalListScreen',
      );

      setState(() {
        _cambios = cambiosResponse.data;
        _isLoading = false;
        _dataSourceMessage = cambiosResponse.message;

        // Apply animal filter if one is selected
        if (_selectedAnimal != null) {
          _filteredCambios = _cambios
              .where((cambio) => cambio.cambiosEtapaAnid == _selectedAnimal!.idAnimal)
              .toList();
        } else {
          _filteredCambios = _cambios;
        }
      });
    } catch (e) {
      LoggingService.error('Error loading cambios animal', 'CambiosAnimalListScreen', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterByAnimal(Animal? animal) {
    setState(() {
      _selectedAnimal = animal;
      if (animal == null) {
        _filteredCambios = _cambios;
      } else {
        _filteredCambios = _cambios
            .where((cambio) => cambio.cambiosEtapaAnid == animal.idAnimal)
            .toList();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedAnimal != null
                  ? 'Cambios de ${_selectedAnimal!.nombre}'
                  : 'Cambios de Animales',
            ),
            Text(
              widget.finca.nombre,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
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
                    'Error al cargar cambios',
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
                    onPressed: _loadCambios,
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
                      color: _isOffline ? Colors.orange[100] : Colors.green[100],
                      border: Border.all(
                        color: _isOffline ? Colors.orange : Colors.green,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isOffline ? Icons.cloud_off : Icons.cloud_done,
                          color: _isOffline ? Colors.orange[800] : Colors.green[800],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dataSourceMessage!,
                            style: TextStyle(
                              color: _isOffline ? Colors.orange[800] : Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Filter section
                if (_animales.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<Animal?>(
                            value: _selectedAnimal,
                            decoration: const InputDecoration(
                              hintText: 'Filtrar por animal',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem<Animal?>(
                                value: null,
                                child: Text('Todos los animales'),
                              ),
                              ..._animales.map((animal) {
                                return DropdownMenuItem<Animal>(
                                  value: animal,
                                  child: Text('${animal.nombre} (${animal.codigoAnimal})'),
                                );
                              }),
                            ],
                            onChanged: _filterByAnimal,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Count info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${_filteredCambios.length} cambio${_filteredCambios.length != 1 ? 's' : ''} encontrado${_filteredCambios.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _filteredCambios.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay cambios registrados',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agrega el primer cambio de animal',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCambios,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredCambios.length,
                            itemBuilder: (context, index) {
                              final cambio = _filteredCambios[index];
                              return _buildCambioCard(cambio);
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
                content: Text('No hay animales disponibles. Crea un animal primero.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateCambiosAnimalScreen(
                finca: widget.finca,
                animales: _animales,
                selectedAnimal: _selectedAnimal,
              ),
            ),
          );

          if (result == true) {
            _loadCambios();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar cambio de animal',
      ),
    );
  }

  Widget _buildCambioCard(CambiosAnimal cambio) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animal name and stage
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAnimalName(cambio.cambiosEtapaAnid),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Etapa: ${cambio.etapaCambio}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDate(cambio.fechaCambio),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Measurements
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementChip(
                    'Peso',
                    '${cambio.peso} kg',
                    Icons.monitor_weight,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementChip(
                    'Altura',
                    '${cambio.altura} cm',
                    Icons.height,
                    Colors.green,
                  ),
                ),
              ],
            ),

            // Comment
            if (cambio.comentario.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.comment,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cambio.comentario,
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
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Registrado: ${_formatDate(cambio.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementChip(String label, String value, IconData icon, Color color) {
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