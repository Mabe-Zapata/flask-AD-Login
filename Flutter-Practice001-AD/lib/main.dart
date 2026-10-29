import 'package:app001/pages/login_page.dart';
import 'package:app001/services/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void _onSessionExpired() {
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false,
  );
  showDialog<void>(
    context: navigator.overlay!.context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Sesión cerrada'),
      content: const Text(
        'Ha pasado el tiempo de transacción del sistema. Vuelva a acceder para continuar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

void main() {
  Session.onExpired = _onSessionExpired;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Gestor de productos',
      theme: ThemeData(
          colorScheme: .fromSeed(seedColor: const Color(0xFF00A8C6)),
      ),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const LoginPage(),
    );
  }
}
