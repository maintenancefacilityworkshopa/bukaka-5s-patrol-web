import 'package:flutter/material.dart';

import '../../activity/presentation/screens/aktivitas_pengguna_screen.dart';
import '../../admin/patrol_schedule/presentation/screens/patrol_schedule_screen.dart';
import '../../admin/user_management/presentation/screens/user_management_screen.dart';
import '../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../patrol/presentation/screens/buat_patrol_screen.dart';
import '../../patrol/presentation/screens/patrol_screen.dart';
import '../../account/screens/account_page.dart';

class MainNavigationWrapper extends StatefulWidget {
  final bool isAdmin;

  const MainNavigationWrapper({super.key, this.isAdmin = false});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardScreen(),
      const PatrolScreen(),
      const AktivitasPenggunaScreen(),
      const AccountPage(),
    ];
  }

  void _onFabPressed() {
    if (widget.isAdmin) {
      // Role Admin: Menampilkan pilihan Kelola Pengguna atau Kelola Schedule
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        elevation: 0,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.only(bottom: 110),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildAdminFabOptions(),
            ),
          );
        },
      );
    } else {
      // Role Non-Admin (User): Langsung ke Form Buat Patrol
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BuatPatrolScreen(),
        ),
      );
    }
  }

  List<Widget> _buildAdminFabOptions() {
    return [
      _buildFloatingOption(
        title: 'KELOLA PENGGUNA',
        icon: Icons.person_add_alt_1_rounded,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserManagementScreen(),
            ),
          );
        },
      ),
      const SizedBox(width: 36),
      _buildFloatingOption(
        title: 'KELOLA SCHEDULE',
        icon: Icons.edit_calendar_rounded,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PatrolScheduleScreen(),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildFloatingOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const primaryBlue = Color(0xFF2563EB);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.8,
            shadows: [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 6,
                color: Colors.black87,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(35),
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryBlue,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const activePillBg = Color(0xFFE0F2FE);
    const inactiveColor = Color(0xFF64748B);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Beranda',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                activeColor: primaryBlue,
                activePillColor: activePillBg,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                index: 1,
                label: 'Patrol',
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment_rounded,
                activeColor: primaryBlue,
                activePillColor: activePillBg,
                inactiveColor: inactiveColor,
              ),
              GestureDetector(
                onTap: _onFabPressed,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066BE), primaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              _buildNavItem(
                index: 2,
                label: 'Activity',
                icon: Icons.show_chart_rounded,
                activeIcon: Icons.show_chart_rounded,
                activeColor: primaryBlue,
                activePillColor: activePillBg,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                index: 3,
                label: 'Akun',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                activeColor: primaryBlue,
                activePillColor: activePillBg,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    IconData? activeIcon,
    required Color activeColor,
    required Color activePillColor,
    required Color inactiveColor,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? activeColor : inactiveColor;
    final currentIcon = isSelected ? (activeIcon ?? icon) : icon;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activePillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              currentIcon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}