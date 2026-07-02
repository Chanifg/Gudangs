import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../services/database_service.dart';

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
      filterActive: filterActive, // allow resetting to null by omission if handled, or pass explicitly
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Helper copyWith to allow resetting filterActive to null
  EmployeeState copyWithResetFilter({
    List<Employee>? employees,
    String? searchKeyword,
    bool? resetFilterActive, // if true, sets filterActive to null
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
  EmployeeNotifier() : super(EmployeeState(employees: [])) {
    loadEmployees();
  }

  void loadEmployees() {
    state = state.copyWith(isLoading: true);
    
    var allEmployees = DatabaseService.employeesBox.values.toList();

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
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.employeesBox.put(id, employee);
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

    employee.fullName = fullName.trim();
    employee.phoneNumber = phoneNumber.trim();
    employee.position = position.trim();
    employee.isActive = isActive;
    employee.updatedAt = DateTime.now();

    await employee.save();
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
      loadEmployees();
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final employeeProvider = StateNotifierProvider<EmployeeNotifier, EmployeeState>((ref) {
  return EmployeeNotifier();
});
