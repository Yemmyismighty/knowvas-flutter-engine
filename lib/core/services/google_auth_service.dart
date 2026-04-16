import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps GoogleSignIn to get an ID token for backend verification.
class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn(
    // iOS client ID — Android uses strings.xml, web client ID is used by the backend
    clientId: '342830036463-luvdm1h73joqrpmvtvfggttfafs0sstc.apps.googleusercontent.com',
    serverClientId: '342830036463-43ln1m5lmhrnh5ghb0p32q2m2usvgjl0.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Triggers the Google sign-in flow and returns the ID token.
  /// Returns null if the user cancels.
  /// Throws a descriptive string on failure so callers can show an error.
  static Future<String?> getIdToken() async {
    // Sign out first to force account picker every time
    await _googleSignIn.signOut();

    final account = await _googleSignIn.signIn();
    if (account == null) {
      debugPrint('🔵 Google Sign-In: user cancelled');
      return null; // user cancelled — not an error
    }

    debugPrint('🔵 Google Sign-In: account selected: ${account.email}');

    final auth = await account.authentication;
    final idToken = auth.idToken;

    debugPrint('🔵 Google Sign-In: idToken=${idToken != null ? "received" : "NULL"}');

    if (idToken == null) {
      throw 'Google did not return an ID token. Check that serverClientId is correct.';
    }

    return idToken;
  }
}
