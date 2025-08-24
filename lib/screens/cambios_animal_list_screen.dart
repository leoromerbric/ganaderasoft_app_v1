import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'create_cambio_animal_screen.dart';

class CambiosAnimalListScreen extends StatefulWidget {
  final Finca finca;

  const CambiosAnimalListScreen({
    super.key,
    required this.finca,
  });

  @override
  State<CambiosAnimalListScreen> createState() => _CambiosAnimalListScreenState();
}

class _CambiosAnimalListScreenState extends State<CambiosAnimalListScreen> {
  final _authService = AuthService();
  List<CambioAnimal> _cambiosAnimal = [];
  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;
  String? _dataSourceMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadCambiosAnimal();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  Future<void> _loadCambiosAnimal() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cambiosResponse = await _authService.getCambiosAnimal(
        fincaId: widget.finca.idFinca,
      );

      setState(() {
        _cambiosAnimal = cambiosResponse.cambiosAnimal;
        _isLoading = false;
        _dataSourceMessage = _isOffline 
            ? 'Datos desde caché local (sin conexión)'
            : 'Datos actualizados desde el servidor';
      });

      LoggingService.info(
        'Cambios animal loaded successfully (${_cambiosAnimal.length} items)',
        'CambiosAnimalListScreen',
      );
    } catch (e) {
      LoggingService.error('Error loading cambios animal', 'CambiosAnimalListScreen', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
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
        title: const Text('Cambios de Animales'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status indicator
          if (_dataSourceMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _isOffline ? Colors.orange[100] : Colors.green[100],
              child: Row(
                children: [
                  Icon(
                    _isOffline ? Icons.cloud_off : Icons.cloud_done,
                    size: 16,
                    color: _isOffline
                        ? Colors.orange[700]
                        : Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dataSourceMessage!,
                      style: TextStyle(
                        fontSize: 12,
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
          Expanded(child: _buildCambiosAnimalList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateCambioAnimalScreen(finca: widget.finca),
            ),
          );

          if (result != null) {
            // Refresh the list
            _loadCambiosAnimal();
          }
        },
        tooltip: 'Registrar Cambio',
        backgroundColor: const Color.fromARGB(255, 192, 212, 59),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCambiosAnimalList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar los cambios',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCambiosAnimal,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_cambiosAnimal.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.change_circle_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay cambios registrados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Los cambios de animales aparecerán aquí cuando sean registrados',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCambiosAnimal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _cambiosAnimal.length,
        itemBuilder: (context, index) {
          final cambio = _cambiosAnimal[index];
          return _buildCambioCard(cambio);
        },
      ),
    );
  }

  Widget _buildCambioCard(CambioAnimal cambio) {
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
                Icon(
                  Icons.change_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cambio.tipoCambio,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(cambio.fechaCambio),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animal info
            if (cambio.animal != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cambio.animal!.nombre} (${cambio.animal!.codigoAnimal})',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Change details
            _buildDetailRow('Valor Anterior', cambio.valorAnterior),
            const SizedBox(height: 8),
            _buildDetailRow('Valor Nuevo', cambio.valorNuevo),
            
            if (cambio.observaciones != null && cambio.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Observaciones', cambio.observaciones!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
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
}