import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee.dart';
import '../services/database_service.dart';

class JobTypeWageSummary {
  final String jobTypeId;
  final String jobTypeName;
  final double totalUnits;
  final double ratePerUnit;
  final double subtotal;

  JobTypeWageSummary({
    required this.jobTypeId,
    required this.jobTypeName,
    required this.totalUnits,
    required this.ratePerUnit,
    required this.subtotal,
  });
}

class EmployeeSalarySummary {
  final Employee employee;
  final List<JobTypeWageSummary> jobSummaries;
  final double totalSalary;
  final int totalActivities;

  EmployeeSalarySummary({
    required this.employee,
    required this.jobSummaries,
    required this.totalSalary,
    required this.totalActivities,
  });
}

class SalaryState {
  final DateTimeRange dateRange;
  final List<EmployeeSalarySummary> summaries;
  final double totalEstimatedWages;
  final int totalActivities;
  final bool isLoading;

  SalaryState({
    required this.dateRange,
    required this.summaries,
    required this.totalEstimatedWages,
    required this.totalActivities,
    this.isLoading = false,
  });

  SalaryState copyWith({
    DateTimeRange? dateRange,
    List<EmployeeSalarySummary>? summaries,
    double? totalEstimatedWages,
    int? totalActivities,
    bool? isLoading,
  }) {
    return SalaryState(
      dateRange: dateRange ?? this.dateRange,
      summaries: summaries ?? this.summaries,
      totalEstimatedWages: totalEstimatedWages ?? this.totalEstimatedWages,
      totalActivities: totalActivities ?? this.totalActivities,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SalaryNotifier extends StateNotifier<SalaryState> {
  SalaryNotifier()
      : super(SalaryState(
          dateRange: DateTimeRange(
            start: DateTime(DateTime.now().year, DateTime.now().month, 1),
            end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
          ),
          summaries: [],
          totalEstimatedWages: 0,
          totalActivities: 0,
        )) {
    calculateSalaries();
  }

  void setDateRange(DateTimeRange range) {
    state = state.copyWith(dateRange: range);
    calculateSalaries();
  }

  void calculateSalaries() {
    state = state.copyWith(isLoading: true);

    final start = state.dateRange.start.subtract(const Duration(seconds: 1));
    final end = state.dateRange.end.add(const Duration(days: 1));

    // 1. Fetch all activity records in date range
    final activities = DatabaseService.activityBox.values.where((act) {
      return act.date.isAfter(start) && act.date.isBefore(end);
    }).toList();

    // 2. Group by employee
    final Map<String, List<dynamic>> employeeActivities = {};
    for (final act in activities) {
      employeeActivities.putIfAbsent(act.employeeId, () => []).add(act);
    }

    final List<EmployeeSalarySummary> summaries = [];
    double overallTotal = 0;
    int overallActivities = 0;

    // 3. Process each employee
    for (final employeeId in employeeActivities.keys) {
      final employee = DatabaseService.employeesBox.get(employeeId);
      if (employee == null) continue; // Skip if employee was hard-deleted

      final empActs = employeeActivities[employeeId]!;
      
      // Group by job type
      final Map<String, List<dynamic>> jobActs = {};
      for (final act in empActs) {
        jobActs.putIfAbsent(act.jobTypeId, () => []).add(act);
      }

      final List<JobTypeWageSummary> jobSummaries = [];
      double empTotal = 0;

      for (final jobTypeId in jobActs.keys) {
        final acts = jobActs[jobTypeId]!;
        final firstAct = acts.first;

        final double totalUnits = acts.fold(0.0, (sum, act) => sum + act.units);
        final double subtotal = acts.fold(0.0, (sum, act) => sum + act.estimatedWage);

        jobSummaries.add(JobTypeWageSummary(
          jobTypeId: jobTypeId,
          jobTypeName: firstAct.jobTypeName,
          totalUnits: totalUnits,
          ratePerUnit: firstAct.ratePerUnit, // Snapshot rate from activity records
          subtotal: subtotal,
        ));
        
        empTotal += subtotal;
      }

      // Sort job summaries by job name
      jobSummaries.sort((a, b) => a.jobTypeName.compareTo(b.jobTypeName));

      summaries.add(EmployeeSalarySummary(
        employee: employee,
        jobSummaries: jobSummaries,
        totalSalary: empTotal,
        totalActivities: empActs.length,
      ));

      overallTotal += empTotal;
      overallActivities += empActs.length;
    }

    // Sort employee summaries by employee name
    summaries.sort((a, b) => a.employee.fullName.compareTo(b.employee.fullName));

    state = state.copyWith(
      summaries: summaries,
      totalEstimatedWages: overallTotal,
      totalActivities: overallActivities,
      isLoading: false,
    );
  }
}

final salaryProvider = StateNotifierProvider<SalaryNotifier, SalaryState>((ref) {
  return SalaryNotifier();
});
