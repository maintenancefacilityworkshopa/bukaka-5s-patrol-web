import 'package:flutter/material.dart';
import '../../../data/user_service.dart';
import '../../../models/user_model.dart';

class AddEditUserDialog extends StatefulWidget {
  final UserModel? user;
  final UserService userService;

  const AddEditUserDialog({
    super.key,
    this.user,
    required this.userService,
  });

  @override
  State<AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _nikController;
  late TextEditingController _hpController;
  late TextEditingController _passwordController;

  String _selectedRoleDisplay = 'Staff Ahli';
  String? _selectedDepartmentId;
  List<Map<String, dynamic>> _departments = [];
  bool _isActive = true;
  bool _isLoading = false;

  static const primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _namaController = TextEditingController(text: widget.user?.fullName ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _nikController = TextEditingController(text: widget.user?.nik ?? '');
    _hpController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _passwordController = TextEditingController();

    if (widget.user != null) {
      _selectedRoleDisplay = widget.user!.displayRole;
      _selectedDepartmentId = widget.user!.departmentId;
      _isActive = widget.user!.isActive;
    }

    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final data = await widget.userService.fetchDepartments();
      if (mounted) setState(() => _departments = data);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _nikController.dispose();
    _hpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_namaController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Email wajib diisi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final userPayload = UserModel(
        id: widget.user?.id ?? '',
        fullName: _namaController.text.trim(),
        email: _emailController.text.trim(),
        nik: _nikController.text.trim(),
        role: UserModel.roleToEnum(_selectedRoleDisplay),
        departmentId: _selectedDepartmentId,
        phoneNumber: _hpController.text.trim(),
        isActive: _isActive,
      );

      await widget.userService.saveUser(user: userPayload, userId: widget.user?.id);
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user == null ? 'Tambah Pengguna' : 'Edit Pengguna',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          TabBar(
            controller: _tabController,
            labelColor: primaryBlue,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: primaryBlue,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Profil'),
              Tab(text: 'Ganti Password'),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 310,
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Nama Lengkap', _namaController)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('Email', _emailController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('NIK', _nikController)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Role', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedRoleDisplay,
                                      isExpanded: true,
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      items: ['Admin', 'PIC Area', 'Staff Ahli', 'Staff Internship'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => _selectedRoleDisplay = v);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Departemen / Jabatan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDepartmentId,
                                      hint: const Text('Pilih Departemen', style: TextStyle(fontSize: 11)),
                                      isExpanded: true,
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      items: _departments.map((dept) {
                                        return DropdownMenuItem<String>(
                                          value: dept['id'].toString(),
                                          child: Text(dept['name'] ?? '', overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                      onChanged: (v) => setState(() => _selectedDepartmentId = v),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('No. HP', _hpController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Status Akun:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          const SizedBox(width: 8),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: _isActive,
                              activeThumbColor: primaryBlue,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                          ),
                          Text(_isActive ? 'Aktif' : 'Non-Aktif', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Password Baru', _passwordController, isPassword: true),
                    const SizedBox(height: 12),
                    const Text(
                      'Pastikan password terdiri dari minimal 8 karakter gabungan huruf dan angka.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            ),
          ),
        ),
      ],
    );
  }
}