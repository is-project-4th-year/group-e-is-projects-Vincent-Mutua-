import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:is_application/core/providers/firebase_providers.dart';

// --- NOTIFICATION SETTINGS PROVIDER ---
// Simple boolean toggle for now. In a real app, sync this with Firestore or SharedPreferences.
final notificationEnabledProvider = StateProvider<bool>((ref) => true);

// --- PROFILE CONTROLLER ---
final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController(ref);
});

class ProfileController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  ProfileController(this._ref) : super(const AsyncValue.data(null));

  /// Picks an image from the gallery, uploads it to Firebase Storage,
  /// and updates the user's photoURL.
  Future<void> updateProfileImage() async {
    try {
      // 1. Pick Image
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return; // User cancelled

      state = const AsyncValue.loading();

      final File file = File(image.path);
      final user = _ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('No user signed in');

      // 2. Upload to Firebase Storage
      // Path: users/{uid}/profile_image.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile_image.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // 4. Update FirebaseAuth Profile
      await user.updatePhotoURL(downloadUrl);
      
      // Force a reload to ensure UI updates (sometimes needed)
      await user.reload();
      
      // 5. (Optional) Update Firestore User Document if you store photoUrl there too
      // await _ref.read(firestoreRepositoryProvider).updateUserPhoto(user.uid, downloadUrl);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
