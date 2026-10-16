import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/shared/presentation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fhgcihxfnohefyciczox.supabase.co',
    publishableKey: 'sb_publishable_9Pn8q9bCrUGzy2xZcFqnpg_ltwBL4GS',
  );

  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bukaka 5S Patrol',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
      ),
      // 1. Jadikan SplashScreen sebagai halaman pertama yang dibuka
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/splash': (context) => const SplashScreen(),
        '/main': (context) => const AuthGate(), // Diarahkan ke AuthGate setelah SplashScreen
      },
    );
  }
}

/// Kelas untuk mengecek Role/Profil pengguna yang SUDAH LOGIN
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  /// Mengambil data profil user berdasarkan UID dari Supabase
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, role')
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    // Jika karena suatu alasan session bernilai null saat masuk ke sini, balikkan ke Login
    if (session == null) {
      return const LoginScreen();
    }

    // Ambil profil berdasarkan UID pengguna yang aktif
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserProfile(session.user.id),
      builder: (context, profileSnapshot) {
        // Indikator loading saat mengambil data profil dari Supabase
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00569E)),
              ),
            ),
          );
        }

        // Jika profil tidak ditemukan, arahkan kembali ke LoginScreen
        if (!profileSnapshot.hasData || profileSnapshot.data == null) {
          return const LoginScreen();
        }

        final userProfile = profileSnapshot.data!;
        final role = (userProfile['role'] ?? '').toString().toLowerCase();
        final isAdmin = role == 'admin' || role == 'administrator';

        // Tampilkan Halaman Utama sesuai status Admin / User
        return MainNavigationWrapper(isAdmin: isAdmin);
      },
    );
  }
}