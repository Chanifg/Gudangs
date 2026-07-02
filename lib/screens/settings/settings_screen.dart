import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';
import '../../core/formatters.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah PIN Keamanan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN Lama',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'PIN harus 6 digit angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN Baru',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'PIN baru harus 6 digit angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi PIN Baru',
                  counterText: '',
                ),
                validator: (value) {
                  if (value != newPinController.text) {
                    return 'PIN konfirmasi tidak cocok';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await ref.read(settingsProvider.notifier).changePin(
                      oldPinController.text,
                      newPinController.text,
                    );
                if (success) {
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN berhasil diperbarui!')),
                    );
                  }
                } else {
                  if (ctx.mounted) {
                    final error = ref.read(settingsProvider).errorMessage ?? 'Gagal mengubah PIN';
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  }
                }
              }
            },
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.person, color: Color(0xFF006E2F)),
          ),
        ),
        title: const Text('Profil & Pengaturan'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            color: colorScheme.primary,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Account Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.account_box, color: colorScheme.primary, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admin Gudang Utama',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Offline Mode',
                                style: TextStyle(fontSize: 10, color: colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Operational Section Links
              Text('Operasional & Laporan', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.bar_chart_outlined, color: colorScheme.primary),
                      title: const Text('Statistik Operasional'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/more/stats');
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ListTile(
                      leading: Icon(Icons.payments_outlined, color: colorScheme.primary),
                      title: const Text('Estimasi Gaji Karyawan'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/more/salary');
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ListTile(
                      leading: Icon(Icons.table_chart_outlined, color: colorScheme.primary),
                      title: const Text('Cetak & Ekspor Laporan'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/more/reports');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security settings Section
              Text('Keamanan Aplikasi', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.fingerprint, color: colorScheme.primary),
                      title: const Text('Login Biometrik'),
                      subtitle: const Text('Aktifkan Sidik Jari / Face ID'),
                      value: settingsState.isBiometricEnabled,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).toggleBiometric(val);
                      },
                      activeThumbColor: colorScheme.primaryContainer,
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ListTile(
                      leading: Icon(Icons.lock_outline, color: colorScheme.primary),
                      title: const Text('Ubah PIN Keamanan'),
                      subtitle: const Text('Ganti PIN masuk 6-digit'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showChangePinDialog(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Job types settings section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tarif & Jenis Pekerjaan', style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: () {
                      context.push('/more/job-types/add');
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (settingsState.jobTypes.isEmpty) ...[
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text('Belum ada jenis pekerjaan. Tambahkan dulu.'),
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: settingsState.jobTypes.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final jt = settingsState.jobTypes[index];
                      return ListTile(
                        title: Text(jt.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${Formatters.formatRupiah(jt.ratePerUnit)} per unit'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () {
                                context.push('/more/job-types/${jt.id}/edit');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () async {
                                final success = await ref.read(settingsProvider.notifier).deleteJobType(jt.id);
                                if (!success && context.mounted) {
                                  final error = ref.read(settingsProvider).errorMessage ?? 'Gagal menghapus';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
