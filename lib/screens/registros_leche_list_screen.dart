import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/animal.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'create_registro_leche_screen.dart';

class RegistrosLecheListScreen extends StatefulWidget {
  final Finca finca;
  final List<Animal> animales;

  const RegistrosLecheListScreen({
    super.key,
    required this.finca,
    required this.animales,
  });

  @override
  State<RegistrosLecheListScreen> createState() =>
      _RegistrosLecheListScreenState();
}

class _RegistrosLecheListScreenState extends State<RegistrosLecheListScreen> {
  final _authService = AuthService();
  List<Animal> _femaleAnimals = [];
  List<Lactancia> _lactancias = [];
  List<RegistroLechero> _registrosLeche = [];
  List<RegistroLechero> _filteredRegistrosLeche = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _dataSourceMessage;
  Animal? _selectedAnimal;
  Lactancia? _selectedLactancia;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Filter to only female animals
    _femaleAnimals = widget.animales
        .where((animal) => animal.sexo.toLowerCase() == 'f')
        .toList();
    await _loadData();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
      _dataSourceMessage = _isOffline ? 'Datos offline' : 'Datos online';
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _checkConnectivity();

      // Load lactancias for female animals
      _lactancias.clear();
      _registrosLeche.clear();

      for (final animal in _femaleAnimals) {
        try {
          final lactanciaResponse = await _authService.getLactancia(
            animalId: animal.idAnimal,
          );
          _lactancias.addAll(lactanciaResponse.data);
        } catch (e) {
          LoggingService.error(
            'Error loading lactancias for animal ${animal.idAnimal}',
            'RegistrosLecheListScreen',
            e,
          );
        }
      }

      // Load all milk records for all lactancias
      for (final lactancia in _lactancias) {
        try {
          final lecheResponse = await _authService.getRegistroLechero(
            lactanciaId: lactancia.lactanciaId,
          );
          _registrosLeche.addAll(lecheResponse.data);
        } catch (e) {
          LoggingService.error(
            'Error loading milk records for lactancia ${lactancia.lactanciaId}',
            'RegistrosLecheListScreen',
            e,
          );
        }
      }

      setState(() {
        _dataSourceMessage = _isOffline ? 'Datos offline' : 'Datos online';
        _applyFilters();
      });

      LoggingService.info(
        'Milk records data loaded successfully (${_registrosLeche.length} records)',
        'RegistrosLecheListScreen',
      );
    } catch (e) {
      LoggingService.error(
        'Error loading milk records data',
        'RegistrosLecheListScreen',
        e,
      );
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredRegistrosLeche = _registrosLeche;

    // Filter by selected animal
    if (_selectedAnimal != null) {
      final animalLactancias = _lactancias
          .where(
            (lactancia) =>
                lactancia.lactanciaEtapaAnid == _selectedAnimal!.idAnimal,
          )
          .map((lactancia) => lactancia.lactanciaId)
          .toSet();

      _filteredRegistrosLeche = _filteredRegistrosLeche
          .where(
            (registro) => animalLactancias.contains(registro.lecheLactanciaId),
          )
          .toList();
    }

    // Filter by selected lactancia
    if (_selectedLactancia != null) {
      _filteredRegistrosLeche = _filteredRegistrosLeche
          .where(
            (registro) =>
                registro.lecheLactanciaId == _selectedLactancia!.lactanciaId,
          )
          .toList();
    }

    // Sort by date descending (most recent first)
    _filteredRegistrosLeche.sort(
      (a, b) => DateTime.parse(
        b.lecheFechaPesaje,
      ).compareTo(DateTime.parse(a.lecheFechaPesaje)),
    );
  }

  void _filterByAnimal(Animal? animal) {
    setState(() {
      _selectedAnimal = animal;
      _selectedLactancia =
          null; // Reset lactancia selection when animal changes
      _applyFilters();
    });
  }

  void _filterByLactancia(Lactancia? lactancia) {
    setState(() {
      _selectedLactancia = lactancia;
      _applyFilters();
    });
  }

  List<Lactancia> _getAvailableLactancias() {
    if (_selectedAnimal == null) return [];
    return _lactancias
        .where(
          (lactancia) =>
              lactancia.lactanciaEtapaAnid == _selectedAnimal!.idAnimal,
        )
        .toList();
  }

  String _getAnimalName(int animalId) {
    try {
      final animal = _femaleAnimals.firstWhere((a) => a.idAnimal == animalId);
      return animal.nombre;
    } catch (e) {
      return 'Animal #$animalId';
    }
  }

  String _getLactanciaName(int lactanciaId) {
    try {
      final lactancia = _lactancias.firstWhere(
        (l) => l.lactanciaId == lactanciaId,
      );
      final fechaInicio = DateTime.parse(lactancia.lactanciaFechaInicio);
      return 'Lactancia del ${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}';
    } catch (e) {
      return 'Lactancia #$lactanciaId';
    }
  }

  String _getCountDisplayText() {
    final count = _filteredRegistrosLeche.length;
    final plural = count != 1;
    return '$count registro${plural ? 's' : ''} de leche${plural ? ' encontrados' : ' encontrado'}';
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
                  ? 'Registros de ${_selectedAnimal!.nombre}'
                  : 'Registros de Leche',
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
                    'Error al cargar registros',
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
                    onPressed: _loadData,
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
                      // Animal filter
                      if (_femaleAnimals.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.pets, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<Animal?>(
                                initialValue: _selectedAnimal,
                                decoration: const InputDecoration(
                                  hintText: 'Filtrar por animal hembra',
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
                                  ..._femaleAnimals.map((animal) {
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

                        // Lactancia filter (only show if animal is selected)
                        if (_selectedAnimal != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.local_drink, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<Lactancia?>(
                                  initialValue: _selectedLactancia,
                                  decoration: const InputDecoration(
                                    hintText: 'Filtrar por lactancia',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<Lactancia?>(
                                      value: null,
                                      child: Text('Todas las lactancias'),
                                    ),
                                    ..._getAvailableLactancias().map((
                                      lactancia,
                                    ) {
                                      final fechaInicio = DateTime.parse(
                                        lactancia.lactanciaFechaInicio,
                                      );
                                      return DropdownMenuItem<Lactancia>(
                                        value: lactancia,
                                        child: Text(
                                          'Lactancia del ${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}',
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: _filterByLactancia,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                        Icons.scale,
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
                  child: _femaleAnimals.isEmpty
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
                                'No hay animales hembras',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Solo las hembras pueden tener registros de leche',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : _filteredRegistrosLeche.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.scale,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay registros de leche',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedAnimal != null
                                    ? 'No se encontraron registros para los filtros seleccionados'
                                    : 'Agrega el primer registro de producción de leche',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredRegistrosLeche.length,
                            itemBuilder: (context, index) {
                              final registro = _filteredRegistrosLeche[index];
                              return _buildRegistroCard(registro);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_femaleAnimals.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No hay animales hembras disponibles.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRegistroLecheScreen(
                finca: widget.finca,
                animales: _femaleAnimals,
                selectedAnimal: _selectedAnimal,
                selectedLactancia: _selectedLactancia,
              ),
            ),
          );

          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: const Color.fromARGB(255, 192, 212, 59),
        tooltip: 'Agregar registro de leche',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRegistroCard(RegistroLechero registro) {
    final fechaPesaje = DateTime.parse(registro.lecheFechaPesaje).toLocal();
    final animalName = _getAnimalName(
      _lactancias
          .firstWhere((l) => l.lactanciaId == registro.lecheLactanciaId)
          .lactanciaEtapaAnid,
    );
    final lactanciaName = _getLactanciaName(registro.lecheLactanciaId);

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
                  Icons.scale,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animalName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        lactanciaName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Production amount
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: Text(
                    '${registro.lechePesajeTotal} L',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date and details
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Fecha',
                    '${fechaPesaje.day}/${fechaPesaje.month}/${fechaPesaje.year}',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoChip(
                    'Producción',
                    '${registro.lechePesajeTotal} litros',
                    Icons.local_drink,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Footer with created date if available
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Pesaje: ${fechaPesaje.day}/${fechaPesaje.month}/${fechaPesaje.year}',
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
