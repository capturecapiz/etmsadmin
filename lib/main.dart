import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/session.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'config.dart';

void main() {
  runApp(const EtmsAdminApp());
}

class EtmsAdminApp extends StatefulWidget {
  const EtmsAdminApp({super.key});

  @override
  State<EtmsAdminApp> createState() => _EtmsAdminAppState();
}

class _EtmsAdminAppState extends State<EtmsAdminApp> {
  final Session _session = Session();
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _session.restore().whenComplete(() {
      if (mounted) setState(() => _restoring = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Same brand blue the web admin redesign uses.
    const brandBlue = Color(0xFF3B82F6);

    return ChangeNotifierProvider.value(
      value: _session,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: brandBlue,
            primary: brandBlue,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7FB),
          appBarTheme: const AppBarTheme(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        home: _restoring
            ? const _SplashScreen()
            : Consumer<Session>(
                builder: (context, session, _) {
                  return session.isLoggedIn ? const HomeShell() : const LoginScreen();
                },
              ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
