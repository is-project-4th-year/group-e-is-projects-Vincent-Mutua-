import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:is_application/core/providers/firebase_providers.dart';
import 'package:is_application/presentation/auth/data/auth_repository.dart';

// --- 1. AUTH STATE PROVIDER ---
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// --- 2. AUTH CONTROLLER ---
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthController({
    required AuthRepository authRepository,
    required Ref ref,
  })  : _authRepository = authRepository,
        _ref = ref,
        super(const AsyncValue.data(null));

  /// Signs in a user with email and password.
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithEmailPassword(email, password);
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Signs up a new user.
  Future<void> signUp(
      String email, String password, String firstName, String lastName) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUpWithEmailPassword(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        ref: _ref,
      );

      // --- FIX: REMOVED REDUNDANT EMAIL VERIFICATION LOGIC ---
      // The call is now handled reliably inside auth_repository.dart

      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Signs in or signs up a user with their Google account.
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signInWithGoogle(_ref);
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, stack) {
      // Handle user cancellation gracefully
      if (e.code == 'sign_in_canceled' || e.code == 'network_request_failed') {
        state = const AsyncValue.data(null); // Not a fatal error
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// --- 3. AUTH CONTROLLER PROVIDER ---
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    authRepository: ref.watch(authRepositoryProvider),
    ref: ref,
  );
});