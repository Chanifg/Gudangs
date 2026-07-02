import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../services/database_service.dart';
import 'audit_log_provider.dart';
import 'auth_provider.dart';

class EmployeeState {
  final List<Employee> employees;
  final String searchKeyword;
  final bool? filterActive; // null: all, true: active only, false: inactive only
  final String? errorMessage;
  final bool isLoading;

  EmployeeState({
    required this.employees,
    this.searchKeyword = '',
    this.filterActive,
    this.errorMessage,
    this.isLoading = false,
  });

  EmployeeState copyWith({
    List<Employee>? employees,
    String? searchKeyword,
    bool? filterActive,
    String? errorMessage,
    bool? isLoading,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      filterActive: filterActive,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  EmployeeState copyWithResetFilter({
    List<Employee>? employees,
    String? searchKeyword,
    bool? resetFilterActive,
    bool? filterActive,
    String? errorMessage,
    bool? isLoading,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      filterActive: resetFilterActive == true ? null : (filterActive ?? this.filterActive),
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class EmployeeNotifier extends StateNotifier<EmployeeState> {
  final Ref ref;

  EmployeeNotifier(this.ref) : super(EmployeeState(employees: [])) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        loadEmployees();
      }
    });
    loadEmployees();
  }

  void loadEmployees() {
    if (!DatabaseService.isOperationalOpen) return;
    state = state.copyWith(isLoading: true);
    
    // Filter out soft deleted employees
    var allEmployees = DatabaseService.employeesBox.values
        .where((emp) => emp.isDeleted != true)
        .toList();

    // Apply Active Status Filter
    if (state.filterActive != null) {
      allEmployees = allEmployees.where((emp) => emp.isActive == state.filterActive).toList();
    }

    // Apply Search
    if (state.searchKeyword.isNotEmpty) {
      final query = state.searchKeyword.toLowerCase();
      allEmployees = allEmployees.where((emp) => emp.fullName.toLowerCase().contains(query)).toList();
    }

    // Sort alphabetically by full name
    allEmployees.sort((a, b) => a.fullName.compareTo(b.fullName));

    state = state.copyWith(employees: allEmployees, isLoading: false);
  }

  void setSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword);
    loadEmployees();
  }

  void setFilterActive(bool? active) {
    if (active == null) {
      state = state.copyWithResetFilter(resetFilterActive: true);
    } else {
      state = state.copyWith(filterActive: active);
    }
    loadEmployees();
  }

  // Add Employee
  Future<bool> addEmployee({
    required String fullName,
    required String phoneNumber,
    required String position,
    bool isActive = true,
  }) async {
    if (fullName.trim().isEmpty || phoneNumber.trim().isEmpty || position.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Semua field wajib diisi');
      return false;
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final employee = Employee(
      id: id,
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      position: position.trim(),
      isActive: isActive,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.employeesBox.put(id, employee);
    
    // Log audit
    ref.read(auditLogProvider.notifier).logActivity(
      action: 'TAMBAH_KARYAWAN',
      description: 'Menambahkan karyawan baru: ${employee.fullName}',
    );

    loadEmployees();
    return true;
  }

  // Update Employee
  Future<bool> updateEmployee({
    required String id,
    required String fullName,
    required String phoneNumber,
    required String position,
    required bool isActive,
  }) async {
    final employee = DatabaseService.employeesBox.get(id);
    if (employee == null) {
      state = state.copyWith(errorMessage: 'Karyawan tidak ditemukan');
      return false;
    }

    if (fullName.trim().isEmpty || phoneNumber.trim().isEmpty || position.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Semua field wajib diisi');
      return false;
    }

    final oldName = employee.fullName;
    employee.fullName = fullName.trim();
    employee.phoneNumber = phoneNumber.trim();
    employee.position = position.trim();
    employee.isActive = isActive;
    employee.updatedAt = DateTime.now();

    await employee.save();

    // Log audit
    ref.read(auditLogProvider.notifier).logActivity(
      action: 'EDIT_KARYAWAN',
      description: 'Mengubah profil karyawan: $oldName -> ${employee.fullName} (Status Aktif: ${employee.isActive})',
    );

    loadEmployees();
    return true;
  }

  // Toggle active status
  Future<void> toggleActive(String id) async {
    final employee = DatabaseService.employeesBox.get(id);
    if (employee != null) {
      employee.isActive = !employee.isActive;
      employee.updatedAt = DateTime.now();
      await employee.save();
      
      // Log audit
      ref.read(auditLogProvider.notifier).logActivity(
        action: 'TOGGLE_AKTIF_KARYAWAN',
        description: 'Mengubah status keaktifan karyawan ${employee.fullName}: ${employee.isActive ? "Aktif" : "Nonaktif"}',
      );

      loadEmployees();
    }
  }

  // Soft delete employee
  Future<void> deleteEmployee(String id) async {
    final employee = DatabaseService.employeesBox.get(id);
    if (employee != null) {
      employee.isDeleted = true;
      employee.updatedAt = DateTime.now();
      await employee.save();

      // Log audit
      ref.read(auditLogProvider.notifier).logActivity(
        action: 'HAPUS_KARYAWAN',
        description: 'Menghapus karyawan (soft delete): ${employee.fullName}',
      );

      loadEmployees();
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final employeeProvider = StateNotifierProvider<EmployeeNotifier, EmployeeState>((ref) {
  return EmployeeNotifier(ref);
});
