import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class LocalDbProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _kamarList = [];
  List<Map<String, dynamic>> get kamarList => _kamarList;

  List<Map<String, dynamic>> _penghuniList = [];
  List<Map<String, dynamic>> get penghuniList => _penghuniList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get totalIncome {
    int total = 0;
    for (var kamar in _kamarList) {
      if (isRoomOccupied(kamar['id_kamar'])) {
        total += (kamar['harga_sewa'] as int);
      }
    }
    return total;
  }

  bool isRoomOccupied(int idKamar) {
    return _penghuniList.any((p) => p['id_kamar'] == idKamar);
  }

  Future<void> fetchKamar() async {
    _isLoading = true;
    notifyListeners();
    _kamarList = await DatabaseHelper.instance.readAllKamar();
    
    // Inisialisasi kamar otomatis jika kosong
    if (_kamarList.isEmpty) {
      await _initializeFixedRooms();
      _kamarList = await DatabaseHelper.instance.readAllKamar();
    }
    
    _penghuniList = await DatabaseHelper.instance.readAllPenghuni();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _initializeFixedRooms() async {
    for (int lantai = 1; lantai <= 3; lantai++) {
      for (int nomor = 1; nomor <= 10; nomor++) {
        String nomorKamar = "$lantai.$nomor";
        String tipe;
        int harga;

        if (nomor <= 5) {
          tipe = "Reguler";
          harga = 1500000;
        } else if (nomor <= 8) {
          tipe = "VIP";
          harga = 2500000;
        } else {
          tipe = "VVIP";
          harga = 3500000;
        }

        await DatabaseHelper.instance.createKamar({
          'nomor_kamar': nomorKamar,
          'tipe_kamar': tipe,
          'harga_sewa': harga,
        });
      }
    }
  }

  Future<void> addKamar(String nomor, String tipe, int harga) async {
    await DatabaseHelper.instance.createKamar({
      'nomor_kamar': nomor,
      'tipe_kamar': tipe,
      'harga_sewa': harga,
    });
    await fetchKamar();
  }

  Future<void> updateKamar(int id, String nomor, String tipe, int harga) async {
    await DatabaseHelper.instance.updateKamar({
      'id_kamar': id,
      'nomor_kamar': nomor,
      'tipe_kamar': tipe,
      'harga_sewa': harga,
    });
    await fetchKamar();
  }

  Future<void> deleteKamar(int id) async {
    await DatabaseHelper.instance.deleteKamar(id);
    await fetchKamar();
  }

  // PENGHUNI METHODS
  Future<void> fetchPenghuni() async {
    _isLoading = true;
    notifyListeners();
    _penghuniList = await DatabaseHelper.instance.readAllPenghuni();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPenghuni(int idKamar, String nama, String wa, String tanggal) async {
    await DatabaseHelper.instance.createPenghuni({
      'id_kamar': idKamar,
      'nama_lengkap': nama,
      'nomor_wa': wa,
      'tanggal_masuk': tanggal,
    });
    await fetchPenghuni();
  }

  Future<void> editPenghuni(int idPenghuni, int idKamar, String nama, String wa, String tanggal) async {
    await DatabaseHelper.instance.updatePenghuni({
      'id_penghuni': idPenghuni,
      'id_kamar': idKamar,
      'nama_lengkap': nama,
      'nomor_wa': wa,
      'tanggal_masuk': tanggal,
    });
    await fetchPenghuni();
  }

  Future<void> deletePenghuni(int id) async {
    await DatabaseHelper.instance.deletePenghuni(id);
    await fetchPenghuni();
  }

  Future<void> resetToFixedRooms() async {
    _isLoading = true;
    notifyListeners();
    await DatabaseHelper.instance.clearAllData();
    await fetchKamar(); // Memicu inisialisasi ulang otomatis
  }
}
