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
  State<RegistrosLecheListScreen> createState() => _RegistrosLecheListScreenState();
}

class _RegistrosLecheListScreenState extends State<RegistrosLecheListScreen> {
  final _authService = AuthService();
  List<Animal> _femaleAnimals = [];
  Map<int, List<Lactancia>> _animalLactancias = {};
  Map<int, List<RegistroLechero>> _lactanciaRegistros = {};
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _dataSourceMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Filter to only female animals
    _femaleAnimals = widget.animales.where((animal) => animal.sexo.toLowerCase() == 'hembra').toList();
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

      // Load lactancias for each female animal
      for (final animal in _femaleAnimals) {
        try {
          final lactanciaResponse = await _authService.getLactancia(
            animalId: animal.idAnimal,
          );
          _animalLactancias[animal.idAnimal] = lactanciaResponse.data;

          // Load milk records for each lactancia
          for (final lactancia in lactanciaResponse.data) {
            try {
              final lecheResponse = await _authService.getRegistroLechero(
                lactanciaId: lactancia.lactanciaId,
              );
              _lactanciaRegistros[lactancia.lactanciaId] = lecheResponse.data;
            } catch (e) {
              LoggingService.error('Error loading milk records for lactancia ${lactancia.lactanciaId}', 'RegistrosLecheListScreen', e);
              _lactanciaRegistros[lactancia.lactanciaId] = [];
            }
          }
        } catch (e) {
          LoggingService.error('Error loading lactancias for animal ${animal.idAnimal}', 'RegistrosLecheListScreen', e);
          _animalLactancias[animal.idAnimal] = [];
        }
      }

      LoggingService.info('Milk records data loaded successfully', 'RegistrosLecheListScreen');
    } catch (e) {
      LoggingService.error('Error loading milk records data', 'RegistrosLecheListScreen', e);
      setState(() {
        _error = e.toString();
      });
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
        title: const Text('Registros de Leche'),
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
          // Farm info card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.agriculture,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.finca.nombre,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Registros de producción de leche',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_dataSourceMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _dataSourceMessage!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _isOffline ? Colors.orange[700] : Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar datos',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _femaleAnimals.isEmpty
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
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Solo las hembras pueden tener registros de leche',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _femaleAnimals.length,
                              itemBuilder: (context, index) {
                                final animal = _femaleAnimals[index];
                                final lactancias = _animalLactancias[animal.idAnimal] ?? [];
                                return _buildAnimalCard(animal, lactancias);
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
              ),
            ),
          );

          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal, List<Lactancia> lactancias) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            animal.nombre.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          animal.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Código: ${animal.codigoAnimal} • ${lactancias.length} lactancia${lactancias.length != 1 ? 's' : ''}'),
        children: lactancias.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay lactancias registradas para este animal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ]
            : lactancias.map((lactancia) => _buildLactanciaCard(animal, lactancia)).toList(),
      ),
    );
  }

  Widget _buildLactanciaCard(Animal animal, Lactancia lactancia) {
    final registros = _lactanciaRegistros[lactancia.lactanciaId] ?? [];
    final fechaInicio = DateTime.parse(lactancia.lactanciaFechaInicio).toLocal();
    final fechaFin = lactancia.lactanciaFechaFin != null ? DateTime.parse(lactancia.lactanciaFechaFin!).toLocal() : null;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ExpansionTile(
        leading: Icon(
          Icons.local_drink,
          color: fechaFin == null ? Colors.green : Colors.grey,
        ),
        title: Text(
          'Lactancia ${lactancia.lactanciaId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inicio: ${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}'),
            if (fechaFin != null)
              Text('Fin: ${fechaFin.day}/${fechaFin.month}/${fechaFin.year}'),
            Text('${registros.length} registro${registros.length != 1 ? 's' : ''} de leche'),
          ],
        ),
        children: registros.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay registros de leche para esta lactancia',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ]
            : registros.map((registro) => _buildRegistroCard(registro)).toList(),
      ),
    );
  }

  Widget _buildRegistroCard(RegistroLechero registro) {
    final fechaPesaje = DateTime.parse(registro.lecheFechaPesaje).toLocal();
    
    return ListTile(
      leading: const Icon(Icons.scale, color: Colors.blue),
      title: Text('${registro.lechePesajeTotal} litros'),
      subtitle: Text('${fechaPesaje.day}/${fechaPesaje.month}/${fechaPesaje.year}'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}