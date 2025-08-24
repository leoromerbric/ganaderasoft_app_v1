import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'create_peso_corporal_screen.dart';

class PesoCorporalListScreen extends StatefulWidget {
  final Finca finca;
  final List<Animal> animales;
  final Animal? selectedAnimal;

  const PesoCorporalListScreen({
    super.key,
    required this.finca,
    required this.animales,
    this.selectedAnimal,
  });

  @override
  State<PesoCorporalListScreen> createState() => _PesoCorporalListScreenState();
}

class _PesoCorporalListScreenState extends State<PesoCorporalListScreen> {
  final _authService = AuthService();
  List<PesoCorporal> _pesos = [];
  List<PesoCorporal> _filteredPesos = [];
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
    _loadPesos();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadPesos() async {
    try {
      LoggingService.info(
        'Loading peso corporal for finca ${widget.finca.idFinca}',
        'PesoCorporalListScreen',
      );

      setState(() {
        _isLoading = true;
        _error = null;
        _dataSourceMessage = null;
      });

      await _checkConnectivity();

      final pesosResponse = await _authService.getPesoCorporal(
        animalId: _selectedAnimal?.idAnimal,
        fechaInicio: '2023-01-01',
        fechaFin: DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
      );

      LoggingService.info(
        'Peso corporal loaded successfully (${pesosResponse.data.length} items)',
        'PesoCorporalListScreen',
      );

      setState(() {
        _pesos = pesosResponse.data;
        _isLoading = false;
        _dataSourceMessage = pesosResponse.message;

        // Apply animal filter if one is selected
        if (_selectedAnimal != null) {
          _filteredPesos = _pesos
              .where((peso) => peso.pesoEtapaAnid == _selectedAnimal!.idAnimal)
              .toList();
        } else {
          _filteredPesos = _pesos;
        }

        // Sort by date descending (most recent first)
        _filteredPesos.sort((a, b) => DateTime.parse(b.fechaPeso).compareTo(DateTime.parse(a.fechaPeso)));
      });
    } catch (e) {
      LoggingService.error('Error loading peso corporal', 'PesoCorporalListScreen', e);
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
        _filteredPesos = _pesos;
      } else {
        _filteredPesos = _pesos
            .where((peso) => peso.pesoEtapaAnid == animal.idAnimal)
            .toList();
      }
      
      // Sort by date descending
      _filteredPesos.sort((a, b) => DateTime.parse(b.fechaPeso).compareTo(DateTime.parse(a.fechaPeso)));
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

  Color _getPesoTrendColor(int index) {
    if (index == _filteredPesos.length - 1) return Colors.grey; // No previous weight to compare
    
    final currentWeight = _filteredPesos[index].peso;
    final previousWeight = _filteredPesos[index + 1].peso;
    
    if (currentWeight > previousWeight) return Colors.green;
    if (currentWeight < previousWeight) return Colors.red;
    return Colors.grey;
  }

  IconData _getPesoTrendIcon(int index) {
    if (index == _filteredPesos.length - 1) return Icons.circle; // No previous weight to compare
    
    final currentWeight = _filteredPesos[index].peso;
    final previousWeight = _filteredPesos[index + 1].peso;
    
    if (currentWeight > previousWeight) return Icons.trending_up;
    if (currentWeight < previousWeight) return Icons.trending_down;
    return Icons.trending_flat;
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
                  ? 'Peso de ${_selectedAnimal!.nombre}'
                  : 'Peso Corporal',
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
                    'Error al cargar pesos',
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
                    onPressed: _loadPesos,
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
                      Icon(Icons.monitor_weight, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${_filteredPesos.length} peso${_filteredPesos.length != 1 ? 's' : ''} registrado${_filteredPesos.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _filteredPesos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monitor_weight,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay pesos registrados',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agrega el primer registro de peso',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPesos,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredPesos.length,
                            itemBuilder: (context, index) {
                              final peso = _filteredPesos[index];
                              return _buildPesoCard(peso, index);
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
              builder: (context) => CreatePesoCorporalScreen(
                finca: widget.finca,
                animales: _animales,
                selectedAnimal: _selectedAnimal,
              ),
            ),
          );

          if (result == true) {
            _loadPesos();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar peso',
      ),
    );
  }

  Widget _buildPesoCard(PesoCorporal peso, int index) {
    final trendColor = _getPesoTrendColor(index);
    final trendIcon = _getPesoTrendIcon(index);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animal name and date
            Row(
              children: [
                Icon(
                  Icons.monitor_weight,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAnimalName(peso.pesoEtapaAnid),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(peso.fechaPeso),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Weight with trend indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendIcon,
                        color: trendColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${peso.peso} kg',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Comment
            if (peso.comentario.isNotEmpty) ...[
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
                      peso.comentario,
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
                  'Registrado: ${_formatDate(peso.createdAt)}',
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
}