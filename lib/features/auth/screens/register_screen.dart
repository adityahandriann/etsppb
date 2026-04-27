import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _waController = TextEditingController();
  String _selectedRole = 'user';
  String? _selectedKamar;
  
  List<String> _occupiedRooms = [];
  bool _isFetchingRooms = true;

  @override
  void initState() {
    super.initState();
    _fetchOccupiedRooms();
  }

  Future<void> _fetchOccupiedRooms() async {
    if (!mounted) return;
    setState(() => _isFetchingRooms = true);
    try {
      // Mencoba mengambil data kamar terisi
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();
      
      if (mounted) {
        setState(() {
          _occupiedRooms = snapshot.docs.map((doc) {
            final data = doc.data();
            return (data['roomNumber'] ?? '').toString().trim();
          }).where((room) => room.isNotEmpty).toList();
          _isFetchingRooms = false;
        });
      }
    } catch (e) {
      // Jika gagal (karena permission atau index), kita biarkan list kosong 
      // dan biarkan User mendaftar (validasi dilakukan Admin nanti)
      if (mounted) {
        setState(() {
          _occupiedRooms = [];
          _isFetchingRooms = false;
        });
        debugPrint("Firestore Notice: Gagal memuat filter kamar (mungkin aturan Firestore belum diatur).");
      }
    }
  }

  List<String> _getAvailableRooms() {
    List<String> rooms = [];
    for (int l = 1; l <= 3; l++) {
      for (int n = 1; n <= 10; n++) {
        String room = "$l.$n";
        if (!_occupiedRooms.contains(room)) {
          rooms.add(room);
        }
      }
    }
    return rooms;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Registrasi Akun', style: TextStyle(color: Colors.black, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Akun Baru',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              const Text('Lengkapi data di bawah untuk bergabung.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(child: _buildRoleCard('user', 'Anak Kost', Icons.person_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRoleCard('admin', 'Admin Kost', Icons.admin_panel_settings_outlined)),
                ],
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline, size: 18)),
                obscureText: true,
              ),
              
              if (_selectedRole == 'user') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.badge_outlined, size: 18)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _waController,
                  decoration: const InputDecoration(labelText: 'Nomor WhatsApp', prefixIcon: Icon(Icons.phone_android_outlined, size: 18)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                
                _isFetchingRooms 
                  ? const LinearProgressIndicator()
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedKamar,
                      isExpanded: true,
                      hint: const Text('Pilih Nomor Kamar', style: TextStyle(fontSize: 14)),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.meeting_room_outlined, size: 18)),
                      items: _getAvailableRooms().map((room) => DropdownMenuItem(value: room, child: Text('Kamar $room', style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) => setState(() => _selectedKamar = val),
                    ),
              ],
              
              const SizedBox(height: 32),
              if (authProvider.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(authProvider.errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email dan Password wajib diisi!')));
                            return;
                          }

                          if (_selectedRole == 'user') {
                            if (_nameController.text.isEmpty || _waController.text.isEmpty || _selectedKamar == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi Nama, WA, dan Kamar!')));
                              return;
                            }
                            
                            // PROTEKSI CRASH: Gunakan Try-Catch untuk pengecekan ganda
                            try {
                              final check = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('roomNumber', isEqualTo: _selectedKamar)
                                  .get();
                              
                              if (check.docs.isNotEmpty) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maaf, kamar ini sudah terdaftar!'), backgroundColor: Colors.red));
                                return;
                              }
                            } catch (e) {
                              debugPrint("Pengecekan ganda dilewati: $e");
                            }
                          }

                          bool success = await authProvider.register(
                            email: _emailController.text,
                            password: _passwordController.text,
                            role: _selectedRole,
                            name: _nameController.text,
                            wa: _waController.text,
                            roomNumber: _selectedKamar,
                          );

                          if (!mounted) return;

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_selectedRole == 'user' ? 'Pendaftaran berhasil! Menunggu konfirmasi admin.' : 'Registrasi Berhasil!')),
                            );
                            Navigator.pop(context);
                          }
                        },
                  child: authProvider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Daftar Akun Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() {
        _selectedRole = role;
        if (role == 'admin') {
          _nameController.clear();
          _waController.clear();
          _selectedKamar = null;
        }
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 20),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
