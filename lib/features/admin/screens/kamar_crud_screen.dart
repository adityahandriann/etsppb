import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/local_db_provider.dart';
import '../../../widgets/custom_widgets.dart';

class KamarCrudScreen extends StatefulWidget {
  const KamarCrudScreen({super.key});

  @override
  State<KamarCrudScreen> createState() => _KamarCrudScreenState();
}

class _KamarCrudScreenState extends State<KamarCrudScreen> {
  final _nomorController = TextEditingController();
  final _hargaController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedTipe = 'Reguler';
  int _selectedLantai = 1;
  String _searchQuery = '';

  void _calculatePrice() {
    int basePrice = 0;
    int multiplier = 0;

    if (_selectedTipe == 'Reguler') {
      basePrice = 1300000;
      multiplier = 100000;
    } else if (_selectedTipe == 'VIP') {
      basePrice = 1500000;
      multiplier = 150000;
    } else if (_selectedTipe == 'VVIP') {
      basePrice = 1800000;
      multiplier = 250000;
    }

    // Hitung jarak dari Lantai 3 (Lantai 3 = 0, Lantai 2 = 1, Lantai 1 = 2)
    int floorStep = 3 - _selectedLantai;
    int floorBonus = floorStep * multiplier;
    
    _hargaController.text = (basePrice + floorBonus).toString();
  }

  @override
  void initState() {
    super.initState();
    _calculatePrice(); // Hitung harga awal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalDbProvider>().fetchKamar();
    });
  }

  void _showForm([Map<String, dynamic>? kamar]) {
    if (kamar != null) {
      _nomorController.text = kamar['nomor_kamar'];
      _selectedTipe = kamar['tipe_kamar'];
      _hargaController.text = kamar['harga_sewa'].toString();
      // Kita asumsikan lantai bisa didapat dari nomor kamar (misal: "1.1" artinya lantai 1)
      _selectedLantai = int.tryParse(kamar['nomor_kamar'].split('.').first) ?? 1;
    } else {
      _nomorController.clear();
      _selectedTipe = 'Reguler';
      _selectedLantai = 1;
      _calculatePrice();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(kamar == null ? 'Tambah Kamar' : 'Edit Kamar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomorController,
                decoration: const InputDecoration(labelText: 'Nomor Kamar'),
                readOnly: true, // Nomor kamar tidak boleh diubah
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedTipe,
                decoration: const InputDecoration(labelText: 'Tipe Kamar'),
                items: const [
                  DropdownMenuItem(value: 'Reguler', child: Text('Reguler')),
                  DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                  DropdownMenuItem(value: 'VVIP', child: Text('VVIP')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      _selectedTipe = val;
                      _calculatePrice();
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedLantai,
                decoration: const InputDecoration(labelText: 'Pilih Lantai'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Lantai 1')),
                  DropdownMenuItem(value: 2, child: Text('Lantai 2')),
                  DropdownMenuItem(value: 3, child: Text('Lantai 3')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      _selectedLantai = val;
                      _calculatePrice();
                    });
                  }
                },
              ),
              TextField(
                controller: _hargaController,
                decoration: const InputDecoration(labelText: 'Harga Sewa (Otomatis)'),
                keyboardType: TextInputType.number,
                readOnly: true, // Agar tidak bisa diedit manual
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final dbProvider = context.read<LocalDbProvider>();
                if (kamar == null) {
                  dbProvider.addKamar(
                    _nomorController.text,
                    _selectedTipe,
                    int.tryParse(_hargaController.text) ?? 0,
                  );
                } else {
                  dbProvider.updateKamar(
                    kamar['id_kamar'],
                    _nomorController.text,
                    _selectedTipe,
                    int.tryParse(_hargaController.text) ?? 0,
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbProvider = context.watch<LocalDbProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Data Kamar (Fixed)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nomor kamar...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: dbProvider.isLoading
                ? ListView.builder(
                    itemCount: 5,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SkeletonLoading(height: 80),
                    ),
                  )
                : dbProvider.kamarList.isEmpty
                    ? const EmptyState(
                        icon: Icons.meeting_room_outlined,
                        title: 'Kamar Masih Kosong',
                        subtitle: 'Belum ada data kamar yang terdaftar di sistem.',
                      )
                    : ListView.builder(
                        itemCount: dbProvider.kamarList.where((k) => 
                          k['nomor_kamar'].toString().toLowerCase().contains(_searchQuery)
                        ).length,
                        itemBuilder: (context, index) {
                          final filteredList = dbProvider.kamarList.where((k) => 
                            k['nomor_kamar'].toString().toLowerCase().contains(_searchQuery)
                          ).toList();
                          final kamar = filteredList[index];
                          final isOccupied = dbProvider.isRoomOccupied(kamar['id_kamar']);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.meeting_room_outlined, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Kamar ${kamar['nomor_kamar']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isOccupied ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isOccupied ? 'TERISI' : 'KOSONG',
                                                style: TextStyle(
                                                  color: isOccupied ? const Color(0xFF991B1B) : const Color(0xFF166534),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${kamar['tipe_kamar']} • Rp ${kamar['harga_sewa']}',
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                                    onPressed: () => _showForm(kamar),
                                    tooltip: 'Edit Detail Kamar',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
