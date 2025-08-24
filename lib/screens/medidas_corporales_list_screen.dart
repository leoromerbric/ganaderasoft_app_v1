import 'package:flutter/material.dart';
import '../models/finca.dart';
import '../models/farm_management_models.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/logging_service.dart';
import 'create_medidas_corporales_screen.dart';

class MedidasCorporalesListScreen extends StatefulWidget {
  final Finca finca;

  const MedidasCorporalesListScreen({
    super.key,
    required this.finca,
  });

  @override
  State<MedidasCorporalesListScreen> createState() => _MedidasCorporalesListScreenState();
}

class _MedidasCorporalesListScreenState extends State<MedidasCorporalesListScreen> {
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;
  String? _dataSourceMessage;
  List<MedidasCorporales> _medidasCorporales = [];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadMedidasCorporales();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityService.isConnected();
    setState(() {
      _isOffline = !isConnected;
      _dataSourceMessage = _isOffline
          ? 'Mostrando datos guardados localmente'
          : 'Mostrando datos sincronizados';
    });
  }

  Future<void> _loadMedidasCorporales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // This would need to be implemented in AuthService
      // For now, create an empty response
      setState(() {
        _medidasCorporales = [];
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.error('Error loading medidas corporales', 'MedidasCorporalesListScreen', e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medidas Corporales'),
            Text(
              widget.finca.nombre,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Sin conexión',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_dataSourceMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _isOffline ? Colors.orange[50] : Colors.green[50],
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
          Expanded(child: _buildMedidasCorporalesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMedidasCorporalesScreen(finca: widget.finca),
            ),
          );

          if (result != null) {
            // Refresh the list
            _loadMedidasCorporales();
          }
        },
        tooltip: 'Registrar Medidas Corporales',
        backgroundColor: const Color.fromARGB(255, 192, 212, 59),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMedidasCorporalesList() {
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
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar medidas corporales',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMedidasCorporales,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_medidasCorporales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.straighten,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay medidas corporales registradas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Las medidas corporales aparecerán aquí cuando sean registradas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedidasCorporales,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _medidasCorporales.length,
        itemBuilder: (context, index) {
          final medida = _medidasCorporales[index];
          return _buildMedidaCard(medida);
        },
      ),
    );
  }

  Widget _buildMedidaCard(MedidasCorporales medida) {
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
                  Icons.straighten,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Medida #${medida.idMedida}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animal info
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
                'Animal ID: ${medida.medidaEtapaAnid} - Etapa ID: ${medida.medidaEtapaEtid}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Measurements grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildMeasurementTile('Altura HC', '${medida.alturaHC} cm', Icons.height),
                _buildMeasurementTile('Altura HG', '${medida.alturaHG} cm', Icons.height),
                _buildMeasurementTile('Perímetro PT', '${medida.perimetroPT} cm', Icons.circle_outlined),
                _buildMeasurementTile('Perímetro PCA', '${medida.perimetroPCA} cm', Icons.circle_outlined),
                _buildMeasurementTile('Longitud LC', '${medida.longitudLC} cm', Icons.straighten),
                _buildMeasurementTile('Longitud LG', '${medida.longitudLG} cm', Icons.straighten),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Anchura AG', '${medida.anchuraAG} cm'),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.blue[700],
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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