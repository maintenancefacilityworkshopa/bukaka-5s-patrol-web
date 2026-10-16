import 'package:flutter/material.dart';
import '../../../shared/presentation/main_navigation.dart';
import '../../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan Password wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepo.login(email: email, password: password);
      final profile = await _authRepo.getUserProfile();
      
      final bool isAdmin = profile?['role'] == 'ADMIN';
      final String fullName = profile?['full_name'] ?? 'User Patrol';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat Datang, $fullName!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationWrapper(isAdmin: isAdmin),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Gagal: ${e.toString().replaceAll('Exception:', '').replaceAll('AuthException:', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Pabrik
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_bukaka.png',
              fit: BoxFit.cover,
            ),
          ),

          // Overlay Biru Elegan
          Positioned.fill(
            child: Container(
              color: const Color(0xFF003B6D).withValues(alpha: 0.55),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(opacity: _fadeAnimation.value, child: child),
                  );
                },
                
                // CONSTRAINEDBOX MEMBUAT CARD PROPOSIONAL DI WEB, ANDROID, DAN IOS
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420, // Maksimal lebar card di Web / Tablet
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/bukaka_logo.png',
                          height: 85,
                          errorBuilder: (ctx, err, stack) => const Column(
                            children: [
                              Text('BUKAKA', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF00569E))),
                              Text('— 5S PATROL SISTEM —', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00569E))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Username / Email Field
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Username / Email',
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          isObscure: _isObscure,
                          onTogglePassword: () => setState(() => _isObscure = !_isObscure),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _isLoading ? null : _handleLogin(),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Silakan hubungi Administrator Maintenance and Facility untuk reset password.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            child: const Text(
                              'Forget password ?',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E5BB0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onTogglePassword,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? isObscure : false,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF00569E)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey),
                onPressed: onTogglePassword,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00569E), width: 1.5),
        ),
      ),
    );
  }
}