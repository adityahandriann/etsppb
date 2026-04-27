import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  final TicketService _ticketService = TicketService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  // Pilih Foto dari Kamera
  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 25, // Kompres lebih kecil karena Firestore punya limit 1MB per dokumen
    );

    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // Fungsi helper konversi ke Base64
  Future<String> _fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  // Kirim Laporan Kerusakan
  Future<bool> sendDamageReport(String uid, String nomorKamar, String deskripsi) async {
    if (_selectedImage == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Konversi ke Base64
      String base64Image = await _fileToBase64(_selectedImage!);
      
      // 2. Simpan ke Firestore
      bool success = await _ticketService.createDamageReport(
        uid: uid,
        nomorKamar: nomorKamar,
        deskripsi: deskripsi,
        imageUrl: base64Image, // Kita kirim string Base64 ke field imageUrl
      );
      
      if (success) {
        _selectedImage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Error in Provider: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Kirim Laporan Pembayaran
  Future<bool> sendPaymentReport(String uid, String nomorKamar) async {
    if (_selectedImage == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Konversi ke Base64
      String base64Image = await _fileToBase64(_selectedImage!);
      
      bool success = await _ticketService.createPaymentReport(
        uid: uid,
        nomorKamar: nomorKamar,
        imageUrl: base64Image,
      );
      
      if (success) {
        _selectedImage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Error in Provider: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
