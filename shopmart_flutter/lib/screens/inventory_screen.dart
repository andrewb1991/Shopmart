import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    // Carica l'inventario all'avvio con un delay per evitare crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInventorySafely();
      }
    });
  }

  Future<void> _loadInventorySafely() async {
    try {
      await Provider.of<InventoryProvider>(context, listen: false).loadInventory();
    } catch (e) {
      debugPrint('⚠️ Errore durante il caricamento iniziale dell\'inventario: $e');
    }
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.scaduto:
        return Colors.red[100]!;
      case ProductStatus.urgente:
        return Colors.orange[100]!;
      case ProductStatus.attenzione:
        return Colors.yellow[100]!;
      case ProductStatus.ok:
        return Colors.green[100]!;
    }
  }

  Color _getStatusBorderColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.scaduto:
        return Colors.red[300]!;
      case ProductStatus.urgente:
        return Colors.orange[300]!;
      case ProductStatus.attenzione:
        return Colors.yellow[300]!;
      case ProductStatus.ok:
        return Colors.green[300]!;
    }
  }

  IconData _getStatusIcon(ProductStatus status) {
    switch (status) {
      case ProductStatus.scaduto:
      case ProductStatus.urgente:
        return Icons.warning;
      case ProductStatus.attenzione:
        return Icons.warning_amber;
      case ProductStatus.ok:
        return Icons.check_circle;
    }
  }

  Color _getStatusIconColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.scaduto:
      case ProductStatus.urgente:
        return Colors.red;
      case ProductStatus.attenzione:
        return Colors.orange;
      case ProductStatus.ok:
        return Colors.green;
    }
  }

  String _getDaysLeftText(int daysLeft) {
    if (daysLeft == 0) {
      return 'Scade oggi';
    } else if (daysLeft > 0) {
      return 'Giorni rimanenti: $daysLeft';
    } else {
      return 'Scaduto da ${daysLeft.abs()} giorni';
    }
  }

  Future<void> _deleteProduct(String id) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo prodotto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final success = await provider.deleteProduct(id);

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Prodotto eliminato'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'eliminazione'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Magazzino',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<InventoryProvider>(context, listen: false)
                  .loadInventory();
            },
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.inventory.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nessun prodotto nel magazzino',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Inizia ad aggiungere prodotti!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.inventory.length,
            itemBuilder: (context, index) {
              return _buildInventoryItem(provider.inventory[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryItem(InventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(item.status),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusBorderColor(item.status),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Immagine prodotto
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),

          const SizedBox(width: 12),

          // Info prodotto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(item.status),
                      color: _getStatusIconColor(item.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.brand,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scadenza: ${DateFormat('dd/MM/yyyy').format(item.expiryDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDaysLeftText(item.daysLeft),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),

                // Ingredienti collapsable
                if (item.ingredients != null) ...[
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text(
                        'Vedi ingredienti',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.ingredients!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Quantità ed elimina
          Column(
            children: [
              Column(
                children: [
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.unit ?? 'pz',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              IconButton(
                onPressed: () => _deleteProduct(item.id),
                icon: const Icon(Icons.delete),
                color: Colors.red,
                tooltip: 'Elimina',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
