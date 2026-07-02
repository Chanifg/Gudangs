import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/raw_material_provider.dart';
import '../../providers/finished_good_provider.dart';
import '../../services/database_service.dart';

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  final String? preselectedItemId;
  final String? preselectedItemType; // 'raw_material' or 'product'

  const StockAdjustmentScreen({
    super.key,
    this.preselectedItemId,
    this.preselectedItemType,
  });

  @override
  ConsumerState<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyAdjustment = GlobalKey<FormState>();
  final _formKeyOpname = GlobalKey<FormState>();

  String _itemType = 'raw_material'; // 'raw_material' or 'product'
  String? _selectedItemId;
  String _adjustmentType = 'adjustment_add'; // 'adjustment_add' or 'adjustment_sub'
  
  final _qtyController = TextEditingController();
  final _opnameQtyController = TextEditingController();
  final _notesController = TextEditingController();

  double _currentStock = 0.0;
  String _unit = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.preselectedItemType != null) {
      _itemType = widget.preselectedItemType!;
    }
    if (widget.preselectedItemId != null) {
      _selectedItemId = widget.preselectedItemId!;
      _updateCurrentStockInfo();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qtyController.dispose();
    _opnameQtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateCurrentStockInfo() {
    if (_selectedItemId == null) {
      setState(() {
        _currentStock = 0.0;
        _unit = '';
      });
      return;
    }

    if (_itemType == 'raw_material') {
      final item = DatabaseService.rawMaterialsBox.get(_selectedItemId!);
      if (item != null) {
        setState(() {
          _currentStock = item.currentStock;
          _unit = item.unit;
        });
      }
    } else {
      final item = DatabaseService.finishedGoodsBox.get(_selectedItemId!);
      if (item != null) {
        setState(() {
          _currentStock = item.currentStock;
          _unit = item.unit;
        });
      }
    }
  }

  Future<void> _submitAdjustment() async {
    if (!_formKeyAdjustment.currentState!.validate() || _selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih barang dan isi jumlah koreksi.')),
      );
      return;
    }

    final double qty = double.tryParse(_qtyController.text) ?? 0.0;
    final notes = _notesController.text.trim();

    bool success = false;
    String error = '';

    if (_itemType == 'raw_material') {
      success = await ref.read(rawMaterialProvider.notifier).adjustStock(
        id: _selectedItemId!,
        type: _adjustmentType,
        quantity: qty,
        notes: notes,
      );
      if (!success) {
        error = ref.read(rawMaterialProvider).errorMessage ?? 'Gagal menyesuaikan stok';
      }
    } else {
      success = await ref.read(finishedGoodProvider.notifier).adjustStock(
        id: _selectedItemId!,
        type: _adjustmentType,
        quantity: qty,
        notes: notes,
      );
      if (!success) {
        error = ref.read(finishedGoodProvider).errorMessage ?? 'Gagal menyesuaikan stok';
      }
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penyesuaian stok berhasil disimpan')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Future<void> _submitOpname() async {
    if (!_formKeyOpname.currentState!.validate() || _selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih barang dan isi jumlah stok fisik.')),
      );
      return;
    }

    final double physicalQty = double.tryParse(_opnameQtyController.text) ?? 0.0;
    final notes = 'Stock Opname - ' + (_notesController.text.trim().isEmpty ? 'Pencocokan stok periodik' : _notesController.text.trim());

    bool success = false;
    String error = '';

    if (_itemType == 'raw_material') {
      success = await ref.read(rawMaterialProvider.notifier).adjustStock(
        id: _selectedItemId!,
        type: 'opname',
        quantity: physicalQty,
        notes: notes,
      );
      if (!success) {
        error = ref.read(rawMaterialProvider).errorMessage ?? 'Gagal melakukan stock opname';
      }
    } else {
      success = await ref.read(finishedGoodProvider.notifier).adjustStock(
        id: _selectedItemId!,
        type: 'opname',
        quantity: physicalQty,
        notes: notes,
      );
      if (!success) {
        error = ref.read(finishedGoodProvider).errorMessage ?? 'Gagal melakukan stock opname';
      }
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock opname berhasil disimpan')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rawMaterials = ref.watch(rawMaterialProvider).rawMaterials;
    final finishedGoods = ref.watch(finishedGoodProvider).finishedGoods;

    // Filter list for dropdown
    List<DropdownMenuItem<String>> items = [];
    if (_itemType == 'raw_material') {
      items = rawMaterials.map((m) {
        return DropdownMenuItem<String>(
          value: m.id,
          child: Text('${m.name} (${m.sku})'),
        );
      }).toList();
    } else {
      items = finishedGoods.map((g) {
        return DropdownMenuItem<String>(
          value: g.id,
          child: Text('${g.name} (${g.sku})'),
        );
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koreksi & Opname Stok'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Koreksi Stok', icon: Icon(Icons.tune_outlined)),
            Tab(text: 'Stock Opname', icon: Icon(Icons.playlist_add_check_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Adjustment
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKeyAdjustment,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Choice of Item Type
                      const Text(
                        'PILIH JENIS BARANG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Bahan Baku')),
                              selected: _itemType == 'raw_material',
                              onSelected: widget.preselectedItemType != null
                                  ? null
                                  : (selected) {
                                      if (selected) {
                                        setState(() {
                                          _itemType = 'raw_material';
                                          _selectedItemId = null;
                                          _updateCurrentStockInfo();
                                        });
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Barang Jadi')),
                              selected: _itemType == 'product',
                              onSelected: widget.preselectedItemType != null
                                  ? null
                                  : (selected) {
                                      if (selected) {
                                        setState(() {
                                          _itemType = 'product';
                                          _selectedItemId = null;
                                          _updateCurrentStockInfo();
                                        });
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Item Dropdown
                      const Text(
                        'PILIH BARANG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedItemId,
                        hint: const Text('Pilih barang yang ingin dikoreksi'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: items,
                        onChanged: widget.preselectedItemId != null
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedItemId = val;
                                  _updateCurrentStockInfo();
                                });
                              },
                      ),
                      const SizedBox(height: 20),

                      // Current Stock Snapshot Card
                      if (_selectedItemId != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Stok Sistem Saat Ini:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text('$_currentStock $_unit', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Adjustment Type (Add or Sub)
                      const Text(
                        'TIPE KOREKSI',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _adjustmentType = 'adjustment_add';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _adjustmentType == 'adjustment_add'
                                      ? colorScheme.primaryContainer
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _adjustmentType == 'adjustment_add'
                                        ? colorScheme.primary
                                        : colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.add_circle_outline, color: _adjustmentType == 'adjustment_add' ? colorScheme.primary : colorScheme.onSurfaceVariant),
                                    const SizedBox(height: 4),
                                    Text('Tambah Stok', style: TextStyle(fontWeight: FontWeight.bold, color: _adjustmentType == 'adjustment_add' ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _adjustmentType = 'adjustment_sub';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _adjustmentType == 'adjustment_sub'
                                      ? colorScheme.errorContainer
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _adjustmentType == 'adjustment_sub'
                                        ? colorScheme.error
                                        : colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.remove_circle_outline, color: _adjustmentType == 'adjustment_sub' ? colorScheme.error : colorScheme.onSurfaceVariant),
                                    const SizedBox(height: 4),
                                    Text('Kurangi Stok', style: TextStyle(fontWeight: FontWeight.bold, color: _adjustmentType == 'adjustment_sub' ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Quantity Input
                      const Text(
                        'JUMLAH UNIT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: _unit.isNotEmpty ? _unit : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Harap isi jumlah';
                          final d = double.tryParse(value);
                          if (d == null || d <= 0) return 'Jumlah harus lebih besar dari 0';
                          if (_adjustmentType == 'adjustment_sub' && d > _currentStock) {
                            return 'Pengurangan stok melebihi stok yang tersedia';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Notes Input
                      const Text(
                        'ALASAN / CATATAN KOREKSI',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Koreksi stok awal, Barang rusak, atau Barang hilang',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Harap isi alasan koreksi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitAdjustment,
                        child: const Text('Simpan Koreksi Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tab 2: Stock Opname
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKeyOpname,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Choice of Item Type
                      const Text(
                        'PILIH JENIS BARANG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Bahan Baku')),
                              selected: _itemType == 'raw_material',
                              onSelected: widget.preselectedItemType != null
                                  ? null
                                  : (selected) {
                                      if (selected) {
                                        setState(() {
                                          _itemType = 'raw_material';
                                          _selectedItemId = null;
                                          _updateCurrentStockInfo();
                                        });
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Barang Jadi')),
                              selected: _itemType == 'product',
                              onSelected: widget.preselectedItemType != null
                                  ? null
                                  : (selected) {
                                      if (selected) {
                                        setState(() {
                                          _itemType = 'product';
                                          _selectedItemId = null;
                                          _updateCurrentStockInfo();
                                        });
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Item Dropdown
                      const Text(
                        'PILIH BARANG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedItemId,
                        hint: const Text('Pilih barang untuk opname'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: items,
                        onChanged: widget.preselectedItemId != null
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedItemId = val;
                                  _updateCurrentStockInfo();
                                });
                              },
                      ),
                      const SizedBox(height: 20),

                      // Stock Opname Details Card
                      if (_selectedItemId != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Stok Tercatat (Sistem):', style: TextStyle(fontWeight: FontWeight.w500)),
                                  Text('$_currentStock $_unit', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Physical Stock Input
                      const Text(
                        'STOK FISIK SEBENARNYA (AKTUAL)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _opnameQtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Masukkan jumlah fisik yang dihitung',
                          suffixText: _unit.isNotEmpty ? _unit : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Harap isi jumlah fisik';
                          final d = double.tryParse(value);
                          if (d == null || d < 0) return 'Jumlah fisik tidak boleh negatif';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Optional Opname notes
                      const Text(
                        'CATATAN OPNAME (OPSIONAL)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Selisih susut kain atau opname bulanan',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitOpname,
                        child: const Text('Simpan Stock Opname', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
