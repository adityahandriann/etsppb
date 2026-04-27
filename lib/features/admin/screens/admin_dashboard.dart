import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../screens/kamar_crud_screen.dart';
import '../screens/penghuni_crud_screen.dart';
import '../screens/admin_tickets_screen.dart';
import '../providers/local_db_provider.dart';
import '../../auth/screens/profile_screen.dart';
import '../../../widgets/custom_widgets.dart';
import 'announcement_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.watch<LocalDbProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil Saya',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: Icon(authProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: authProvider.isDarkMode ? 'Ganti ke Tema Terang' : 'Ganti ke Tema Gelap',
            onPressed: () => authProvider.toggleDarkMode(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Keluar dari Akun',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Bisnis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            // Card Statistik Pendapatan Premium
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Potensi Pendapatan',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${dbProvider.totalIncome}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${dbProvider.penghuniList.length} Kamar Terisi',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomBarChart(
                    label: 'Okupansi Kamar',
                    value: dbProvider.penghuniList.length,
                    total: dbProvider.kamarList.length,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Menu Manajemen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            // Grid Menu Utama
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildMenuCard(
                  context,
                  'Kamar',
                  Icons.meeting_room_outlined,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KamarCrudScreen())),
                ),
                _buildMenuCard(
                  context,
                  'Penghuni',
                  Icons.people_alt_outlined,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PenghuniCrudScreen())),
                ),
                _buildMenuCard(
                  context,
                  'Laporan',
                  Icons.assignment_outlined,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTicketsScreen())),
                ),
                _buildMenuCard(
                  context,
                  'Pengumuman',
                  Icons.campaign_outlined,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementManagementScreen())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tombol Ekspor (Full Width)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: const Text('Ekspor Laporan Bulanan'),
                onPressed: () => _exportReport(dbProvider),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Semantics(
      label: 'Menu $title',
      button: true,
      hint: 'Tekan untuk mengelola data $title',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportReport(LocalDbProvider db) {
    String report = "📊 LAPORAN SOBATKOST 📊\n";
    report += "--------------------------\n";
    report += "Total Kamar: ${db.kamarList.length}\n";
    report += "Kamar Terisi: ${db.penghuniList.length}\n";
    report += "Potensi Pendapatan: Rp ${db.totalIncome}\n\n";
    
    report += "📋 DAFTAR PENGHUNI:\n";
    for (var p in db.penghuniList) {
      report += "- ${p['nama_lengkap']} (Kamar ${p['nomor_kamar']})\n";
    }
    
    report += "\nDicetak pada: ${DateTime.now().toString()}";
    
    Share.share(report, subject: 'Laporan Bulanan SobatKost');
  }
}
