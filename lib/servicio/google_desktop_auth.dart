import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class GoogleDesktopAuth {
  /// Genera un code verifier aleatorio
  static String _generateCodeVerifier([int length = 64]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Calcula el code_challenge = BASE64URL(SHA256(verifier))
  static String _codeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Realiza flujo PKCE en escritorio, devuelve map con idToken y accessToken
  static Future<Map<String, String>> signInWithPKCE({
    required String clientId,
    List<String> scopes = const ['openid', 'email', 'profile'],
  }) async {
    final verifier = _generateCodeVerifier();
    final challenge = _codeChallenge(verifier);

    // Levantamos un servidor local para recibir el callback
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}/callback';

    // Construir URL de autorización
    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scopes.join(' '),
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'access_type': 'offline',
      'prompt': 'select_account',
    });

    // Abrir navegador
    if (!await _openUrl(authUrl.toString())) {
      await server.close(force: true);
      throw Exception('No se pudo abrir el navegador para autenticación.');
    }

    // Esperar callback con el código
    final Completer<String> codeCompleter = Completer();

    server.listen((HttpRequest request) async {
      try {
        if (request.uri.path == '/callback') {
          final code = request.uri.queryParameters['code'];
          final error = request.uri.queryParameters['error'];

          // Send a simple response to close the browser tab
          request.response.statusCode = 200;
          request.response.headers.set(
            'Content-Type',
            'text/html; charset=utf-8',
          );
          request.response.write(
            '<html><body><h3>Puedes cerrar esta ventana y volver a la app.</h3></body></html>',
          );
          await request.response.close();

          if (error != null) {
            codeCompleter.completeError(
              Exception('Error en autorización: $error'),
            );
          } else if (code != null) {
            codeCompleter.complete(code);
          } else {
            codeCompleter.completeError(
              Exception('No se recibió el código de autorización.'),
            );
          }
        } else {
          request.response.statusCode = 404;
          await request.response.close();
        }
      } catch (e) {
        if (!codeCompleter.isCompleted) codeCompleter.completeError(e);
      }
    });

    final code = await codeCompleter.future;
    await server.close(force: true);

    // Intercambiar código por tokens
    final tokenRes = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': verifier,
      },
    );

    if (tokenRes.statusCode != 200) {
      throw Exception('Falló intercambio de tokens: ${tokenRes.body}');
    }

    final Map<String, dynamic> tokenJson = json.decode(tokenRes.body);

    final idToken = tokenJson['id_token'] as String?;
    final accessToken = tokenJson['access_token'] as String?;

    if (idToken == null) throw Exception('id_token no recibido');

    return {
      'idToken': idToken,
      if (accessToken != null) 'accessToken': accessToken,
    };
  }

  // Helper para abrir URL en el sistema (usa url_launcher impl internamente si fuera necesario)
  static Future<bool> _openUrl(String url) async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Intentar con 'start' / 'xdg-open' / 'open'
        if (Platform.isWindows) {
          await Process.run('rundll32', ['url.dll,FileProtocolHandler', url]);
          return true;
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [url]);
          return true;
        } else if (Platform.isMacOS) {
          await Process.run('open', [url]);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Flujo completo: obtiene tokens y hace sign-in en Firebase
  static Future<User?> signInAndSignInFirebase({
    required String clientId,
  }) async {
    final tokens = await signInWithPKCE(clientId: clientId);
    final idToken = tokens['idToken']!;
    final accessToken = tokens['accessToken'];

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    final userCred = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    return userCred.user;
  }
}
