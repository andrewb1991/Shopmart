import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';
import 'recipes_screen.dart';

// Schermata con TabView che integra "Tutti i prodotti" e "In scadenza"
// Mantiene la barra di ricerca, filtri e "Genera ricetta" sempre visibili

class HomeWithTabsScreen extends StatefulWidget {
  const HomeWithTabsScreen({super.key});

  @override
  State<HomeWithTabsScreen> createState() => _HomeWithTabsScreenState();
}

enum SortType { nameAsc, nameDesc, brandAsc, brandDesc, expiryAsc, expiryDesc, quantityAsc, quantityDesc }

class _HomeWithTabsScreenState extends State<HomeWithTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortType _currentSort = SortType.expiryAsc; // Default: ordina per scadenza
  bool _isSelectionMode = false;
  Set<String> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Carica l'inventario all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<InventoryProvider>(context, listen: false).loadInventory();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryItem> _filterInventory(List<InventoryItem> inventory) {
    if (_searchQuery.isEmpty) {
      return inventory;
    }
    return inventory.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.productName.toLowerCase().contains(query) ||
          item.brand.toLowerCase().contains(query);
    }).toList();
  }

  List<InventoryItem> _sortInventory(List<InventoryItem> inventory) {
    final sorted = List<InventoryItem>.from(inventory);

    switch (_currentSort) {
      case SortType.nameAsc:
        sorted.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
        break;
      case SortType.nameDesc:
        sorted.sort((a, b) => b.productName.toLowerCase().compareTo(a.productName.toLowerCase()));
        break;
      case SortType.brandAsc:
        sorted.sort((a, b) => a.brand.toLowerCase().compareTo(b.brand.toLowerCase()));
        break;
      case SortType.brandDesc:
        sorted.sort((a, b) => b.brand.toLowerCase().compareTo(a.brand.toLowerCase()));
        break;
      case SortType.expiryAsc:
        sorted.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case SortType.expiryDesc:
        sorted.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
        break;
      case SortType.quantityAsc:
        sorted.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case SortType.quantityDesc:
        sorted.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
    }

    return sorted;
  }

  List<InventoryItem> _getExpiringProducts(List<InventoryItem> inventory) {
    return inventory.where((item) {
      return item.status == ProductStatus.scaduto ||
          item.status == ProductStatus.urgente ||
          item.status == ProductStatus.attenzione;
    }).toList();
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

  Future<void> _generateRecipes() async {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final selectedProducts = provider.inventory
        .where((item) => _selectedProductIds.contains(item.id))
        .map((item) => item.productName)
        .toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno un prodotto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Cercando ricette...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final apiService = ApiService();
      final recipes = await apiService.suggestRecipes(selectedProducts);

      if (!mounted) return;

      Navigator.pop(context);

      if (recipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nessuna ricetta trovata con questi ingredienti'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSelectionMode = false;
        _selectedProductIds.clear();
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipesScreen(
            recipes: recipes,
            selectedIngredients: selectedProducts,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la ricerca: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editProduct(InventoryItem item) async {
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.productName);
    final brandController = TextEditingController(text: item.brand);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final unitController = TextEditingController(text: item.unit ?? 'pz');
    DateTime selectedDate = item.expiryDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: Colors.blue[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Modifica Prodotto',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: nameController,
                              label: 'Nome prodotto',
                              icon: Icons.shopping_bag_outlined,
                              validator: (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: brandController,
                              label: 'Marca',
                              icon: Icons.business_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: quantityController,
                              label: 'Quantità',
                              icon: Icons.numbers_rounded,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Campo obbligatorio';
                                if (int.tryParse(value) == null) return 'Inserisci un numero valido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: unitController,
                              label: 'Unità (es. pz, kg, L)',
                              icon: Icons.straighten_rounded,
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final initialDate = selectedDate.isBefore(now) ? now : selectedDate;

                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initialDate,
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 3650)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.grey[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Data di scadenza',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(selectedDate),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.grey[400],
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.grey.withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'Annulla',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      if (formKey.currentState?.validate() ?? false) {
                                        Navigator.of(context).pop({
                                          'productName': nameController.text,
                                          'brand': brandController.text,
                                          'quantity': int.parse(quantityController.text),
                                          'unit': unitController.text,
                                          'expiryDate': selectedDate,
                                        });
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.blue[700],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Salva',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final success = await provider.updateProduct(
        id: item.id,
        productName: result['productName'],
        brand: result['brand'],
        quantity: result['quantity'],
        unit: result['unit'],
        expiryDate: result['expiryDate'],
      );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Prodotto aggiornato'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'aggiornamento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
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
      backgroundColor: const Color(0xFFF5F5F7),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Header con titolo e azioni
                    SizedBox(
                      height: 70,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text(
                              'In casa',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 28,
                                letterSpacing: -0.5,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.refresh_rounded),
                                onPressed: () {
                                  Provider.of<InventoryProvider>(context, listen: false)
                                      .loadInventory();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // TabBar con stile liquid glass
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue[400]!.withOpacity(0.8),
                                    Colors.blue[700]!.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorPadding: const EdgeInsets.all(4),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey[700],
                              labelStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                              dividerColor: Colors.transparent,
                              overlayColor: WidgetStateProperty.all(Colors.transparent),
                              tabs: const [
                                Tab(text: 'Tutti i prodotti'),
                                Tab(text: 'In scadenza'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Barra di ricerca con filtro (FISSA - sempre visibile)
              SafeArea(
                bottom: false,
                child: Container(
                  color: const Color(0xFFF5F5F7),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      // Pulsante filtro
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: PopupMenuButton<SortType>(
                                icon: Icon(
                                  Icons.filter_list_rounded,
                                  color: Colors.blue[700],
                                  size: 24,
                                ),
                                color: Colors.white.withOpacity(0.95),
                                elevation: 20,
                                shadowColor: Colors.black.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                offset: const Offset(0, 8),
                                onSelected: (SortType value) {
                                  setState(() {
                                    _currentSort = value;
                                  });
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: SortType.nameAsc,
                                    padding: EdgeInsets.zero,
                                    child: _buildMenuItemGlass(
                                      icon: Icons.sort_by_alpha,
                                      text: 'Nome (A-Z)',
                                      isSelected: _currentSort == SortType.nameAsc,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortType.nameDesc,
                                    padding: EdgeInsets.zero,
                                    child: _buildMenuItemGlass(
                                      icon: Icons.sort_by_alpha,
                                      text: 'Nome (Z-A)',
                                      isSelected: _currentSort == SortType.nameDesc,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortType.brandAsc,
                                    padding: EdgeInsets.zero,
                                    child: _buildMenuItemGlass(
                                      icon: Icons.business,
                                      text: 'Marca (A-Z)',
                                      isSelected: _currentSort == SortType.brandAsc,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortType.brandDesc,
                                    padding: EdgeInsets.zero,
                                    child: _buildMenuItemGlass(
                                      icon: Icons.business,
                                      text: 'Marca (Z-A)',
                                      isSelected: _currentSort == SortType.brandDesc,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortType.expiryAsc,
                                    padding: EdgeInsets.zero,
                                    child: _buildMenuItemGlass(
                                      icon: Icons.calendar_today,
                                      text: 'Scadenza (prossima)',
                                      isSelected: _currentSort == SortType.expiryAsc,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortType.expiryDesc,
                                    padding: EdgeInsets.zero,
                                    child: _buildMenuItemGlass(
                                      icon: Icons.calendar_today,
                                      text: 'Scadenza (lontana)',
                                      isSelected: _currentSort == SortType.expiryDesc,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortType.quantityAsc,
                                    padding: EdgeInsets.zero,
                                    child: _buildMenuItemGlass(
                                      icon: Icons.numbers,
                                      text: 'Quantità (crescente)',
                                      isSelected: _currentSort == SortType.quantityAsc,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: SortType.quantityDesc,
                                    padding: EdgeInsets.zero,
                                    child: _buildMenuItemGlass(
                                      icon: Icons.numbers,
                                      text: 'Quantità (decrescente)',
                                      isSelected: _currentSort == SortType.quantityDesc,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Barra di ricerca
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Cerca per nome o marca...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 15,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.grey[700],
                                    size: 24,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear_rounded,
                                            color: Colors.grey[700],
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pulsante "Genera Ricetta" (FISSO - sempre visibile in entrambe le tab)
              Container(
                color: const Color(0xFFF5F5F7),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: _isSelectionMode
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isSelectionMode = false;
                                          _selectedProductIds.clear();
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: Colors.grey.withOpacity(0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Annulla',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: TextButton(
                                      onPressed: _selectedProductIds.isEmpty
                                          ? null
                                          : () {
                                              _generateRecipes();
                                            },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: _selectedProductIds.isEmpty
                                            ? Colors.grey[300]
                                            : Colors.green[600],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.restaurant_menu_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Crea ricetta (${_selectedProductIds.length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isSelectionMode = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.green[400]!,
                                        Colors.green[600]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: -2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Genera Ricetta',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

              // TabBarView con le due liste
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Tutti i prodotti
                    _buildProductsList(provider.inventory),
                    // Tab 2: In scadenza
                    _buildProductsList(_getExpiringProducts(provider.inventory)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductsList(List<InventoryItem> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabController.index == 0 ? Icons.inventory_2_outlined : Icons.check_circle_outline,
              size: 64,
              color: _tabController.index == 0 ? Colors.grey : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              _tabController.index == 0
                  ? 'Nessun prodotto nel magazzino'
                  : 'Nessun prodotto in scadenza',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tabController.index == 0
                  ? 'Inizia ad aggiungere prodotti!'
                  : 'Tutto sotto controllo! 🎉',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final sortedInventory = _sortInventory(products);
    final filteredInventory = _filterInventory(sortedInventory);

    if (filteredInventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun risultato',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: filteredInventory.length,
      itemBuilder: (context, index) {
        return _buildInventoryItem(filteredInventory[index]);
      },
    );
  }

  Widget _buildMenuItemGlass({
    required IconData icon,
    required String text,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[100]!.withOpacity(0.3),
                  Colors.blue[50]!.withOpacity(0.2),
                ],
              )
            : null,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.blue[700] : Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.blue[700] : Colors.grey[800],
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check_rounded,
              size: 20,
              color: Colors.blue[700],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventoryItem(InventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getStatusColor(item.status).withOpacity(0.3),
                  Colors.white.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStatusBorderColor(item.status).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Nome prodotto
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.brand,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Contenuto: Immagine e info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox per selezione ricette (visibile in entrambe le tab quando in modalità selezione)
                    if (_isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Transform.scale(
                          scale: 1.3,
                          child: Checkbox(
                            value: _selectedProductIds.contains(item.id),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedProductIds.add(item.id);
                                } else {
                                  _selectedProductIds.remove(item.id);
                                }
                              });
                            },
                            activeColor: Colors.green[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),

                    // Immagine prodotto
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.white,
                          child: item.imageUrl != null
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.grey[100]!,
                                            Colors.grey[200]!,
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.grey[400],
                                        size: 48,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.grey[100]!,
                                        Colors.grey[200]!,
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.grey[400],
                                    size: 48,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Info prodotto con scadenza
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scadenza',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _getStatusIcon(item.status),
                                color: _getStatusIconColor(item.status),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd/MM/yyyy').format(item.expiryDate),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getDaysLeftText(item.daysLeft),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getStatusIconColor(item.status),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Ingredienti collapsable
                if (item.ingredients != null) ...[
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text(
                        'Vedi ingredienti',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 8),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.ingredients!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Controlli quantità ed azioni
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pulsante modifica
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _editProduct(item),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: Colors.blue[700],
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Controlli quantità
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Pulsante -
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(16),
                              ),
                              onTap: item.quantity > 0
                                  ? () async {
                                      final provider = Provider.of<InventoryProvider>(
                                        context,
                                        listen: false,
                                      );
                                      await provider.updateQuantity(
                                        item.id,
                                        item.quantity - 1,
                                      );
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: item.quantity > 0
                                      ? Colors.blue[700]
                                      : Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          // Quantità
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  item.unit ?? 'pz',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Pulsante +
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(16),
                              ),
                              onTap: () async {
                                final provider = Provider.of<InventoryProvider>(
                                  context,
                                  listen: false,
                                );
                                await provider.updateQuantity(
                                  item.id,
                                  item.quantity + 1,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Pulsante elimina
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _deleteProduct(item.id),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red[600]!,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.delete_rounded,
                            color: Colors.red[600],
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
