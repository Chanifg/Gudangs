import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employee_provider.dart';
import '../../services/database_service.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final String? employeeId;

  const EmployeeFormScreen({super.key, this.employeeId});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  bool _isActive = true;

  bool get _isEditing => widget.employeeId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadEmployeeData();
    }
  }

  void _loadEmployeeData() {
    final employee = DatabaseService.employeesBox.get(widget.employeeId);
    if (employee != null) {
      _nameController.text = employee.fullName;
      _phoneController.text = employee.phoneNumber;
      _positionController.text = employee.position;
      _isActive = employee.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(employeeProvider.notifier).clearError();
    bool success = false;

    if (_isEditing) {
      success = await ref.read(employeeProvider.notifier).updateEmployee(
            id: widget.employeeId!,
            fullName: _nameController.text,
            phoneNumber: _phoneController.text,
            position: _positionController.text,
            isActive: _isActive,
          );
    } else {
      success = await ref.read(employeeProvider.notifier).addEmployee(
            fullName: _nameController.text,
            phoneNumber: _phoneController.text,
            position: _positionController.text,
            isActive: _isActive,
          );
    }

    if (success && mounted) {
      context.pop(); // Go back to list
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Ubah Profil Karyawan' : 'Tambah Karyawan Baru'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error banner
                if (employeeState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Text(
                      employeeState.errorMessage!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap Karyawan *',
                    hintText: 'Contoh: Budi Santoso',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP *',
                    hintText: 'Contoh: 08123456789',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor HP tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Position / Position in Warehouse
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'Posisi / Jabatan *',
                    hintText: 'Contoh: Karyawan Harian, Sortir, Helper',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Posisi/jabatan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Active toggle status
                SwitchListTile(
                  title: const Text('Status Karyawan Aktif'),
                  subtitle: const Text('Karyawan nonaktif tidak muncul di form input upah harian.'),
                  value: _isActive,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                    });
                  },
                  activeColor: colorScheme.primaryContainer,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Save button
                ElevatedButton(
                  onPressed: _saveEmployee,
                  child: Text(_isEditing ? 'Simpan Profil' : 'Tambah Karyawan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
