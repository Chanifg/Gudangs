import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/salary_provider.dart';
import '../../core/formatters.dart';

class SalaryScreen extends ConsumerWidget {
  const SalaryScreen({super.key});

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref, DateTimeRange currentRange) async {
    // Show a simple date range picker or date picker for month/year selection
    // To make it simple and elegant, we can use the default showDateRangePicker
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
        children: [
          // Period selector banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: InkWell(
              onTap: () => _selectDateRange(context, ref, salaryState.dateRange),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Periode Aktif',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$startDateStr - $endDateStr',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),

          // Bento Summary Widgets
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: colorScheme.primary.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL UPAH ESTIMASI', style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 6),
                          Text(
                            Formatters.formatRupiah(salaryState.totalEstimatedWages),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL AKTIVITAS', style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 6),
                          Text(
                            '${salaryState.totalActivities} Kerja',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Card(
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.surfaceVariant,
                                    child: const Icon(Icons.person, color: Color(0xFF006E2F)),
                                  ),
                                  title: Text(
                                    summary.employee.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${summary.employee.position} • ${summary.totalActivities} aktivitas',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: Text(
                                    Formatters.formatRupiah(summary.totalSalary),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  children: [
                                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'RINCIAN PEKERJAAN',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...summary.jobSummaries.map((job) {
                                            final unitStr = job.totalUnits.toStringAsFixed(job.totalUnits % 1 == 0 ? 0 : 1);
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 10.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        job.jobTypeName,
                                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '$unitStr unit x ${Formatters.formatRupiah(job.ratePerUnit)}',
                                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    Formatters.formatRupiah(job.subtotal),
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
