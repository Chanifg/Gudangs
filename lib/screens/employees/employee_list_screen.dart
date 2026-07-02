import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employee_provider.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeState = ref.watch(employeeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            backgroundColor: colorScheme.surfaceVariant,
            child: const Icon(Icons.person, color: Color(0xFF006E2F)),
          ),
        ),
        title: const Text('Halo, Admin Gudang'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            color: colorScheme.primary,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Karyawan Gudang',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (val) {
                    ref.read(employeeProvider.notifier).setSearchKeyword(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama karyawan...',
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Active / Inactive Tab Buttons
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: employeeState.filterActive == null,
                      onSelected: (_) => ref.read(employeeProvider.notifier).setFilterActive(null),
                      selectedColor: colorScheme.primaryContainer.withOpacity(0.15),
                      checkmarkColor: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Aktif'),
                      selected: employeeState.filterActive == true,
                      onSelected: (_) => ref.read(employeeProvider.notifier).setFilterActive(true),
                      selectedColor: colorScheme.primaryContainer.withOpacity(0.15),
                      checkmarkColor: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Nonaktif'),
                      selected: employeeState.filterActive == false,
                      onSelected: (_) => ref.read(employeeProvider.notifier).setFilterActive(false),
                      selectedColor: colorScheme.primaryContainer.withOpacity(0.15),
                      checkmarkColor: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Employees List
          Expanded(
            child: employeeState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : employeeState.employees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Karyawan tidak ditemukan',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(employeeProvider.notifier).loadEmployees();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: employeeState.employees.length,
                          itemBuilder: (context, index) {
                            final emp = employeeState.employees[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Profile Initial Badge
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: emp.isActive
                                          ? colorScheme.primary.withOpacity(0.1)
                                          : Colors.grey[200],
                                      child: Text(
                                        emp.fullName.substring(0, emp.fullName.length > 1 ? 2 : 1).toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: emp.isActive ? colorScheme.primary : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Profile Information
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            emp.fullName,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: emp.isActive ? Colors.black : Colors.grey[600],
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            emp.position,
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            emp.phoneNumber,
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action Buttons & Toggle
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Edit profile & Toggle active
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                context.push('/employees/${emp.id}/edit');
                                              },
                                              icon: const Icon(Icons.edit_outlined, size: 20),
                                              tooltip: 'Edit Karyawan',
                                            ),
                                            Switch(
                                              value: emp.isActive,
                                              onChanged: (_) {
                                                ref.read(employeeProvider.notifier).toggleActive(emp.id);
                                              },
                                              activeColor: colorScheme.primaryContainer,
                                            ),
                                          ],
                                        ),
                                        
                                        // Shortcut to record daily activity
                                        if (emp.isActive) ...[
                                          const SizedBox(height: 4),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              context.push('/transactions/activity/add?employeeId=${emp.id}');
                                            },
                                            icon: const Icon(Icons.add, size: 14),
                                            label: const Text('Catat Kerja', style: TextStyle(fontSize: 11)),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: Size.zero,
                                            ),
                                          ),
                                        ],
                                      ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/employees/add');
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
