import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/presentation/main_navigation.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _puzzleController;
  late AnimationController _continuousRotationController;

  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _scaleAnimations;

  final List<String> _puzzleAssets = [
    'assets/images/puzzle_sustain.png',
    'assets/images/puzzle_sort.png',
    'assets/images/puzzle_set_in_order.png',
    'assets/images/puzzle_shine.png',
    'assets/images/puzzle_standardize.png',
  ];

  @override
  void initState() {
    super.initState();

    // 1. Controller Animasi Pemunculan Puzzle (3.5 Detik agar lebih pas)
    _puzzleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // 2. Controller Rotasi Menerus Roda (12 Detik Per Putaran agar sangat halus & tenang)
    _continuousRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(); // Looping tanpa henti secara linear

    // Interval Animasi Pemunculan Puzzle yang Lebih Mulus
    _fadeAnimations = List.generate(5, (index) {
      double start = index * 0.15;
      double end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _puzzleController,
          curve: Interval(start, end, curve: Curves.easeInOutCubic),
        ),
      );
    });

    _scaleAnimations = List.generate(5, (index) {
      double start = index * 0.15;
      double end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
          parent: _puzzleController,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        ),
      );
    });

    _runSplashSequence();
  }

  Future<void> _runSplashSequence() async {
    // SIKLUS 1
    await _puzzleController.forward();

    // JEDA HILANG SMOOTH (300 ms)
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      await _puzzleController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }

    // SIKLUS 2
    await _puzzleController.forward();

    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    final session = Supabase.instance.client.auth.currentSession;

    bool isAdmin = false;
    if (session != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .maybeSingle();

        if (profile != null && profile['role'] != null) {
          final roleStr = profile['role'].toString().toUpperCase();
          isAdmin = (roleStr == 'ADMIN');
        }
      } catch (_) {}
    }

    if (mounted) {
      if (session != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainNavigationWrapper(isAdmin: isAdmin),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var curve = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              );
              return FadeTransition(
                opacity: curve,
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _puzzleController.dispose();
    _continuousRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Roda puzzle diset lebih kecil (38% dari lebar layar, min: 150, max: 200)
    final double puzzleSize = (screenSize.width * 0.38).clamp(150.0, 200.0);

    // Ukuran logo / teks 5S di tengah
    final double centerContentSize = puzzleSize * 0.42;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_bukaka.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFD0DCE5),
              ),
            ),
          ),

          // 2. Overlay Transparan Light
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),

          // 3. Konten Utama Roda 5S
          SafeArea(
            child: Center(
              child: SizedBox(
                width: puzzleSize,
                height: puzzleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // RODA PUZZLE BERPUTAR (Linear smooth rotation)
                    RotationTransition(
                      turns: _continuousRotationController,
                      child: SizedBox(
                        width: puzzleSize,
                        height: puzzleSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (int i = 0; i < 5; i++)
                              AnimatedBuilder(
                                animation: _puzzleController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _fadeAnimations[i].value,
                                    child: Transform.scale(
                                      scale: _scaleAnimations[i].value,
                                      child: Image.asset(
                                        _puzzleAssets[i],
                                        width: puzzleSize,
                                        height: puzzleSize,
                                        fit: BoxFit.contain,
                                        errorBuilder: (ctx, err, stack) =>
                                            const SizedBox(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    // TEKS / LOGO "5S" TENGAH
                    SizedBox(
                      width: centerContentSize,
                      height: centerContentSize,
                      child: Center(
                        child: Image.asset(
                          'assets/images/center_5s.png',
                          width: centerContentSize,
                          height: centerContentSize,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => Text(
                            '5S',
                            style: TextStyle(
                              fontSize: centerContentSize * 0.48,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF00569E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Versi Aplikasi di Bagian Bawah
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'VERSION 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color.fromARGB(255, 212, 207, 207),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}