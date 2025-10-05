import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service class for handling Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently signed-in user, if any.
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes (sign-in/sign-out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns `true` if a user is currently signed in.
  bool get isLoggedIn => _auth.currentUser != null;

  /// Signs up a new user using [email] and [password].
  /// Throws a user-friendly error message if signup fails.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Signs in an existing user using [email] and [password].
  /// Throws a user-friendly error message if sign-in fails.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Signs out the currently signed-in user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sends a password reset email to the given [email].
  /// Throws a user-friendly error message if the operation fails.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Deletes the currently signed-in user's account.
  /// Throws a user-friendly error message if deletion fails.
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Converts FirebaseAuthException codes to user-friendly error messages.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'error_weak_password'.tr();
      case 'email-already-in-use':
        return 'The email is already in use'.tr();
      case 'invalid-email':
        return 'error_invalid_email'.tr();
      case 'user-not-found':
        return 'No user found with this email'.tr();
      case 'wrong-password':
        return 'Wrong password';
      case 'user-disabled':
        return 'This account has been disabled'.tr();
      case 'too-many-requests':
        return 'Too many requests. Please try again later'.tr();
      case 'operation-not-allowed':
        return 'Operation not allowed'.tr();
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
