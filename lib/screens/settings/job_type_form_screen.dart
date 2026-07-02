import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_service.dart';

class JobTypeFormScreen extends ConsumerStatefulWidget {
  final String? jobTypeId;

  const JobTypeFormScreen({super.key, this.jobTypeId});

  @override
  ConsumerState<JobTypeFormScreen> createState() => _JobTypeFormScreenState();
}

class _JobTypeFormScreenState extends ConsumerState<JobTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();

  bool get _isEditing => widget.jobTypeId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadJobTypeData();
    }
  }

  void _loadJobTypeData() {
    final jobType = DatabaseService.jobTypesBox.get(widget.jobTypeId);
    if (jobType != null) {
      _nameController.text = jobType.name;
      _rateController.text = jobType.ratePerUnit.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveJobType() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(settingsProvider.notifier).clearMessage();
    bool success = false;

    if (_isEditing) {
      success = await ref.read(settingsProvider.notifier).updateJobType(
            widget.jobTypeId!,
            _nameController.text,
            double.tryParse(_rateController.text) ?? 0.0,
          );
    } else {
      success = await ref.read(settingsProvider.notifier).addJobType(
            _nameController.text,
            double.tryParse(_rateController.text) ?? 0.0,
          );
    }

    if (success && mounted) {
      context.pop(); // Go back to settings
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Ubah Jenis Pekerjaan' : 'Tambah Jenis Pekerjaan'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message banner
                if (settingsState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Text(
                      settingsState.errorMessage!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Job Type Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pekerjaan *',
                    hintText: 'Contoh: Bongkar Muat Beras, Sortir Telur',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pekerjaan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Rate per Unit
                TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tarif Per Unit (Rupiah) *',
                    hintText: '0',
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tarif per unit tidak boleh kosong';
                    }
                    final n = double.tryParse(value);
                    if (n == null || n < 0) {
                      return 'Tarif harus berupa angka >= 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _saveJobType,
                  child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Jenis Pekerjaan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
