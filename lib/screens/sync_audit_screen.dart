import 'package:flutter/material.dart';
import '../models/sync_audit_models.dart';
import '../services/database_service.dart';
import '../services/utc_timestamp_helper.dart';

class SyncAuditScreen extends StatefulWidget {
  const SyncAuditScreen({super.key});

  @override
  State<SyncAuditScreen> createState() => _SyncAuditScreenState();
}

class _SyncAuditScreenState extends State<SyncAuditScreen> with TickerProviderStateMixin {
  List<SyncAuditRecord> _auditRecords = [];
  bool _isLoading = true;
  String? _selectedEntityType;
  TabController? _tabController;

  final List<String> _entityTypes = ['Todos', 'Animal', 'PersonalFinca', 'CambiosAnimal'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _entityTypes.length, vsync: this);
    _loadAuditRecords();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadAuditRecords([String? entityType]) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await DatabaseService.getSyncAuditRecords(
        entityType: entityType == 'Todos' ? null : entityType,
        limit: 200,
      );
      
      setState(() {
        _auditRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sync audit records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cleanupOldRecords() async {
    try {
      await DatabaseService.cleanupOldSyncAuditRecords(keepDays: 30);
      _loadAuditRecords(_selectedEntityType);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registros antiguos eliminados (más de 30 días)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cleaning up old records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitácora de Sincronización'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAuditRecords(_selectedEntityType),
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'cleanup') {
                _showCleanupDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cleanup',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 8),
                    Text('Limpiar registros antiguos'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _entityTypes.map((type) => Tab(text: type)).toList(),
          onTap: (index) {
            final entityType = _entityTypes[index];
            _selectedEntityType = entityType;
            _loadAuditRecords(entityType);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _auditRecords.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: _entityTypes.map((type) => _buildAuditList()).toList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sync_alt,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay registros de sincronización',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los registros aparecerán aquí cuando se realicen sincronizaciones',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditList() {
    final filteredRecords = _selectedEntityType == null || _selectedEntityType == 'Todos'
        ? _auditRecords
        : _auditRecords.where((r) => r.entityType == _selectedEntityType).toList();

    if (filteredRecords.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRecords.length,
      itemBuilder: (context, index) {
        final record = filteredRecords[index];
        return _buildAuditCard(record);
      },
    );
  }

  Widget _buildAuditCard(SyncAuditRecord record) {
    final actionIcon = _getActionIcon(record.action);
    final actionColor = _getActionColor(record.action);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  actionIcon,
                  color: actionColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.entityName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.entityType,
                    style: TextStyle(
                      color: actionColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  UtcTimestampHelper.formatDetailed(record.syncTimestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getActionDescription(record.action),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (record.conflictReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Conflicto detectado',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.conflictReason!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (record.resolution != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Resolución: ${record.resolution!}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (record.localTimestamp != null && record.serverTimestamp != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTimestampInfo(
                      'Local',
                      record.localTimestamp!,
                      Icons.smartphone,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimestampInfo(
                      'Servidor',
                      record.serverTimestamp!,
                      Icons.cloud,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampInfo(String label, DateTime timestamp, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            UtcTimestampHelper.formatDetailed(timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(SyncAuditAction action) {
    switch (action) {
      case SyncAuditAction.syncSuccess:
        return Icons.check_circle;
      case SyncAuditAction.syncSkipped:
        return Icons.skip_next;
      case SyncAuditAction.conflictResolved:
        return Icons.merge_type;
      case SyncAuditAction.localNewer:
        return Icons.smartphone;
      case SyncAuditAction.serverNewer:
        return Icons.cloud_download;
    }
  }

  Color _getActionColor(SyncAuditAction action) {
    switch (action) {
      case SyncAuditAction.syncSuccess:
        return Colors.green;
      case SyncAuditAction.syncSkipped:
        return Colors.orange;
      case SyncAuditAction.conflictResolved:
        return Colors.blue;
      case SyncAuditAction.localNewer:
        return Colors.blue;
      case SyncAuditAction.serverNewer:
        return Colors.green;
    }
  }

  String _getActionDescription(SyncAuditAction action) {
    switch (action) {
      case SyncAuditAction.syncSuccess:
        return 'Sincronización exitosa desde el servidor';
      case SyncAuditAction.syncSkipped:
        return 'Sincronización omitida';
      case SyncAuditAction.conflictResolved:
        return 'Conflicto de sincronización resuelto';
      case SyncAuditAction.localNewer:
        return 'Se mantuvo la versión local (más reciente)';
      case SyncAuditAction.serverNewer:
        return 'Se actualizó con la versión del servidor (más reciente)';
    }
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar registros antiguos'),
        content: const Text(
          '¿Está seguro que desea eliminar todos los registros de sincronización '
          'de más de 30 días? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cleanupOldRecords();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}