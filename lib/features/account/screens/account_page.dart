import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/about_app.dart';
import 'widgets/change_password.dart';
import 'widgets/edit_profiles.dart';
import 'widgets/help_app.dart';
import '../../notification/presentation/screens/notification_screen.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  String _fullName = '';
  String _role = '';
  String _nik = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await _supabase
          .from('profiles')
          .select('full_name, role, nik, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _fullName = res['full_name'] ?? 'Pengguna';
          _role = (res['role'] ?? 'STAFF_AHLI').toString().replaceAll('_', ' ');
          _nik = res['nik'] ?? '-';
          _avatarUrl = res['avatar_url'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    try {
      setState(() => _isLoading = true);
      final fileExt = pickedFile.path.split('.').last;
      final filePath = '${user.id}/avatar.$fileExt';

      final imageBytes = await pickedFile.readAsBytes();

      await _supabase.storage.from('avatars').uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$fileExt',
            ),
          );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      await _supabase.from('profiles').update({
        'avatar_url': imageUrl,
      }).eq('id', user.id);

      await _fetchUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah foto: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                  title: const Text('Ambil Foto Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// PERBAIKAN LOGOUT: Menambahkan async handler, loading indicator & pushNamedAndRemoveUntil ke /login
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog

              if (!mounted) return;
              setState(() => _isLoading = true);

              try {
                await _supabase.auth.signOut();
                if (!mounted) return;

                // Navigasi hapus seluruh stack & arahkan ke halaman Login
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal logout: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003B6D),
      body: Stack(
        children: [
          // Background Header dengan Dark Overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_account.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 110,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Foto Profil
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: CircleAvatar(
                                          radius: 46,
                                          backgroundColor: Colors.white,
                                          backgroundImage: _avatarUrl != null
                                              ? NetworkImage(_avatarUrl!)
                                              : null,
                                          child: _avatarUrl == null
                                              ? const Icon(
                                                  Icons.person_rounded,
                                                  size: 50,
                                                  color: Color(0xFF2563EB),
                                                )
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: _showAvatarOptions,
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                )
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.edit_rounded,
                                              size: 15,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Nama & Info User
                                  Text(
                                    _fullName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_role   |   $_nik',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Container Card Menu Utama
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(22),
                                      child: Column(
                                        children: [
                                          _buildMenuItem(
                                            icon: Icons.person_outline_rounded,
                                            title: 'Your Profiles',
                                            subtitle: 'Lihat dan kelola profil Anda',
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const EditProfilesScreen(),
                                                ),
                                              );
                                              _fetchUserData();
                                            },
                                          ),
                                          const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
                                          _buildMenuItem(
                                            icon: Icons.lock_outline_rounded,
                                            title: 'Change Password',
                                            subtitle: 'Ubah password akun Anda',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const ChangePasswordScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
                                          _buildMenuItem(
                                            icon: Icons.notifications_none_rounded,
                                            title: 'Notification',
                                            subtitle: 'Atur preferensi notifikasi',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const NotificationScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
                                          _buildMenuItem(
                                            icon: Icons.info_outline_rounded,
                                            title: 'About',
                                            subtitle: 'Informasi tentang aplikasi',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const AboutAppScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
                                          _buildMenuItem(
                                            icon: Icons.help_outline_rounded,
                                            title: 'Help',
                                            subtitle: 'Pusat bantuan dan dukungan',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const HelpAppScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
                                          _buildMenuItem(
                                            icon: Icons.logout_rounded,
                                            title: 'Logout',
                                            subtitle: 'Keluar dari akun Anda',
                                            isLogout: true,
                                            onTap: _confirmLogout,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLogout ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isLogout ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isLogout ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isLogout ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
      ),
    );
  }
}