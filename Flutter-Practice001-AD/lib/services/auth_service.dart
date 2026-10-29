import 'dart:convert';
import 'dart:io';

import 'package:app001/services/session.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final String url = "http://localhost:5000/api/auth/login";

  /// Devuelve el nombre del rol del usuario (por ejemplo "Admin" o "User").
  Future<String> login(String usuario, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'usuario': usuario, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        Session.start(
          body['token'] as String,
          DateTime.parse(body['expiracion'] as String),
        );
        return body['usuario']['rol'] as String;
      }
      if (response.statusCode == 401) {
        throw AuthException('Usuario o contraseña incorrectos');
      }
      throw AuthException('No se pudo iniciar sesión. Inténtelo de nuevo.');
    } on AuthException {
      rethrow;
    } on SocketException {
      throw AuthException('No se pudo conectar con el servidor.');
    } catch (_) {
      throw AuthException('No se pudo conectar con el servidor.');
    }
  }
}
