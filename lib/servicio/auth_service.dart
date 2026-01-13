import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:cancionero/servicio/firestore_service.dart';
import 'package:cancionero/secrets.dart' as secrets;
import 'package:cancionero/servicio/google_desktop_auth.dart';

class AuthService {
  // Use a getter so FirebaseAuth.instance is only accessed when needed (avoids errors in widget tests)
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Inicia sesión con Google (API 7.x): singleton, initialize y authenticate.
  Future<User?> signInWithGoogle() async {
    try {
      final signIn = GoogleSignIn.instance;

      // Inicializar (safe to call multiple times)
      try {
        await signIn.initialize();
      } catch (_) {}

      // Si estamos en Windows, usar el flujo de OAuth de escritorio (PKCE)
      if (Platform.isWindows) {
        if (secrets.googleDesktopClientId.contains('TU_CLIENT_ID')) {
          throw Exception(
            'Debes configurar `lib/secrets.dart` con el Client ID de tipo Desktop de Google.',
          );
        }

        final u = await GoogleDesktopAuth.signInAndSignInFirebase(
          clientId: secrets.googleDesktopClientId,
        );
        if (u != null) await FirestoreService().crearUsuarioSiNoExiste(u);
        return u;
      }

      // Verificar si la plataforma soporta el método interactivo `authenticate`
      if (!signIn.supportsAuthenticate()) {
        // Lanzamos una excepción que la UI ya maneja para mostrar fallback
        throw MissingPluginException(
          'Google Sign-In no implementado en esta plataforma',
        );
      }

      // Ejecutar el flujo interactivo
      final account = await signIn.authenticate();
      if (account == null) return null; // usuario canceló

      // Obtener tokens de autenticación
      final auth = account.authentication;
      // En la API 7.x actualmente `GoogleSignInAuthentication` expone `idToken`.
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        // Crear el documento del usuario en Firestore si no existe
        await FirestoreService().crearUsuarioSiNoExiste(user);
      }

      return user;
    } catch (e) {
      // Re-lanzar para que la UI pueda mostrar el mensaje apropiado
      throw e;
    }
  }

  /// Registra un usuario con correo y contraseña.
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? nombre,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCred.user;

    if (user != null) {
      // Crear documento en Firestore con método de autenticación por correo.
      await FirestoreService().crearUsuarioConCorreo(
        uid: user.uid,
        email: email,
        nombre: nombre ?? '',
      );
    }

    return user;
  }

  /// Inicia sesión con correo y contraseña.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
