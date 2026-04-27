import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login dengan Email & Password
  Future<Map<String, dynamic>?> login(String email, String password, bool rememberMe) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Ambil role dari Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        String role = 'user';
        bool isApproved = false;
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          role = data['role'] ?? 'user';
          isApproved = data['isApproved'] ?? false;
        }

        // Jika user belum disetujui, jangan biarkan login masuk ke dashboard
        if (role == 'user' && !isApproved) {
          return {'success': false, 'message': 'Akun Anda sedang menunggu konfirmasi Admin.', 'isPending': true};
        }

        // Simpan ke SharedPreferences
        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('role', role);
          await prefs.setString('uid', user.uid);
        }

        return {'success': true, 'role': role};
      }
      return {'success': false, 'message': 'Gagal mendapatkan data user.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Terjadi kesalahan saat login.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Register User Baru
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
    String? name,
    String? wa,
    String? roomNumber,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'role': role,
          'name': name ?? '',
          'wa': wa ?? '',
          'roomNumber': roomNumber ?? '',
          'isApproved': role == 'admin' ? true : false, // Admin otomatis aktif, User butuh konfirmasi
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {'success': true};
      }
      return {'success': false, 'message': 'Gagal mendaftarkan user.'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Terjadi kesalahan.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus sesi
  }

  // Cek Status Login awal (untuk Splash Screen / Main)
  Future<Map<String, dynamic>?> checkLoginStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return {
          'role': data['role'] ?? 'user',
          'isApproved': data['isApproved'] ?? false,
        };
      }
    }
    return null;
  }

  User? get currentUser => _auth.currentUser;

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }
}
