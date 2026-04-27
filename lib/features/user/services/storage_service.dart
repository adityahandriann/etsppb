import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fungsi untuk upload file ke Firebase Storage
  Future<String?> uploadImage(File imageFile, String folderName) async {
    try {
      String fileName = basename(imageFile.path);
      String destination = '$folderName/$fileName';

      // Buat referensi storage
      Reference ref = _storage.ref().child(destination);
      
      // Upload file
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Ambil URL download setelah berhasil
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error upload storage: $e");
      return null;
    }
  }
}
