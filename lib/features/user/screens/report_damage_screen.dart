import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/ticket_provider.dart';
import '../../admin/providers/local_db_provider.dart';

class ReportDamageScreen extends StatefulWidget {
  const ReportDamageScreen({super.key});

  @override
  State<ReportDamageScreen> createState() => _ReportDamageScreenState();
}

class _ReportDamageScreenState extends State<ReportDamageScreen> {
  String? _selectedKamar;
  final _deskripsiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pastikan data kamar terambil untuk dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalDbProvider>().fetchKamar();
    });
  }

  void _submit() async {
    final provider = context.read<TicketProvider>();
    final user = FirebaseAuth.instance.currentUser;

    if (_selectedKamar == null || _deskripsiController.text.isEmpty || provider.selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua bidang dan ambil foto!')),
      );
      return;
    }

    final success = await provider.sendDamageReport(
      user?.uid ?? '',
      _selectedKamar!,
      _deskripsiController.text,
    );

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan Kerusakan Berhasil Dikirim!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim laporan. Cek koneksi Anda.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final dbProvider = context.watch<LocalDbProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Kerusakan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Kamar Anda', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedKamar,
              hint: const Text('Pilih Nomor Kamar'),
              items: dbProvider.kamarList.map((k) {
                return DropdownMenuItem(
                  value: k['nomor_kamar'].toString(),
                  child: Text('Kamar ${k['nomor_kamar']}'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedKamar = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Deskripsi Kerusakan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _deskripsiController,
              decoration: InputDecoration(
                hintText: 'Misal: Kran air bocor, lampu mati...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            const Text('Bukti Foto', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ticketProvider.pickImage(ImageSource.camera),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: ticketProvider.selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(ticketProvider.selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Ketuk untuk Ambil Foto', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => ticketProvider.pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pilih dari Galeri'),
              ),
            ),
            const SizedBox(height: 32),
            ticketProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kirim Laporan Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}
