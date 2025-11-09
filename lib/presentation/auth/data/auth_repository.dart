import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 1. Import Google Sign-In
import 'package:is_application/core/models/user_model.dart';
import 'package:is_application/core/providers/firebase_providers.dart';
import 'package:is_application/core/repositories/firestore_repository.dart';

/// The "contract" for our auth repository.
abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<void> signInWithEmailPassword(String email, String password);
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required Ref ref,
  });
  Future<void> signInWithGoogle(Ref ref);
  Future<void> signOut();
}

// --- The Implementation ---

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  // 2. Add an instance of GoogleSignIn
  final GoogleSignIn _googleSignIn;

  // 3. Initialize it in the constructor
  AuthRepositoryImpl(this._firebaseAuth) : _googleSignIn = GoogleSignIn();

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required Ref ref,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
        );
        await ref
            .read(firestoreRepositoryProvider)
            .createUserDocument(newUser);
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle(Ref ref) async {
    try {
      // 4. FIX: Use the class instance '_googleSignIn'
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // User canceled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 5. This 'credential' call will now work because your
      // 'firebase_auth' package is up to date.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // 6. Check if new user and create doc
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final user = userCredential.user;
        if (user != null) {
          final newUser = UserModel(
            uid: user.uid,
            firstName: user.displayName?.split(' ').first ?? 'User',
            lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
            email: user.email ?? '',
          );
          await ref
              .read(firestoreRepositoryProvider)
              .createUserDocument(newUser);
        }
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    // 6. FIX: Also sign out from Google
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}

// --- The Provider for the Repository ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRepositoryImpl(firebaseAuth);
});