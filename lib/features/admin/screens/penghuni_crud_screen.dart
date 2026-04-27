import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/local_db_provider.dart';
import '../../../widgets/custom_widgets.dart';

class PenghuniCrudScreen extends StatefulWidget {
  const PenghuniCrudScreen({super.key});

  @override
  State<PenghuniCrudScreen> createState() => _PenghuniCrudScreenState();
}

class _PenghuniCrudScreenState extends State<PenghuniCrudScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalDbProvider>().fetchPenghuni();
      context.read<LocalDbProvider>().fetchKamar();
    });
  }

  void _approveUser(Map<String, dynamic> userData, String docId) async {
    final dbProvider = context.read<LocalDbProvider>();
    
    final kamar = dbProvider.kamarList.firstWhere(
      (k) => k['nomor_kamar'] == userData['roomNumber'], 
      orElse: () => {}
    );
    
    if (kamar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamar tidak ditemukan!')));
      return;
    }

    // CEK APAKAH KAMAR SUDAH TERISI DI SQLITE
    final isOccupied = dbProvider.penghuniList.any((p) => p['nomor_kamar'] == userData['roomNumber']);
    if (isOccupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kamar ${userData['roomNumber']} sudah terisi! Hapus penghuni lama terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await dbProvider.addPenghuni(kamar['id_kamar'], userData['name'], userData['wa'], DateTime.now().toString().split(' ').first);
    await FirebaseFirestore.instance.collection('users').doc(docId).update({'isApproved': true});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penghuni berhasil dikonfirmasi!'), backgroundColor: Colors.green));
  }

  void _approveMove(Map<String, dynamic> request, String docId) async {
    final dbProvider = context.read<LocalDbProvider>();
    
    // 1. Cari ID Kamar baru di SQLite
    final newKamar = dbProvider.kamarList.firstWhere((k) => k['nomor_kamar'] == request['toRoom'], orElse: () => {});
    if (newKamar.isEmpty) return;

    // 2. Cari data penghuni lama di SQLite berdasarkan WA atau Nama
    // Kita asumsikan WA unik untuk mencocokkan user Firestore dengan SQLite
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(request['uid']).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final userWa = userData['wa'];

    final penghuniLokal = dbProvider.penghuniList.firstWhere((p) => p['nomor_wa'] == userWa, orElse: () => {});
    
    if (penghuniLokal.isNotEmpty) {
      // 3. Update Kamar di SQLite
      await dbProvider.editPenghuni(
        penghuniLokal['id_penghuni'],
        newKamar['id_kamar'],
        penghuniLokal['nama_lengkap'],
        penghuniLokal['nomor_wa'],
        penghuniLokal['tanggal_masuk'],
      );
    }

    // 4. Update Kamar di Firestore
    await FirebaseFirestore.instance.collection('users').doc(request['uid']).update({
      'roomNumber': request['toRoom'],
    });

    // 5. Hapus Request
    await FirebaseFirestore.instance.collection('room_move_requests').doc(docId).delete();

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perpindahan kamar disetujui!'), backgroundColor: Colors.blue));
  }

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.watch<LocalDbProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Penghuni'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Daftar Aktif'),
            Tab(text: 'Pendaftaran Baru'),
            Tab(text: 'Pindah Kamar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLocalList(dbProvider),
          _buildPendingList(),
          _buildMoveRequests(),
        ],
      ),
    );
  }

  Widget _buildLocalList(LocalDbProvider db) {
    if (db.isLoading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: db.penghuniList.length,
      itemBuilder: (context, index) {
        final p = db.penghuniList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(child: Text(p['nomor_kamar'].toString())),
            title: Text(p['nama_lengkap']),
            subtitle: Text('WA: ${p['nomor_wa']} • Kamar: ${p['nomor_kamar']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => db.deletePenghuni(p['id_penghuni']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').where('isApproved', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const EmptyState(icon: Icons.verified_user_outlined, title: 'Tidak Ada Antrean', subtitle: 'Semua sudah dikonfirmasi.');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text('Kamar: ${data['roomNumber']} • WA: ${data['wa']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => docs[index].reference.delete()),
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _approveUser(data, docId)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMoveRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('room_move_requests').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const EmptyState(icon: Icons.swap_horiz, title: 'Antrean Kosong', subtitle: 'Belum ada permintaan pindah kamar.');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Icon(Icons.swap_horiz, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRoomBadge(data['fromRoom'], 'Lama'),
                        const Icon(Icons.arrow_forward, size: 16),
                        _buildRoomBadge(data['toRoom'], 'Baru'),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => docs[index].reference.delete(), child: const Text('Tolak'))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(onPressed: () => _approveMove(data, docId), child: const Text('Setujui'))),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoomBadge(String room, String label) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
          child: Text(room, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
