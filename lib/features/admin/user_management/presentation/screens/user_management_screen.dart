import 'package:flutter/material.dart';
import '../../data/user_service.dart';
import '../../models/user_model.dart';
import '../widgets/user_filter_bar.dart';
import '../widgets/user_table_view.dart';
import '../widgets/dialogs/add_edit_user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();

  String _searchQuery = '';
  String _selectedRoleFilter = 'Semua Role';

  static const primaryBlue = Color(0xFF2563EB);

  void _showUserModal({UserModel? user}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'KELOLA PENGGUNA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 24),
            tooltip: 'Tambah Pengguna',
            onPressed: () => _showUserModal(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kelola akun pengguna sistem 5S Patrol',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),

              UserFilterBar(
                searchQuery: _searchQuery,
                selectedRole: _selectedRoleFilter,
                onSearchChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                onRoleChanged: (val) => setState(() => _selectedRoleFilter = val),
              ),
              const SizedBox(height: 16),

              StreamBuilder<List<UserModel>>(
                stream: _userService.getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Terjadi Kesalahan: ${snapshot.error}'));
                  }

                  final allUsers = snapshot.data ?? [];

                  final filteredUsers = allUsers.where((user) {
                    final name = user.fullName.toLowerCase();
                    final email = user.email.toLowerCase();
                    final nik = (user.nik ?? '').toLowerCase();
                    final displayRole = user.displayRole;

                    final matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery) || nik.contains(_searchQuery);
                    final matchesRole = _selectedRoleFilter == 'Semua Role' || displayRole == _selectedRoleFilter;

                    return matchesSearch && matchesRole;
                  }).toList();

                  return UserTableView(
                    users: filteredUsers,
                    onEdit: (user) => _showUserModal(user: user),
                    onDelete: (id) async => await _userService.deleteUser(id),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}