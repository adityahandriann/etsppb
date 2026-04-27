import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'report_damage_screen.dart';
import 'report_payment_screen.dart';
import 'user_tickets_screen.dart';
import 'kost_location_screen.dart';
import '../providers/ticket_provider.dart';
import '../../../services/notification_service.dart';
import '../../auth/screens/profile_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  @override
  void initState() {
    super.initState();
    _scheduleAutoReminder();
  }

  Future<void> _scheduleAutoReminder() async {
    // Otomatis ingatkan tanggal 1 bulan depan jam 09:00
    DateTime now = DateTime.now();
    DateTime nextMonth = DateTime(now.year, now.month + 1, 1, 9, 0);
    
    await NotificationService().scheduleReminder(
      999,
      '🤖 Pengingat Otomatis SobatKost',
      'Halo! Jangan lupa siapkan pembayaran sewa untuk bulan depan ya.',
      nextMonth,
    );
  }

  int _calculateDaysLeft() {
    DateTime now = DateTime.now();
    // Cari tanggal 1 di bulan berikutnya
    DateTime firstOfNextMonth = DateTime(now.year, now.month + 1, 1);
    return firstOfNextMonth.difference(now).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    int daysLeft = _calculateDaysLeft();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SobatKost'),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Sapaan & Hitung Mundur
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, Selamat Datang!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const Text(
                        'Cek tagihan dan laporan Anda di sini.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$daysLeft',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const Text('Hari Lagi', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Fitur Broadcast Pengumuman Real-time
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final msg = snapshot.data!.docs.first['message'];
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_outlined, color: Color(0xFFDC2626)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pengumuman Terbaru',
                                style: TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg,
                                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),

            // Fitur Rincian Tagihan Digital
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tagihan Bulan Ini',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Icon(Icons.receipt_long_outlined, color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildBillRow('Harga Kamar', 'Rp 1.500.000', isDark: authProvider.isDarkMode),
                      _buildBillRow('Biaya Lantai', 'Rp 300.000', isDark: authProvider.isDarkMode),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),
                      _buildBillRow('Total Pembayaran', 'Rp 1.800.000', isBold: true, isDark: authProvider.isDarkMode),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Layanan Mandiri',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 12),

            _buildActionTile(
              context,
              'Lapor Kerusakan',
              'Kirim foto jika ada fasilitas rusak',
              Icons.handyman_outlined,
              () {
                context.read<TicketProvider>().clearImage();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportDamageScreen()));
              },
            ),
            _buildActionTile(
              context,
              'Kirim Bukti Bayar',
              'Konfirmasi pembayaran kost Anda',
              Icons.upload_file_outlined,
              () {
                context.read<TicketProvider>().clearImage();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportPaymentScreen()));
              },
            ),
            _buildActionTile(
              context,
              'Riwayat Laporan',
              'Cek status perbaikan & bayar',
              Icons.history_outlined,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserTicketsScreen())),
            ),
            _buildActionTile(
              context,
              'Lokasi Kost',
              'Lihat koordinat kost di Maps',
              Icons.map_outlined,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KostLocationScreen())),
            ),
            _buildActionTile(
              context,
              'Pengingat Bayar',
              'Atur jadwal notifikasi otomatis',
              Icons.notifications_none_outlined,
              () => _showNotificationSetup(context),
            ),
            
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.timer_outlined, size: 16),
                    label: const Text('Test Notifikasi (Jadwal 10 Detik)', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
                      await NotificationService().scheduleReminder(
                        888,
                        '⏲️ Test Jadwal Berhasil!',
                        'Ini adalah notifikasi yang dijadwalkan 10 detik lalu.',
                        scheduledTime,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifikasi dijadwalkan 10 detik lagi...')),
                        );
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.notifications_active_outlined, size: 16),
                    label: const Text('Test Notifikasi (Instan)', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      await NotificationService().showNotification(
                        '🔔 Test Instan Berhasil!',
                        'Notifikasi SobatKost sudah aktif.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Semantics(
        label: 'Tombol $title',
        button: true,
        hint: subtitle,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showNotificationSetup(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        DateTime scheduledTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (scheduledTime.isAfter(DateTime.now())) {
          await NotificationService().scheduleReminder(
            101,
            '📢 Pengingat Pembayaran Kost',
            'Halo! Saatnya melakukan pembayaran kost Anda.',
            scheduledTime,
          );

          if (!context.mounted) return;
          final String hour = pickedTime.hour.toString().padLeft(2, '0');
          final String minute = pickedTime.minute.toString().padLeft(2, '0');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pengingat diset untuk: ${scheduledTime.day}/${scheduledTime.month} pukul $hour:$minute'),
              backgroundColor: const Color(0xFF6366F1),
            ),
          );
        }
      }
    }
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white70 : Colors.black87)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? (isDark ? Colors.deepPurple[200] : Colors.deepPurple) : (isDark ? Colors.white : Colors.black))),
        ],
      ),
    );
  }
}
