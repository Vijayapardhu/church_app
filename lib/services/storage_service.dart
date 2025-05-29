import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String> getAudioUrl(String path) async {
    return await _storage.ref(path).getDownloadURL();
  }

  Future<String> getImageUrl(String path) async {
    return await _storage.ref(path).getDownloadURL();
  }

  Future<String> uploadPrayerImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final fileName = 'prayer_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('prayer_images/$fileName');

    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String?> pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final File imageFile = File(pickedFile.path);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child('profile_images').child(fileName);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error picking/uploading image: $e');
      return null;
    }
  }
} 