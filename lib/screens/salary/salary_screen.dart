import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/salary_provider.dart';
import '../../core/formatters.dart';
import '../../models/employee.dart';

class SalaryScreen extends ConsumerWidget {
  const SalaryScreen({super.key});

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref, DateTimeRange currentRange) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: currentRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih Periode Laporan Upah',
      saveText: 'Pilih',
    );

    if (picked != null && picked != currentRange) {
      ref.read(salaryProvider.notifier).setDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salaryState = ref.watch(salaryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final startDateStr = Formatters.formatDate(salaryState.dateRange.start);
    final endDateStr = Formatters.formatDate(salaryState.dateRange.end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimasi Gaji Karyawan'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Period selector banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: InkWell(
              onTap: () => _selectDateRange(context, ref, salaryState.dateRange),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF), // softBlueGray
                  border: Border.all(color: const Color(0xFFBCCBB9)), // borderGray
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF006E2F), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$startDateStr - $endDateStr',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B1C30), // darkNavy
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF006E2F)),
                  ],
                ),
              ),
            ),
          ),

          // Bento Summary Widgets
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                // Total Estimasi Gaji Card
                Expanded(
                  child: Container(
                    height: 96,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, color: Color(0xFF006E2F), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Total Estimasi Gaji',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF565E74), // slateGrey
                              ),
                            ),
                          ],
                        ),
                        Text(
                          Formatters.formatRupiah(salaryState.totalEstimatedWages),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B1C30), // darkNavy
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Total Aktivitas Card (with blur effect)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Blur radial effect on top right
                          Positioned(
                            right: -16,
                            top: -16,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, color: Color(0xFF565E74), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total Aktivitas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF565E74), // slateGrey
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${salaryState.totalActivities}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B1C30), // darkNavy
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Header for List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Rincian Karyawan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    Text(
                      '${salaryState.summaries.length} Karyawan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF565E74),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ],
            ),
          ),

          // Salary Breakdown List
          Expanded(
            child: salaryState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : salaryState.summaries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Tidak ada aktivitas kerja pada periode ini.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(salaryProvider.notifier).calculateSalaries();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: salaryState.summaries.length,
                          itemBuilder: (context, index) {
                            final summary = salaryState.summaries[index];
                            return EmployeeSalaryCard(summary: summary);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class EmployeeSalaryCard extends StatefulWidget {
  final EmployeeSalarySummary summary;

  const EmployeeSalaryCard({super.key, required this.summary});

  @override
  State<EmployeeSalaryCard> createState() => _EmployeeSalaryCardState();
}

class _EmployeeSalaryCardState extends State<EmployeeSalaryCard> {
  bool _isExpanded = false;

  String _getInitials(String name) {
    final clean = name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final initials = _getInitials(summary.employee.fullName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Row (Clickable)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF4FF), // softBlueGray
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFF006E2F), // primaryGreen
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Employee details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.employee.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B1C30), // darkNavy
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${summary.totalActivities} Aktivitas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF565E74), // slateGrey
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Salary Info & Expand icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatRupiah(summary.totalSalary),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isExpanded ? const Color(0xFF006E2F) : const Color(0xFF0B1C30),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF565E74),
                  ),
                ],
              ),
            ),
          ),

          // Detail Breakdown (Expanded)
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF4FF), // softBlueGray
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: summary.jobSummaries.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Detail tidak tersedia',
                          style: TextStyle(color: Color(0xFF565E74), fontSize: 13),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Header
                        const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Tipe Pekerjaan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF565E74),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Unit',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF565E74),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Tarif',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF565E74),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Total',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF565E74),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: Color(0xFFBCCBB9)),
                        const SizedBox(height: 4),
                        // Table Body
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: summary.jobSummaries.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: Color(0xFFE2E8F0),
                          ),
                          itemBuilder: (context, idx) {
                            final job = summary.jobSummaries[idx];
                            final unitStr = job.totalUnits.toStringAsFixed(job.totalUnits % 1 == 0 ? 0 : 1);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      job.jobTypeName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0B1C30),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      unitStr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF0B1C30),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      Formatters.formatRupiah(job.ratePerUnit),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF565E74),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      Formatters.formatRupiah(job.subtotal),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0B1C30),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

