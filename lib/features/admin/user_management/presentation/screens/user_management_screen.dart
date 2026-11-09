import 'package:flutter/material.dart';
import '../../data/user_service.dart';
import '../../models/user_model.dart';
import '../widgets/dialogs/add_edit_user_dialog.dart';
import '../widgets/user_filter_bar.dart';
import '../widgets/user_list_mobile.dart';
import '../widgets/user_table_view.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  String _searchQuery = '';
  String _selectedRole = 'Semua Role';

  void _openAddEditDialog([UserModel? user]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditUserDialog(
        user: user,
        userService: _userService,
      ),
    );
  }

  Future<void> _handleDeleteUser(String userId) async {
    try {
      await _userService.deleteUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna berhasil dihapus'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus pengguna: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // AppBar Dihapus agar tampilan lebih rapi & menyesuaikan gesture back device
      appBar: null,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 4,
        onPressed: () => _openAddEditDialog(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: _userService.getUsersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Terjadi kesalahan: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              );
            }

            final allUsers = snapshot.data ?? [];

            // Kalkulasi Statistik Role
            int countStaffAhli = allUsers.where((u) => u.role == AppRole.STAFF_AHLI).length;
            int countIntern = allUsers.where((u) => u.role == AppRole.STAFF_INTERNSHIP).length;
            int countPicArea = allUsers.where((u) => u.role == AppRole.PIC_AREA).length;
            int countTotal = allUsers.length;

            // Filter data berdasarkan query pencarian dan dropdown role
            final filteredUsers = allUsers.where((user) {
              final matchesSearch = user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (user.nik ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

              bool matchesRole = true;
              if (_selectedRole != 'Semua Role') {
                matchesRole = user.displayRole.toLowerCase() == _selectedRole.toLowerCase();
              }

              return matchesSearch && matchesRole;
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth > 768;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Banner Info Kelola Pengguna (Dibuat Responsif agar Tidak Overflow)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.group_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Kelola Pengguna',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Atur data pengguna sistem 5S',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF64748B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$countTotal',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.group, size: 12, color: Color(0xFF2563EB)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter Search & Dropdown Role
                      UserFilterBar(
                        searchQuery: _searchQuery,
                        selectedRole: _selectedRole,
                        onSearchChanged: (val) => setState(() => _searchQuery = val),
                        onRoleChanged: (val) => setState(() => _selectedRole = val),
                      ),
                      const SizedBox(height: 16),

                      // Kartu Kategori Ringkasan Role
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRoleSummaryCard(
                              title: 'Staff Ahli',
                              count: countStaffAhli,
                              icon: Icons.person_rounded,
                              color: const Color(0xFF2563EB),
                              isSelected: _selectedRole == 'Staff Ahli',
                              onTap: () => setState(() {
                                _selectedRole = _selectedRole == 'Staff Ahli' ? 'Semua Role' : 'Staff Ahli';
                              }),
                            ),
                            const SizedBox(width: 10),
                            _buildRoleSummaryCard(
                              title: 'Staff Internship',
                              count: countIntern,
                              icon: Icons.person_outline_rounded,
                              color: const Color(0xFF10B981),
                              isSelected: _selectedRole == 'Staff Internship',
                              onTap: () => setState(() {
                                _selectedRole = _selectedRole == 'Staff Internship' ? 'Semua Role' : 'Staff Internship';
                              }),
                            ),
                            const SizedBox(width: 10),
                            _buildRoleSummaryCard(
                              title: 'PIC Area',
                              count: countPicArea,
                              icon: Icons.verified_user_rounded,
                              color: const Color(0xFF8B5CF6),
                              isSelected: _selectedRole == 'PIC Area',
                              onTap: () => setState(() {
                                _selectedRole = _selectedRole == 'PIC Area' ? 'Semua Role' : 'PIC Area';
                              }),
                            ),
                            const SizedBox(width: 10),
                            _buildRoleSummaryCard(
                              title: 'Total',
                              count: countTotal,
                              icon: Icons.groups_rounded,
                              color: const Color(0xFF64748B),
                              isSelected: _selectedRole == 'Semua Role',
                              onTap: () => setState(() => _selectedRole = 'Semua Role'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sub-Header List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.group_outlined, size: 18, color: Color(0xFF2563EB)),
                              SizedBox(width: 6),
                              Text(
                                'Daftar Pengguna',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${filteredUsers.length} Pengguna',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tampilan Pengguna (Desktop / Mobile Card)
                      isDesktop
                          ? UserTableView(
                              users: filteredUsers,
                              onEdit: _openAddEditDialog,
                              onDelete: _handleDeleteUser,
                            )
                          : UserListMobile(
                              users: filteredUsers,
                              onEdit: _openAddEditDialog,
                              onDelete: _handleDeleteUser,
                            ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 135,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}