import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/inventory')) return 1;
    if (location.startsWith('/transactions')) return 2;
    if (location.startsWith('/employees')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/inventory');
        break;
      case 2:
        context.go('/transactions');
        break;
      case 3:
        context.go('/employees');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }

  void _showQuickActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // transparent to show rounded corners
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Menu Operasional Gudang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1C30), // darkNavy
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih tindakan cepat yang ingin Anda lakukan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF565E74), // slateGrey
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const Text(
                          'PRODUKSI & AKTIVITAS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF565E74), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        _buildActionItem(
                          context: context,
                          icon: Icons.precision_manufacturing_outlined,
                          iconColor: const Color(0xFF006E2F), // primaryGreen
                          title: 'Eksekusi Produksi (BOM)',
                          description: 'Proses bahan baku mentah menjadi barang jadi',
                          route: '/production',
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.engineering_outlined,
                          iconColor: const Color(0xFF006E2F), // primaryGreen
                          title: 'Catat Aktivitas Kerja',
                          description: 'Catat pekerjaan harian karyawan untuk upah',
                          route: '/transactions/activity/add',
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.arrow_downward,
                          iconColor: const Color(0xFF22C55E), // emeraldGreen
                          title: 'Barang Masuk (Inbound)',
                          description: 'Beli dan tambah stok bahan baku mentah',
                          route: '/transactions/inbound/add',
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.arrow_upward,
                          iconColor: const Color(0xFFBA1A1A), // errorRed
                          title: 'Barang Keluar (Outbound)',
                          description: 'Jual dan kurangi stok barang jadi',
                          route: '/transactions/outbound/add',
                        ),
                        
                        const SizedBox(height: 16),
                        const Text(
                          'REGISTRASI DATA BARU',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF565E74), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        _buildActionItem(
                          context: context,
                          icon: Icons.playlist_add_outlined,
                          iconColor: const Color(0xFF565E74),
                          title: 'Tambah Bahan Baku',
                          description: 'Daftarkan tipe bahan baku baru',
                          route: '/inventory/raw-materials/add',
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.library_add_outlined,
                          iconColor: const Color(0xFF565E74),
                          title: 'Tambah Barang Jadi',
                          description: 'Daftarkan produk barang jadi baru',
                          route: '/inventory/finished-goods/add',
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.person_add_outlined,
                          iconColor: const Color(0xFF565E74),
                          title: 'Tambah Karyawan Baru',
                          description: 'Daftarkan data karyawan baru ke sistem',
                          route: '/employees/add',
                        ),
                        
                        const SizedBox(height: 16),
                        const Text(
                          'RIWAYAT & LAPORAN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF565E74), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        _buildActionItem(
                          context: context,
                          icon: Icons.history,
                          iconColor: const Color(0xFF0B1C30),
                          title: 'Riwayat Produksi',
                          description: 'Log proses perakitan barang & HPP',
                          route: '/production/history',
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.receipt_long_outlined,
                          iconColor: const Color(0xFF006E2F),
                          title: 'Daftar Barang Masuk',
                          description: 'Lihat riwayat pembelian bahan baku',
                          route: '/transactions/inbound',
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.assignment_turned_in_outlined,
                          iconColor: const Color(0xFFBA1A1A),
                          title: 'Daftar Barang Keluar',
                          description: 'Lihat log pengiriman & status jual',
                          route: '/transactions/outbound',
                        ),
                        _buildActionItem(
                          context: context,
                          icon: Icons.receipt_outlined,
                          iconColor: const Color(0xFF565E74),
                          title: 'Daftar Formula BOM',
                          description: 'Kelola resep komponen barang jadi',
                          route: '/inventory/bom',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String route,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // close bottom sheet
          context.push(route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1C30), // darkNavy
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF565E74), // slateGrey
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF565E74), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showQuickActionsBottomSheet(context),
      backgroundColor: const Color(0xFF006E2F), // primaryGreen
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tooltip: 'Aksi Cepat',
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;
    final selectedIndex = _getSelectedIndex(context);
    final showGlobalFAB = selectedIndex == 0 || selectedIndex == 2;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar Navigation for Desktop
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Logo / App Name
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          Icons.warehouse,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'GUDANGS',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Sidebar Items
                  _buildSidebarItem(
                    context: context,
                    icon: Icons.home,
                    label: 'Beranda',
                    isSelected: selectedIndex == 0,
                    onTap: () => _onItemTapped(0, context),
                  ),
                  _buildSidebarItem(
                    context: context,
                    icon: Icons.inventory_2,
                    label: 'Inventori',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onItemTapped(1, context),
                  ),
                  _buildSidebarItem(
                    context: context,
                    icon: Icons.history,
                    label: 'Histori Transaksi',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onItemTapped(2, context),
                  ),
                  _buildSidebarItem(
                    context: context,
                    icon: Icons.groups,
                    label: 'Karyawan',
                    isSelected: selectedIndex == 3,
                    onTap: () => _onItemTapped(3, context),
                  ),
                  _buildSidebarItem(
                    context: context,
                    icon: Icons.person,
                    label: 'Profil & Pengaturan',
                    isSelected: selectedIndex == 4,
                    onTap: () => _onItemTapped(4, context),
                  ),
                  
                  const Spacer(),
                  
                  // Footer info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Gudangs v1.1.0\nManufacturing & BOM',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content Area
            Expanded(
              child: child,
            ),
          ],
        ),
        floatingActionButton: showGlobalFAB ? _buildFAB(context) : null,
      );
    }

    // Mobile View with BottomNavigationBar
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory_2),
                label: 'Inventori',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                activeIcon: Icon(Icons.history, fill: 1),
                label: 'Histori',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups),
                label: 'Karyawan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Pengaturan',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: showGlobalFAB ? _buildFAB(context) : null,
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
      ),
    );
  }
}
