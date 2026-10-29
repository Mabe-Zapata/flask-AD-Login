import 'dart:async';

import 'package:flutter/foundation.dart';

/// Sesión en memoria: se pierde al cerrar la app.
class Session {
  static String? token;
  static Timer? _timer;

  /// Se invoca cuando el token caduca (lo asigna main.dart).
  static VoidCallback? onExpired;

  static void start(String newToken, DateTime expiration) {
    _timer?.cancel();
    token = newToken;
    // shortcut: usa el reloj del dispositivo, si está desfasado del servidor la caducidad será imprecisa.
    _timer = Timer(expiration.difference(DateTime.now()), () {
      clear();
      onExpired?.call();
    });
  }

  static void clear() {
    _timer?.cancel();
    _timer = null;
    token = null;
  }

  static Map<String, String> headers({bool json = false}) => {
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
}
