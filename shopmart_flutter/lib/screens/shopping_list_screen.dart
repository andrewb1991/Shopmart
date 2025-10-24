import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Set<String> _selectedItems = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadInventory();
    });
  }

  List<InventoryItem> _getShoppingList(List<InventoryItem> inventory) {
    return inventory.where((item) => item.quantity <= 1).toList();
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }

  Future<void> _shareAsPDF() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno un prodotto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostra indicatore di caricamento
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Generazione PDF in corso...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Ottieni i prodotti selezionati
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final allItems = _getShoppingList(provider.inventory);
      final selectedProducts = allItems
          .where((item) => _selectedItems.contains(item.id))
          .toList();

      // Crea il documento PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Titolo
                pw.Text(
                  'Lista Spesa - Shopmart',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generata il ${DateFormat('dd/MM/yyyy HH:mm', 'it_IT').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 24),

                // Riepilogo
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Prodotti da acquistare: ${selectedProducts.length}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Tabella prodotti
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 1,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildTableCell('Prodotto', isHeader: true),
                        _buildTableCell('Marca', isHeader: true),
                        _buildTableCell('Quantità', isHeader: true),
                        _buildTableCell('✓', isHeader: true),
                      ],
                    ),
                    // Righe prodotti
                    ...selectedProducts.map((item) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(item.productName),
                          _buildTableCell(item.brand),
                          _buildTableCell(
                            item.quantity == 0
                                ? 'Terminato'
                                : '${item.quantity} ${item.unit}',
                          ),
                          _buildTableCell('☐'), // Checkbox vuoto per spuntare
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 24),

                // Footer
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generato con Shopmart - Magazzino Casa',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Genera i bytes del PDF
      final pdfBytes = await pdf.save();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'lista_spesa_$timestamp.pdf';

      // Condividi il PDF direttamente dai bytes usando XFile.fromData
      await Share.shareXFiles(
        [
          XFile.fromData(
            pdfBytes,
            name: fileName,
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'Lista Spesa - Shopmart',
        text: 'Lista spesa generata da Shopmart con ${selectedProducts.length} prodotti',
      );

      if (!mounted) return;

      // Mostra messaggio di successo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('PDF generato e condiviso con successo'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Errore durante la generazione del PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la generazione del PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[200]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        color: Colors.grey[500],
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text(
                'Lista Spesa',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
              backgroundColor: colorScheme.surface.withOpacity(0.7),
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              toolbarHeight: 100,
              actions: [
                if (_isSelectionMode) ...[
                  IconButton(
                    onPressed: _shareAsPDF,
                    icon: const Icon(Icons.share),
                    tooltip: 'Condividi come PDF',
                  ),
                  IconButton(
                    onPressed: _toggleSelectionMode,
                    icon: const Icon(Icons.close),
                    tooltip: 'Annulla selezione',
                  ),
                ] else ...[
                  IconButton(
                    onPressed: _toggleSelectionMode,
                    icon: const Icon(Icons.checklist),
                    tooltip: 'Seleziona prodotti',
                  ),
                ],
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.inventory.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final shoppingList = _getShoppingList(provider.inventory);

          if (shoppingList.isEmpty) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lista spesa vuota',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'I prodotti con quantità ≤ 1 appariranno qui',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header info
                if (_isSelectionMode)
                  Container(
                    color: const Color(0xFFF5F5F7),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedItems.length} prodotti selezionati',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Lista prodotti
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: shoppingList.length,
                    itemBuilder: (context, index) {
                      final item = shoppingList[index];
                      final isSelected = _selectedItems.contains(item.id);

                      return _buildShoppingItem(item, isSelected);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShoppingItem(InventoryItem item, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelectionMode ? () => _toggleSelection(item.id) : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surface.withOpacity(isDark ? 0.8 : 0.9),
                  isSelected
                      ? colorScheme.primaryContainer.withOpacity(0.7)
                      : colorScheme.surface.withOpacity(isDark ? 0.6 : 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.5)
                    : colorScheme.surfaceVariant.withOpacity(0.5),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox (se in modalità selezione)
                if (_isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(item.id),
                    activeColor: Colors.blue[700],
                  ),
                  const SizedBox(width: 12),
                ],

                // Immagine prodotto o thumbnail fittizia
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),

                const SizedBox(width: 16),

                // Info prodotto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.brand,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: item.quantity == 0
                                  ? Colors.red[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.quantity == 0
                                      ? Icons.warning
                                      : Icons.inventory_2_outlined,
                                  size: 14,
                                  color: item.quantity == 0
                                      ? Colors.red[700]
                                      : Colors.orange[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.quantity == 0
                                      ? 'Terminato'
                                      : '${item.quantity} ${item.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: item.quantity == 0
                                        ? Colors.red[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
