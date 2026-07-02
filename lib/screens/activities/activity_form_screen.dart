import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employee_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/activity_provider.dart';
import '../../core/formatters.dart';
import '../../services/database_service.dart';

class ActivityFormScreen extends ConsumerStatefulWidget {
  final String? activityId;
  final String? preselectedEmployeeId;

  const ActivityFormScreen({
    super.key,
    this.activityId,
    this.preselectedEmployeeId,
  });

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedEmployeeId;
  String? _selectedJobTypeId;
  double _jobTypeRate = 0.0;
  DateTime _selectedDate = DateTime.now();
  double _estimatedWage = 0.0;

  bool get _isEditing => widget.activityId != null;

  @override
  void initState() {
    super.initState();
    _unitsController.addListener(_updateEstimatedWage);

    if (_isEditing) {
      _loadActivityData();
    } else {
      _selectedEmployeeId = widget.preselectedEmployeeId;
    }
  }

  void _loadActivityData() {
    final act = DatabaseService.activityBox.get(widget.activityId);
    if (act != null) {
      _selectedEmployeeId = act.employeeId;
      _selectedJobTypeId = act.jobTypeId;
      _jobTypeRate = act.ratePerUnit;
      _unitsController.text = act.units.toString();
      _selectedDate = act.date;
      _notesController.text = act.notes ?? '';
    }
  }

  @override
  void dispose() {
    _unitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateEstimatedWage() {
    final units = double.tryParse(_unitsController.text) ?? 0.0;
    
    // If editing, we use the snapshotted rate. If adding, we use the current rate from dropdown.
    final rate = _isEditing ? _jobTypeRate : _getCurrentJobTypeRate();

    setState(() {
      _estimatedWage = units * rate;
    });
  }

  double _getCurrentJobTypeRate() {
    if (_selectedJobTypeId == null) return 0.0;
    try {
      final jobType = ref.read(settingsProvider).jobTypes.firstWhere((jt) => jt.id == _selectedJobTypeId);
      return jobType.ratePerUnit;
    } catch (_) {
      return 0.0;
    }
  }

  void _onJobTypeChanged(String? jobTypeId) {
    if (jobTypeId == null) return;
    setState(() {
      _selectedJobTypeId = jobTypeId;
      _jobTypeRate = _getCurrentJobTypeRate();
      _updateEstimatedWage();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih karyawan terlebih dahulu')),
      );
      return;
    }
    if (_selectedJobTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis pekerjaan terlebih dahulu')),
      );
      return;
    }

    ref.read(activityProvider.notifier).clearError();
    bool success = false;

    if (_isEditing) {
      success = await ref.read(activityProvider.notifier).updateActivity(
            id: widget.activityId!,
            units: double.tryParse(_unitsController.text) ?? 0.0,
            date: _selectedDate,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text,
          );
    } else {
      success = await ref.read(activityProvider.notifier).addActivity(
            employeeId: _selectedEmployeeId!,
            jobTypeId: _selectedJobTypeId!,
            units: double.tryParse(_unitsController.text) ?? 0.0,
            date: _selectedDate,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text,
          );
    }

    if (success && mounted) {
      context.pop(); // Go back to list
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);
    final settingsState = ref.watch(settingsProvider);
    final activityState = ref.watch(activityProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Filter active employees for additions, allow any employee in edit mode
    final employees = _isEditing
        ? employeeState.employees
        : employeeState.employees.where((e) => e.isActive).toList();
        
    final jobTypes = settingsState.jobTypes;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Ubah Catatan Kerja' : 'Catat Kerja Karyawan'),
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
                if (activityState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Text(
                      activityState.errorMessage!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Employee Selection
                DropdownButtonFormField<String>(
                  value: _selectedEmployeeId,
                  disabledHint: _selectedEmployeeId != null
                      ? Text(employees.firstWhere((e) => e.id == _selectedEmployeeId).fullName)
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Karyawan *',
                  ),
                  items: employees.map((emp) {
                    return DropdownMenuItem<String>(
                      value: emp.id,
                      child: Text(emp.fullName),
                    );
                  }).toList(),
                  onChanged: _isEditing
                      ? null // Cannot change employee once recorded
                      : (val) {
                          setState(() {
                            _selectedEmployeeId = val;
                          });
                        },
                  validator: (value) => value == null ? 'Wajib memilih karyawan' : null,
                ),
                const SizedBox(height: 16),

                // Job Type Selection
                DropdownButtonFormField<String>(
                  value: _selectedJobTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Jenis Pekerjaan *',
                  ),
                  items: jobTypes.map((jt) {
                    return DropdownMenuItem<String>(
                      value: jt.id,
                      child: Text('${jt.name} (Rp ${jt.ratePerUnit.toStringAsFixed(0)}/unit)'),
                    );
                  }).toList(),
                  onChanged: _isEditing ? null : _onJobTypeChanged, // Cannot change job type once recorded
                  validator: (value) => value == null ? 'Wajib memilih jenis pekerjaan' : null,
                ),
                const SizedBox(height: 16),

                // Units completed Field
                TextFormField(
                  controller: _unitsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Unit Diselesaikan *',
                    hintText: '0',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jumlah unit tidak boleh kosong';
                    }
                    final n = double.tryParse(value);
                    if (n == null || n <= 0) {
                      return 'Jumlah unit harus berupa angka > 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker Button
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Pekerjaan *',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      Formatters.formatDate(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan / Keterangan',
                    hintText: 'Contoh: Lembur malam',
                  ),
                ),
                const SizedBox(height: 24),

                // Real-time calculated wages
                Card(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ESTIMASI UPAH DITERIMA',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          Formatters.formatRupiah(_estimatedWage),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _saveActivity,
                  child: const Text('Simpan Catatan Kerja'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
