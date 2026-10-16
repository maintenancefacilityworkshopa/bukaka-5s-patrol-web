import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilesScreen extends StatefulWidget {
  const EditProfilesScreen({super.key});

  @override
  State<EditProfilesScreen> createState() => _EditProfilesScreenState();
}

class _EditProfilesScreenState extends State<EditProfilesScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _nikController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedDepartmentId;
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nikController = TextEditingController();
    _loadProfileAndDepartments();
  }

  Future<void> _loadProfileAndDepartments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final deptRes = await _supabase.from('departments').select('id, name');
      final profileRes = await _supabase
          .from('profiles')
          .select('full_name, nik, department_id')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(deptRes);
          if (profileRes != null) {
            _nameController.text = profileRes['full_name'] ?? '';
            _nikController.text = profileRes['nik'] ?? '';
            _selectedDepartmentId = profileRes['department_id']?.toString();
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'nik': _nikController.text.trim(),
        'department_id': _selectedDepartmentId,
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Profiles',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nama Lengkap'),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: _inputDecoration('Masukkan Nama Lengkap'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('NIK / Kode Pegawai'),
                    TextFormField(
                      controller: _nikController,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: _inputDecoration('Contoh: ADM-0001'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'NIK tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Departemen'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _departments.any(
                              (d) => d['id'].toString() == _selectedDepartmentId)
                          ? _selectedDepartmentId
                          : null,
                      decoration: _inputDecoration('Pilih Departemen'),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF64748B)),
                      items: _departments.map((d) {
                        return DropdownMenuItem<String>(
                          value: d['id'].toString(),
                          child: Text(
                            d['name'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDepartmentId = val),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}