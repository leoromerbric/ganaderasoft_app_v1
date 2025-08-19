import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'create_animal_screen.dart';

class AnimalesListScreen extends StatefulWidget {
  final Finca finca;
  final List<Rebano> rebanos;
  final Rebano? selectedRebano;

  const AnimalesListScreen({
    super.key,
    required this.finca,
    required this.rebanos,
    this.selectedRebano,
  });

  @override
  State<AnimalesListScreen> createState() => _AnimalesListScreenState();
}

class _AnimalesListScreenState extends State<AnimalesListScreen> {
  final _authService = AuthService();
  List<Animal> _animales = [];
  List<Animal> _filteredAnimales = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _dataSourceMessage;
  Rebano? _selectedRebano;

  @override
  void initState() {
    super.initState();
    _selectedRebano = widget.selectedRebano;
    _checkConnectivity();
    _loadAnimales();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadAnimales() async {
    try {
      LoggingService.info('Loading animales for finca ${widget.finca.idFinca}', 'AnimalesListScreen');
      
      setState(() {
        _isLoading = true;
        _error = null;
        _dataSourceMessage = null;
      });

      await _checkConnectivity();

      final animalesResponse = await _authService.getAnimales(
        idFinca: widget.finca.idFinca,
        idRebano: _selectedRebano?.idRebano,
      );
      
      LoggingService.info('Animales loaded successfully (${animalesResponse.animales.length} items)', 'AnimalesListScreen');
      
      setState(() {
        _animales = animalesResponse.animales;
        _isLoading = false;
        _dataSourceMessage = animalesResponse.message;
        
        // Apply rebano filter if one is selected
        if (_selectedRebano != null) {
          _filteredAnimales = _animales.where((animal) => 
            animal.idRebano == _selectedRebano!.idRebano
          ).toList();
        } else {
          _filteredAnimales = _animales;
        }
      });
    } catch (e) {
      LoggingService.error('Error loading animales', 'AnimalesListScreen', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterByRebano(Rebano? rebano) {
    setState(() {
      _selectedRebano = rebano;
      if (rebano == null) {
        _filteredAnimales = _animales;
      } else {
        _filteredAnimales = _animales.where((animal) => 
          animal.idRebano == rebano.idRebano
        ).toList();
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

  String _getSexoIcon(String sexo) {
    switch (sexo.toUpperCase()) {
      case 'M':
        return '♂';
      case 'F':
        return '♀';
      default:
        return '?';
    }
  }

  Color _getSexoColor(String sexo) {
    switch (sexo.toUpperCase()) {
      case 'M':
        return Colors.blue;
      case 'F':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_selectedRebano != null ? 'Animales de ${_selectedRebano!.nombre}' : 'Animales'),
            Text(
              widget.finca.nombre,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
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
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar animales',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAnimales,
                        child: const Text('Reintentar'),
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
                          color: _isOffline ? Colors.orange[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isOffline ? Colors.orange[200]! : Colors.green[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isOffline ? Icons.cloud_off : Icons.cloud_done,
                              size: 16,
                              color: _isOffline ? Colors.orange[700] : Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _dataSourceMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isOffline ? Colors.orange[800] : Colors.green[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Filter section
                    if (widget.rebanos.isNotEmpty && widget.selectedRebano == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              'Filtrar por rebaño:',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<Rebano?>(
                                value: _selectedRebano,
                                isExpanded: true,
                                hint: const Text('Todos los rebaños'),
                                items: [
                                  const DropdownMenuItem<Rebano?>(
                                    value: null,
                                    child: Text('Todos los rebaños'),
                                  ),
                                  ...widget.rebanos.map((rebano) => DropdownMenuItem<Rebano?>(
                                    value: rebano,
                                    child: Text(rebano.nombre),
                                  )),
                                ],
                                onChanged: _filterByRebano,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (widget.rebanos.isNotEmpty && widget.selectedRebano == null)
                      const SizedBox(height: 8),

                    // Animals list
                    Expanded(
                      child: _filteredAnimales.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.pets,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay animales registrados',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedRebano != null 
                                        ? 'No hay animales en este rebaño'
                                        : 'Los animales de esta finca aparecerán aquí cuando sean registrados',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : _buildAnimalesList(),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_rebanos.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No hay rebaños disponibles. Crea un rebaño primero.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateAnimalScreen(
                finca: widget.finca,
                rebanos: _rebanos,
                selectedRebano: _selectedRebano,
              ),
            ),
          );

          if (result != null) {
            // Refresh the list
            _loadAnimales();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Crear Animal',
      ),
    );
  }

  Widget _buildAnimalesList() {
    return RefreshIndicator(
      onRefresh: _loadAnimales,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _filteredAnimales.length,
        itemBuilder: (context, index) {
          final animal = _filteredAnimales[index];
          return _buildAnimalCard(animal);
        },
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSexoColor(animal.sexo).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _getSexoIcon(animal.sexo),
                    style: TextStyle(
                      color: _getSexoColor(animal.sexo),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.nombre,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Código: ${animal.codigoAnimal}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow('Rebaño', animal.rebano?.nombre ?? 'N/A', Icons.groups),
            const SizedBox(height: 8),
            _buildDetailRow('Procedencia', animal.procedencia, Icons.location_on),
            const SizedBox(height: 8),
            _buildDetailRow('Fecha de Nacimiento', _formatDate(animal.fechaNacimiento), Icons.cake),
            
            if (animal.composicionRaza != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Raza', '${animal.composicionRaza!.nombre} (${animal.composicionRaza!.siglas})', Icons.pets),
              const SizedBox(height: 8),
              _buildDetailRow('Propósito', animal.composicionRaza!.proposito, Icons.flag),
            ],

            const SizedBox(height: 12),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    'Creado',
                    _formatDate(animal.createdAt),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateInfo(
                    'Actualizado',
                    _formatDate(animal.updatedAt),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
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
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
        Text(
          date,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}