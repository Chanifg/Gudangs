import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/activity_record.dart';
import '../services/database_service.dart';

class ActivityState {
  final List<ActivityRecord> records;
  final DateTimeRange? dateFilter;
  final String? employeeFilterId;
  final String? jobTypeFilterId;
  final String? errorMessage;
  final bool isLoading;

  ActivityState({
    required this.records,
    this.dateFilter,
    this.employeeFilterId,
    this.jobTypeFilterId,
    this.errorMessage,
    this.isLoading = false,
  });

  ActivityState copyWith({
    List<ActivityRecord>? records,
    DateTimeRange? dateFilter,
    String? employeeFilterId,
    String? jobTypeFilterId,
    String? errorMessage,
    bool? isLoading,
  }) {
    return ActivityState(
      records: records ?? this.records,
      dateFilter: dateFilter ?? this.dateFilter,
      employeeFilterId: employeeFilterId ?? this.employeeFilterId,
      jobTypeFilterId: jobTypeFilterId ?? this.jobTypeFilterId,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  ActivityNotifier() : super(ActivityState(records: [])) {
    loadActivityRecords();
  }

  void loadActivityRecords() {
    state = state.copyWith(isLoading: true);
    
    var allRecords = DatabaseService.activityBox.values.toList();

    // Apply Employee Filter
    if (state.employeeFilterId != null) {
      allRecords = allRecords.where((rec) => rec.employeeId == state.employeeFilterId).toList();
    }

    // Apply Job Type Filter
    if (state.jobTypeFilterId != null) {
      allRecords = allRecords.where((rec) => rec.jobTypeId == state.jobTypeFilterId).toList();
    }

    // Apply Date Range Filter
    if (state.dateFilter != null) {
      allRecords = allRecords.where((rec) {
        final date = rec.date;
        return date.isAfter(state.dateFilter!.start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(state.dateFilter!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by date descending
    allRecords.sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(records: allRecords, isLoading: false);
  }

  void setFilters({DateTimeRange? dateRange, String? employeeId, String? jobTypeId}) {
    state = state.copyWith(
      dateFilter: dateRange,
      employeeFilterId: employeeId,
      jobTypeFilterId: jobTypeId,
    );
    loadActivityRecords();
  }

  void clearFilters() {
    state = ActivityState(records: []);
    loadActivityRecords();
  }

  // Add Activity Record
  Future<bool> addActivity({
    required String employeeId,
    required String jobTypeId,
    required double units,
    required DateTime date,
    String? notes,
  }) async {
    if (employeeId.isEmpty || jobTypeId.isEmpty || units <= 0) {
      state = state.copyWith(errorMessage: 'Karyawan, jenis pekerjaan, dan jumlah unit (>0) wajib diisi.');
      return false;
    }

    final employee = DatabaseService.employeesBox.get(employeeId);
    final jobType = DatabaseService.jobTypesBox.get(jobTypeId);

    if (employee == null || !employee.isActive) {
      state = state.copyWith(errorMessage: 'Karyawan tidak ditemukan atau sudah tidak aktif.');
      return false;
    }

    if (jobType == null) {
      state = state.copyWith(errorMessage: 'Jenis pekerjaan tidak ditemukan.');
      return false;
    }

    final id = const Uuid().v4();
    final estimatedWage = units * jobType.ratePerUnit;

    final record = ActivityRecord(
      id: id,
      employeeId: employeeId,
      employeeName: employee.fullName,
      jobTypeId: jobTypeId,
      jobTypeName: jobType.name,
      units: units,
      ratePerUnit: jobType.ratePerUnit,
      estimatedWage: estimatedWage,
      date: date,
      notes: notes?.trim(),
      createdAt: DateTime.now(),
    );

    await DatabaseService.activityBox.put(id, record);
    loadActivityRecords();
    return true;
  }

  // Edit Activity Record
  Future<bool> updateActivity({
    required String id,
    required double units,
    required DateTime date,
    String? notes,
  }) async {
    final record = DatabaseService.activityBox.get(id);
    if (record == null) {
      state = state.copyWith(errorMessage: 'Catatan aktivitas tidak ditemukan.');
      return false;
    }

    if (units <= 0) {
      state = state.copyWith(errorMessage: 'Jumlah unit harus lebih besar dari 0.');
      return false;
    }

    record.units = units;
    record.estimatedWage = units * record.ratePerUnit;
    record.date = date;
    record.notes = notes?.trim();

    await record.save();
    loadActivityRecords();
    return true;
  }

  // Delete Activity Record
  Future<void> deleteActivity(String id) async {
    await DatabaseService.activityBox.delete(id);
    loadActivityRecords();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final activityProvider = StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  return ActivityNotifier();
});
