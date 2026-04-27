import 'package:cloud_firestore/cloud_firestore.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Simpan Laporan Kerusakan
  Future<bool> createDamageReport({
    required String uid,
    required String nomorKamar,
    required String deskripsi,
    required String imageUrl,
  }) async {
    try {
      await _firestore.collection('tickets').add({
        'uid': uid,
        'nomorKamar': nomorKamar,
        'deskripsi': deskripsi,
        'imageUrl': imageUrl,
        'status': 'Pending', // Default status
        'type': 'damage',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print("Error save ticket: $e");
      return false;
    }
  }

  // 2. Simpan Laporan Pembayaran
  Future<bool> createPaymentReport({
    required String uid,
    required String nomorKamar,
    required String imageUrl,
  }) async {
    try {
      await _firestore.collection('payments').add({
        'uid': uid,
        'nomorKamar': nomorKamar,
        'imageUrl': imageUrl,
        'status': 'Unverified', // Default status
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print("Error save payment: $e");
      return false;
    }
  }

  // 3. Ambil List Tiket User (Untuk User)
  Stream<QuerySnapshot> getUserTickets(String uid) {
    return _firestore
        .collection('tickets')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 3b. Ambil List Pembayaran User (Untuk User)
  Stream<QuerySnapshot> getUserPayments(String uid) {
    return _firestore
        .collection('payments')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 4. Ambil Semua Tiket (Untuk Admin)
  Stream<QuerySnapshot> getAllTickets() {
    return _firestore.collection('tickets').orderBy('createdAt', descending: true).snapshots();
  }

  // 5. Ambil Semua Pembayaran (Untuk Admin)
  Stream<QuerySnapshot> getAllPayments() {
    return _firestore.collection('payments').orderBy('createdAt', descending: true).snapshots();
  }

  // 6. Update Status (Untuk Admin)
  Future<void> updateStatus(String collection, String docId, String newStatus) async {
    await _firestore.collection(collection).doc(docId).update({'status': newStatus});
  }
}
