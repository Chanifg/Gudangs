import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../core/formatters.dart';
import '../../services/database_service.dart';
import '../../providers/raw_material_provider.dart';
import '../../providers/finished_good_provider.dart';
import '../../providers/bom_provider.dart';
import '../../providers/inbound_provider.dart';
import '../../providers/outbound_provider.dart';
import '../../providers/production_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/update_service.dart';

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

  void _showSeedDummyDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Data Dummy'),
        content: const Text(
            'Tindakan ini akan MENGHAPUS SEMUA DATA yang ada dan menggantinya dengan data dummy baru (Bahan Baku, Barang Jadi, BOM, Karyawan, dan Transaksi). Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006E2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation dialog
              
              try {
                await DatabaseService.seedDummyData();
                
                // Invalidate all providers to reload data from Hive
                ref.invalidate(rawMaterialProvider);
                ref.invalidate(finishedGoodProvider);
                ref.invalidate(bomProvider);
                ref.invalidate(inboundProvider);
                ref.invalidate(outboundProvider);
                ref.invalidate(productionProvider);
                ref.invalidate(employeeProvider);
                ref.invalidate(activityProvider);
                ref.invalidate(settingsProvider);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Berhasil memuat data dummy!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: const Color(0xFFBA1A1A)),
                  );
                }
              }
            },
            child: const Text('Ya, Buat Data Dummy'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data'),
        content: const Text(
            'Tindakan ini akan MENGHAPUS PERMANEN seluruh data transaksi, inventori, dan karyawan Anda. Tindakan ini tidak dapat dibatalkan. Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation dialog
              
              try {
                await DatabaseService.clearAllData();
                
                // Invalidate all providers
                ref.invalidate(rawMaterialProvider);
                ref.invalidate(finishedGoodProvider);
                ref.invalidate(bomProvider);
                ref.invalidate(inboundProvider);
                ref.invalidate(outboundProvider);
                ref.invalidate(productionProvider);
                ref.invalidate(employeeProvider);
                ref.invalidate(activityProvider);
                ref.invalidate(settingsProvider);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seluruh data berhasil dihapus!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: const Color(0xFFBA1A1A)),
                  );
                }
              }
            },
            child: const Text('Ya, Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _handleCheckForUpdate(BuildContext context, String currentVersion) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Memeriksa pembaruan...'),
              ],
            ),
          ),
        ),
      ),
    );

    final updateInfo = await UpdateService.checkForUpdate(currentVersion);
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    if (updateInfo == null) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sudah Terbaru'),
            content: const Text('Aplikasi Anda sudah menggunakan versi terbaru.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // New update found! Show release notes & download prompt
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _UpdateDialog(updateInfo: updateInfo),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: const Text('Profil & Pengaturan'),
        actions: const [
          ThemeToggleButton(),
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
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    context.push('/more/edit-profile');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          imagePath: settingsState.profileImagePath,
                          name: settingsState.profileName,
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                settingsState.profileName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                settingsState.profileCompanyName.isNotEmpty
                                    ? settingsState.profileCompanyName
                                    : 'Gudang Utama',
                                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                              ),
                              if (settingsState.profilePhone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  settingsState.profilePhone,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                      ],
                    ),
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
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ListTile(
                      leading: Icon(Icons.tune_outlined, color: colorScheme.primary),
                      title: const Text('Koreksi & Opname Stok'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/more/stock-adjustment');
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ListTile(
                      leading: Icon(Icons.history_outlined, color: colorScheme.primary),
                      title: const Text('Log Aktivitas Sistem'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/more/audit-log');
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
              const SizedBox(height: 24),

              // Developer Options / Data Management Section
              Text('Developer Options & Data', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storage, color: Colors.blue),
                      title: const Text('Buat Data Dummy'),
                      subtitle: const Text('Isi database dengan data contoh untuk uji coba'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSeedDummyDataDialog(context, ref),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Hapus Semua Data'),
                      subtitle: const Text('Kosongkan semua data di aplikasi'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showClearAllDataDialog(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Text(
                      'Gudangs v${settingsState.appVersion}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => _handleCheckForUpdate(context, settingsState.appVersion),
                      icon: const Icon(Icons.system_update_alt_outlined, size: 16),
                      label: const Text('Periksa Pembaruan', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const _UpdateDialog({required this.updateInfo});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _downloadProgress;

  @override
  Widget build(BuildContext context) {
    final updateInfo = widget.updateInfo;
    String status = 'Tersedia versi baru: ${updateInfo.latestVersion}\n\nCatatan Rilis:\n${updateInfo.releaseNotes}';

    return AlertDialog(
      title: const Text('Pembaruan Tersedia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status, style: const TextStyle(fontSize: 13)),
          if (_downloadProgress != null) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _downloadProgress),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Mengunduh: ${(_downloadProgress! * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      actions: _downloadProgress != null
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _downloadProgress = 0.0;
                  });

                  final file = await UpdateService.downloadApk(
                    updateInfo.downloadUrl,
                    (progress) {
                      setState(() {
                        _downloadProgress = progress;
                      });
                    },
                  );

                  if (file != null) {
                    final success = await UpdateService.installApk(file.path);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal memasang APK. Harap izinkan instalasi dari sumber tidak dikenal.')),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal mengunduh pembaruan.')),
                      );
                    }
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Perbarui Sekarang'),
              ),
            ],
    );
  }
}
