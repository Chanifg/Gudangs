import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/bom_provider.dart';
import '../../providers/finished_good_provider.dart';
import '../../providers/raw_material_provider.dart';
import '../../models/bill_of_materials.dart';
import '../../models/finished_good.dart';
import '../../models/raw_material.dart';

class BomFormScreen extends ConsumerStatefulWidget {
  final String? bomId;

  const BomFormScreen({super.key, this.bomId});

  @override
  ConsumerState<BomFormScreen> createState() => _BomFormScreenState();
}

class _BomFormScreenState extends ConsumerState<BomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String? _selectedFinishedGoodId;
  List<BOMComponentRow> _componentRows = [];
  bool _isEdit = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.bomId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(finishedGoodProvider.notifier).loadFinishedGoods();
      ref.read(rawMaterialProvider.notifier).loadRawMaterials();
      if (_isEdit) {
        _loadBOMData();
      } else {
        _addComponentRow();
      }
    });
  }

  void _loadBOMData() {
    final state = ref.read(bomProvider);
    final bom = state.boms.firstWhere((b) => b.id == widget.bomId);
    _nameController.text = bom.name;
    _selectedFinishedGoodId = bom.finishedGoodId;

    setState(() {
      _componentRows = bom.components.map((comp) {
        return BOMComponentRow(
          selectedRawMaterialId: comp.rawMaterialId,
          qtyController: TextEditingController(text: comp.quantityPerUnit.toString()),
        );
      }).toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final row in _componentRows) {
      row.qtyController.dispose();
    }
    super.dispose();
  }

  void _addComponentRow() {
    setState(() {
      _componentRows.add(BOMComponentRow(
        qtyController: TextEditingController(),
      ));
    });
  }

  void _removeComponentRow(int index) {
    if (_componentRows.length > 1) {
      setState(() {
        _componentRows[index].qtyController.dispose();
        _componentRows.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal terdapat 1 komponen dalam formula BOM'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFinishedGoodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih barang jadi yang diproduksi'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    final rawMaterials = ref.read(rawMaterialProvider).rawMaterials;
    List<BOMComponent> finalComponents = [];

    for (final row in _componentRows) {
      if (row.selectedRawMaterialId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih bahan baku untuk semua baris komponen'),
            backgroundColor: Color(0xFFBA1A1A),
          ),
        );
        return;
      }

      final rawMat = rawMaterials.firstWhere((m) => m.id == row.selectedRawMaterialId);
      final qty = double.tryParse(row.qtyController.text) ?? 0.0;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuantitas bahan baku harus lebih besar dari 0'),
            backgroundColor: Color(0xFFBA1A1A),
          ),
        );
        return;
      }

      finalComponents.add(BOMComponent(
        rawMaterialId: rawMat.id,
        rawMaterialName: rawMat.name,
        rawMaterialUnit: rawMat.unit,
        quantityPerUnit: qty,
      ));
    }

    // Check duplicate raw materials in component list
    final ids = finalComponents.map((c) => c.rawMaterialId).toList();
    if (ids.length != ids.toSet().length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bahan baku yang sama tidak boleh dimasukkan lebih dari sekali'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool success;
    if (_isEdit) {
      success = await ref.read(bomProvider.notifier).updateBOM(
            id: widget.bomId!,
            name: _nameController.text,
            components: finalComponents,
          );
    } else {
      success = await ref.read(bomProvider.notifier).addBOM(
            name: _nameController.text,
            finishedGoodId: _selectedFinishedGoodId!,
            components: finalComponents,
          );
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Formula BOM berhasil diperbarui'
                : 'Formula BOM berhasil ditambahkan'),
          ),
        );
        Navigator.pop(context);
      } else {
        final err = ref.read(bomProvider).errorMessage ?? 'Gagal menyimpan formula';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: const Color(0xFFBA1A1A)),
        );
        ref.read(bomProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fgState = ref.watch(finishedGoodProvider);
    final rmState = ref.watch(rawMaterialProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Filter out deleted finished goods
    final activeFinishedGoods = fgState.finishedGoods.where((fg) => !fg.isDeleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Formula BOM' : 'Tambah Formula BOM'),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Formula',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B1C30),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // BOM Name input
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Formula BOM',
                              hintText: 'Misal: Formula Kaos Polos Premium',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama formula wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Finished Good Selector Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedFinishedGoodId,
                            decoration: const InputDecoration(
                              labelText: 'Barang Jadi Hasil Produksi',
                            ),
                            items: activeFinishedGoods.map((fg) {
                              return DropdownMenuItem<String>(
                                value: fg.id,
                                child: Text('${fg.name} (${fg.sku})'),
                              );
                            }).toList(),
                            onChanged: _isEdit
                                ? null // Disable selecting a different product when editing
                                : (val) {
                                    setState(() {
                                      _selectedFinishedGoodId = val;
                                    });
                                  },
                            validator: (val) {
                              if (val == null) {
                                return 'Pilih barang jadi hasil produksi';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Komponen Bahan Baku',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0B1C30),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addComponentRow,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Baris', style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Components List View (Rows)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _componentRows.length,
                            itemBuilder: (context, index) {
                              final row = _componentRows[index];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Raw Material Selector
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<String>(
                                        value: row.selectedRawMaterialId,
                                        decoration: const InputDecoration(
                                          labelText: 'Bahan Baku',
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        items: rmState.rawMaterials.map((m) {
                                          return DropdownMenuItem<String>(
                                            value: m.id,
                                            child: Text('${m.name} (${m.unit})'),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            row.selectedRawMaterialId = val;
                                          });
                                        },
                                        validator: (val) {
                                          if (val == null) return 'Pilih';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Quantity Per Unit Input
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: row.qtyController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Kuantitas',
                                          hintText: '0.0',
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) return 'Wajib';
                                          final parsed = double.tryParse(val);
                                          if (parsed == null || parsed <= 0) return '> 0';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),

                                    // Remove Row Button
                                    IconButton(
                                      onPressed: () => _removeComponentRow(index),
                                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFBA1A1A)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF006E2F),
                    ),
                    child: Text(_isEdit ? 'PERBARUI FORMULA' : 'SIMPAN FORMULA'),
                  ),
                ],
              ),
            ),
    );
  }
}

class BOMComponentRow {
  String? selectedRawMaterialId;
  final TextEditingController qtyController;

  BOMComponentRow({
    this.selectedRawMaterialId,
    required this.qtyController,
  });
}
