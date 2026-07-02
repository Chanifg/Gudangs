import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/employee_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/theme_toggle_button.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeState = ref.watch(employeeProvider);
    final settingsState = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: ProfileAvatar(
            imagePath: settingsState.profileImagePath,
            name: settingsState.profileName,
            radius: 20,
          ),
        ),
        title: Text('Halo, ${settingsState.profileName}'),
        actions: const [
          ThemeToggleButton(),
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
                    _buildFilterButton(
                      context: context,
                      label: 'Semua',
                      isSelected: employeeState.filterActive == null,
                      onTap: () => ref.read(employeeProvider.notifier).setFilterActive(null),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      context: context,
                      label: 'Aktif',
                      isSelected: employeeState.filterActive == true,
                      onTap: () => ref.read(employeeProvider.notifier).setFilterActive(true),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      context: context,
                      label: 'Nonaktif',
                      isSelected: employeeState.filterActive == false,
                      onTap: () => ref.read(employeeProvider.notifier).setFilterActive(false),
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
                                                  color: emp.isActive ? colorScheme.onSurface : Colors.grey[600],
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

  Widget _buildFilterButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
