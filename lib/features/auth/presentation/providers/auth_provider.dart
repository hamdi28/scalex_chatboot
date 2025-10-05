import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/auth_service.dart';

// Providers

/// Provides a singleton instance of [AuthService].
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provides a stream of the current Firebase [User] authentication state.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Provides an [AuthController] to manage authentication operations and state.
final authControllerProvider =
StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});

/// Controller for handling authentication logic: sign-up, sign-in, sign-out, and password reset.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  /// Initializes the controller with the given [AuthService].
  AuthController(this._authService) : super(const AsyncValue.data(null));

  /// Signs up a new user with [email] and [password].
  Future<void> signUp(String email, String password) async {
    // Set state to loading while signing up
    state = const AsyncValue.loading();

    // Execute the sign-up safely and update state
    state = await AsyncValue.guard(() async {
      await _authService.signUp(email: email, password: password);
    });
  }

  /// Signs in an existing user with [email] and [password].
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.signIn(email: email, password: password);
    });
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.signOut();
    });
  }

  /// Sends a password reset email to the specified [email].
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.resetPassword(email);
    });
  }
}
