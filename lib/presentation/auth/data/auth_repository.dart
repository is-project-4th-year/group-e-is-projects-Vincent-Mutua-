import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl(this._firebaseAuth) : _googleSignIn = GoogleSignIn();

  // ... (all other methods like signIn, signUp, etc. are correct) ...
  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
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
        await userCredential.user!.sendEmailVerification();
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
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle(Ref ref) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // User canceled
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
      }
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
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
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}

// --- The Provider for the Repository ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRepositoryImpl(firebaseAuth);
});