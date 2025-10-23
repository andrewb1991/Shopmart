import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/date_scanner_screen.dart';
import '../models/product.dart';

class AddProductWidget extends StatefulWidget {
  const AddProductWidget({super.key});

  @override
  State<AddProductWidget> createState() => _AddProductWidgetState();
}

class _AddProductWidgetState extends State<AddProductWidget> {
  final _quantityController = TextEditingController(text: '1');
  final _productNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _unitController = TextEditingController(text: 'pz');
  DateTime? _selectedDate;
  bool _showIngredients = false;
  bool _isManualMode = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _productNameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('it', 'IT'),
      helpText: 'Seleziona data di scadenza',
      cancelText: 'Annulla',
      confirmText: 'OK',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _scanExpiryDate() async {
    final DateTime? scannedDate = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (context) => const DateScannerScreen(),
      ),
    );

    if (scannedDate != null && mounted) {
      setState(() {
        _selectedDate = scannedDate;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data riconosciuta: ${DateFormat('dd/MM/yyyy').format(scannedDate)}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result == true && mounted) {
      // Prodotto trovato, resetta la data
      setState(() {
        _selectedDate = null;
      });
    }
  }

  Future<void> _addProduct() async {
    final provider = Provider.of<InventoryProvider>(context, listen: false);

    // Validazione modalità manuale
    if (_isManualMode) {
      if (_productNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inserisci il nome del prodotto'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (_unitController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inserisci l\'unità di misura'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      // Validazione modalità scansione
      if (provider.currentProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scansiona prima un prodotto'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona una data di scadenza'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci una quantità valida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool success;

    if (_isManualMode) {
      // Creazione prodotto manuale
      final manualProduct = Product(
        barcode: _barcodeController.text.trim().isEmpty
            ? 'MANUAL_${DateTime.now().millisecondsSinceEpoch}'
            : _barcodeController.text.trim(),
        productName: _productNameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? 'N/D'
            : _brandController.text.trim(),
        category: null,
        unit: _unitController.text.trim(),
        ingredients: null,
        nutritionInfo: null,
        imageUrl: null,
      );

      success = await provider.addProduct(
        product: manualProduct,
        quantity: quantity,
        expiryDate: _selectedDate!,
      );
    } else {
      success = await provider.addProduct(
        product: provider.currentProduct!,
        quantity: quantity,
        expiryDate: _selectedDate!,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prodotto aggiunto al magazzino!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _selectedDate = null;
        _quantityController.text = '1';
        _showIngredients = false;
        if (_isManualMode) {
          _productNameController.clear();
          _brandController.clear();
          _barcodeController.clear();
          _unitController.text = 'pz';
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nell\'aggiunta del prodotto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aggiungi Prodotto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Toggle modalità
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isManualMode = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isManualMode ? Colors.blue : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: !_isManualMode ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Scansione',
                                style: TextStyle(
                                  color: !_isManualMode ? Colors.white : Colors.grey[600],
                                  fontWeight: !_isManualMode ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isManualMode = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isManualMode ? Colors.blue : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit,
                                color: _isManualMode ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Manuale',
                                style: TextStyle(
                                  color: _isManualMode ? Colors.white : Colors.grey[600],
                                  fontWeight: _isManualMode ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Pulsante scansione (visibile solo in modalità scansione)
              if (!_isManualMode) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _openBarcodeScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scansiona Codice a Barre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Form manuale (visibile solo in modalità manuale)
              if (_isManualMode) ...[
                TextField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    labelText: 'Nome Prodotto *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    labelText: 'Brand (opzionale)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Codice a Barre (opzionale)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantità *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _unitController,
                        decoration: InputDecoration(
                          labelText: 'Unità *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Data scadenza *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null
                                    ? 'Seleziona data'
                                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate == null
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _scanExpiryDate,
                      icon: const Icon(Icons.document_scanner),
                      tooltip: 'Scansiona data',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _addProduct,
                    icon: const Icon(Icons.add),
                    label: Text(
                      provider.isLoading
                          ? 'Aggiunta in corso...'
                          : 'Aggiungi al magazzino',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],

              // Dettagli prodotto trovato
              if (provider.currentProduct != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Immagine prodotto
                      if (provider.currentProduct!.imageUrl != null) ...[
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              provider.currentProduct!.imageUrl!,
                              height: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Nome prodotto
                      Text(
                        provider.currentProduct!.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Brand
                      Text(
                        'Brand: ${provider.currentProduct!.brand}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),

                      // Categoria
                      if (provider.currentProduct!.category != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Categoria: ${provider.currentProduct!.category!.split(',').first}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],

                      // Ingredienti collapsable
                      if (provider.currentProduct!.ingredients != null) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showIngredients = !_showIngredients;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                'Ingredienti',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Icon(
                                _showIngredients
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                            ],
                          ),
                        ),
                        if (_showIngredients) ...[
                          const SizedBox(height: 8),
                          Text(
                            provider.currentProduct!.ingredients!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 16),

                      // Quantità
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantità',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Data scadenza
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Data scadenza',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate == null
                                          ? 'Seleziona data'
                                          : DateFormat('dd/MM/yyyy')
                                              .format(_selectedDate!),
                                      style: TextStyle(
                                        color: _selectedDate == null
                                            ? Colors.grey[600]
                                            : Colors.black87,
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Pulsante scan data
                          IconButton(
                            onPressed: _scanExpiryDate,
                            icon: const Icon(Icons.document_scanner),
                            tooltip: 'Scansiona data',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue[50],
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Pulsante aggiungi
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : _addProduct,
                          icon: const Icon(Icons.add),
                          label: Text(
                            provider.isLoading
                                ? 'Aggiunta in corso...'
                                : 'Aggiungi al magazzino',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Messaggio di errore
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
