import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuatPatrolScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;

  const BuatPatrolScreen({super.key, this.editData});

  @override
  State<BuatPatrolScreen> createState() => _BuatPatrolScreenState();
}

class _BuatPatrolScreenState extends State<BuatPatrolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _namaPembuatController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedLokasi;
  String? _selected5sItem;
  String _kelasTingkatan = 'LOW';
  String _statusPengerjaan = 'OPEN';

  List<Map<String, dynamic>> _locationsFromDb = [];
  bool _isLoadingLocations = true;

  Uint8List? _fotoSebelumBytes;
  Uint8List? _fotoSesudahBytes;

  String? _fotoSebelumUrl;
  String? _fotoSesudahUrl;

  bool _isLoading = false;
  bool _isLoadingProfile = true;

  final List<String> _item5sList = [
    'SEIRI - RINGKAS',
    'SEITON - RAPI',
    'SEISO - RESIK',
    'SEIKETSU - RAWAT',
    'SHITSUKE - RAJIN',
  ];

  final List<String> _kelasList = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
  final List<String> _statusList = ['OPEN', 'IN PROGRESS', 'CLOSED'];

  @override
  void initState() {
    super.initState();
    _checkLostCameraData();
    _initData();
  }

  Future<void> _checkLostCameraData() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) return;

      final bytes = await response.file!.readAsBytes();
      if (mounted) {
        setState(() {
          _fotoSebelumBytes = bytes;
        });
      }
    } on UnimplementedError catch (e) {
      debugPrint('retrieveLostData belum diimplementasikan: $e');
    } on UnsupportedError catch (e) {
      debugPrint('retrieveLostData tidak didukung di platform ini: $e');
    } catch (e) {
      debugPrint('Error memulihkan foto lost data: $e');
    }
  }

  Future<void> _initData() async {
    await _fetchLocationsFromDatabase();
    if (widget.editData != null) {
      _initEditData();
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    } else {
      await _fetchUserProfile();
    }
  }

  Future<void> _fetchLocationsFromDatabase() async {
    try {
      final response = await _supabase
          .from('locations')
          .select('id, name, description')
          .eq('is_active', true)
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _locationsFromDb = List<Map<String, dynamic>>.from(response);
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching locations from database: $e');
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _fetchUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final profileRes = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();

        if (profileRes != null && profileRes['full_name'] != null) {
          _namaPembuatController.text = profileRes['full_name'].toString();
        } else {
          _namaPembuatController.text = user.email ?? '';
        }
      } catch (e) {
        debugPrint('Error fetch user profile: $e');
      }
    }
    if (mounted) {
      setState(() => _isLoadingProfile = false);
    }
  }

  void _initEditData() {
    final data = widget.editData!;
    _judulController.text = data['judul']?.toString() ?? data['description']?.toString() ?? '';
    _namaPembuatController.text = (data['nama_pembuat'] ??
            data['name_maker'] ??
            data['inspektor'] ??
            data['pelapor_nama'] ??
            '')
        .toString();
    _selectedLokasi = data['lokasi']?.toString() ?? data['location']?.toString();
    _selected5sItem = data['item_5s']?.toString();
    _deskripsiController.text = data['deskripsi']?.toString() ?? data['description']?.toString() ?? '';

    final rawKelas = (data['kelas_tingkatan'] ?? data['priority_level'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    _kelasTingkatan = _kelasList.contains(rawKelas) ? rawKelas : 'LOW';

    String rawStatus = (data['status'] ?? '')
        .toString()
        .trim()
        .replaceAll('_', ' ')
        .toUpperCase();
    if (rawStatus == '-' ||
        rawStatus.isEmpty ||
        !_statusList.contains(rawStatus)) {
      rawStatus = 'OPEN';
    }
    _statusPengerjaan = rawStatus;

    _fotoSebelumUrl = data['foto_sebelum_url']?.toString();
    _fotoSesudahUrl = data['foto_sesudah_url']?.toString();

    final rawDate = data['created_at'] ?? data['tanggal'];
    if (rawDate != null) {
      _selectedDate = DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _namaPembuatController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  String _formatStatusForDb(String status) {
    final clean = status.trim().toUpperCase();
    if (clean == 'IN PROGRESS' || clean == 'IN_PROGRESS') return 'IN_PROGRESS';
    if (clean == 'CLOSED') return 'CLOSED';
    return 'OPEN';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00569E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage(bool isSebelum) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00569E)),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 60,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  if (mounted) {
                    setState(() {
                      if (isSebelum) {
                        _fotoSebelumBytes = bytes;
                      } else {
                        _fotoSesudahBytes = bytes;
                      }
                    });
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00569E)),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 60,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  if (mounted) {
                    setState(() {
                      if (isSebelum) {
                        _fotoSebelumBytes = bytes;
                      } else {
                        _fotoSesudahBytes = bytes;
                      }
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImageToSupabase(
      Uint8List imageBytes, String prefix) async {
    try {
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$prefix/$fileName';

      await _supabase.storage.from('patrol_images').uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '3600',
              upsert: true,
            ),
          );

      return _supabase.storage.from('patrol_images').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error upload image: $e');
      return null;
    }
  }

  Future<void> _savePatrol() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLokasi == null || _selected5sItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih Lokasi dan Tipe 5S Item!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_fotoSebelumBytes == null &&
        (_fotoSebelumUrl == null || _fotoSebelumUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto Sebelum wajib diunggah'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_statusPengerjaan == 'CLOSED' &&
        _fotoSesudahBytes == null &&
        (_fotoSesudahUrl == null || _fotoSesudahUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto Sesudah wajib diunggah jika status CLOSED!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login Anda telah berakhir. Silahkan login kembali.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? urlSebelum = _fotoSebelumUrl;
      String? urlSesudah = _fotoSesudahUrl;

      if (_fotoSebelumBytes != null) {
        urlSebelum =
            await _uploadImageToSupabase(_fotoSebelumBytes!, 'sebelum');
      }
      if (_fotoSesudahBytes != null) {
        urlSesudah =
            await _uploadImageToSupabase(_fotoSesudahBytes!, 'sesudah');
      }

      final String dbStatus = _formatStatusForDb(_statusPengerjaan);

      if (widget.editData == null) {
        final Map<String, dynamic> payload = {
          'judul': _judulController.text.trim(),
          'nama_pembuat': _namaPembuatController.text.trim(),
          'lokasi': _selectedLokasi,
          'item_5s': _selected5sItem,
          'deskripsi': _deskripsiController.text.trim(),
          'kelas_tingkatan': _kelasTingkatan,
          'status': dbStatus,
          'started_at': DateTime.now().toIso8601String(),
          'finished_at': dbStatus == 'CLOSED' ? DateTime.now().toIso8601String() : null,
          'foto_sebelum_url': urlSebelum,
          'foto_sesudah_url': urlSesudah,
          'created_by': currentUser.id,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _supabase.from('patrols').insert(payload);
      } else {
        final patrolId = widget.editData!['id'];
        final oldStatus = (widget.editData!['status'] ?? 'OPEN').toString();
        final createdByUserId = widget.editData!['created_by'];

        final Map<String, dynamic> updatePayload = {
          'judul': _judulController.text.trim(),
          'lokasi': _selectedLokasi,
          'item_5s': _selected5sItem,
          'deskripsi': _deskripsiController.text.trim(),
          'kelas_tingkatan': _kelasTingkatan,
          'status': dbStatus,
          'finished_at': dbStatus == 'CLOSED' ? DateTime.now().toIso8601String() : null,
          'foto_sebelum_url': urlSebelum,
          'foto_sesudah_url': urlSesudah,
        };

        await _supabase.from('patrols').update(updatePayload).eq('id', patrolId);

        try {
          await _supabase.from('patrol_status_logs').insert({
            'patrol_id': patrolId,
            'previous_status': oldStatus,
            'new_status': dbStatus,
            'changed_by': currentUser.id,
            'name_changed_by': _namaPembuatController.text.trim(),
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (logError) {
          debugPrint('Gagal mencatat status log: $logError');
        }

        if (createdByUserId != null && createdByUserId != currentUser.id) {
          try {
            await _supabase.from('notifications').insert({
              'user_id': createdByUserId,
              'title': 'Patroli Diperbarui',
              'message':
                  'Laporan patroli "${_judulController.text.trim()}" telah diperbarui menjadi status $dbStatus.',
              'type': 'patrol',
              'reference_id': patrolId,
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          } catch (notifError) {
            debugPrint('Gagal mengirim notifikasi: $notifError');
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editData == null
              ? 'Patroli berhasil dibuat!'
              : 'Patroli berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan patroli: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          widget.editData == null ? 'FORM PATROL' : 'EDIT PATROL',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: (_isLoading || _isLoadingProfile)
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 110.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tanggal Pembuatan'),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: _buildInputBoxDecoration(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                            const Icon(Icons.calendar_month_outlined,
                                size: 20, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Judul Patrol'),
                    TextFormField(
                      controller: _judulController,
                      style: const TextStyle(fontSize: 14),
                      decoration:
                          _buildInputDecoration('Masukkan judul patrol'),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Judul patrol wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Nama Pembuat Patrol'),
                    TextFormField(
                      controller: _namaPembuatController,
                      readOnly: true,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF374151)),
                      decoration: _buildInputDecoration('Nama pembuat')
                          .copyWith(
                            fillColor: const Color(0xFFF3F4F6),
                            suffixIcon: const Icon(Icons.lock_outline,
                                size: 18, color: Colors.grey),
                          ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Nama pembuat wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Lokasi Patrol'),
                    _isLoadingLocations
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _locationsFromDb.any((loc) {
                              final name = loc['name']?.toString() ?? '';
                              final desc = loc['description']?.toString() ?? '';
                              return name == _selectedLokasi || desc == _selectedLokasi;
                            })
                                ? _locationsFromDb.firstWhere((loc) {
                                    final name = loc['name']?.toString() ?? '';
                                    final desc = loc['description']?.toString() ?? '';
                                    return name == _selectedLokasi || desc == _selectedLokasi;
                                  })['name']?.toString()
                                : null,
                            decoration: _buildInputDecoration('Pilih lokasi patrol'),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.black54),
                            items: _locationsFromDb.map((loc) {
                              final String displayName = (loc['name'] != null && loc['name'].toString().isNotEmpty)
                                  ? loc['name'].toString()
                                  : loc['description'].toString();

                              return DropdownMenuItem<String>(
                                value: displayName,
                                child: Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedLokasi = val),
                            validator: (val) =>
                                val == null ? 'Lokasi patrol wajib dipilih' : null,
                          ),
                    const SizedBox(height: 14),

                    _buildLabel('Tipe 5S Item'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selected5sItem,
                      decoration: _buildInputDecoration('Pilih tipe 5S'),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.black54),
                      items: _item5sList.map((String item) {
                        return DropdownMenuItem(
                            value: item,
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ));
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selected5sItem = val),
                      validator: (val) =>
                          val == null ? 'Tipe 5S wajib dipilih' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Deskripsi'),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      maxLength: 1500,
                      style: const TextStyle(fontSize: 14),
                      decoration:
                          _buildInputDecoration('Tuliskan deskripsi temuan...'),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Kelas Tingkatan'),
                    Row(
                      children: _kelasList.map((kelas) {
                        final isSelected = _kelasTingkatan == kelas;
                        Color activeColor = Colors.grey;
                        if (kelas == 'CRITICAL') {
                          activeColor = const Color(0xFFD32F2F);
                        }
                        if (kelas == 'HIGH') activeColor = Colors.orange;
                        if (kelas == 'MEDIUM') activeColor = Colors.blue;
                        if (kelas == 'LOW') activeColor = Colors.green;

                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2.0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                backgroundColor:
                                    isSelected ? activeColor : Colors.white,
                                foregroundColor:
                                    isSelected ? Colors.white : Colors.black87,
                                side: BorderSide(
                                    color: isSelected
                                        ? activeColor
                                        : Colors.black26),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () =>
                                  setState(() => _kelasTingkatan = kelas),
                              child: Text(
                                kelas,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Indikator Pengerjaan'),
                    Row(
                      children: _statusList.map((status) {
                        final isSelected = _statusPengerjaan == status;
                        Color statusBtnColor = primaryBlue;
                        if (status == 'IN PROGRESS') {
                          statusBtnColor = const Color(0xFFFFB74D);
                        }
                        if (status == 'CLOSED') statusBtnColor = Colors.green;
                        if (status == 'OPEN') statusBtnColor = Colors.redAccent;

                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2.0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                backgroundColor: isSelected
                                    ? statusBtnColor.withValues(alpha: 0.15)
                                    : Colors.white,
                                foregroundColor:
                                    isSelected ? statusBtnColor : Colors.black87,
                                side: BorderSide(
                                    color: isSelected
                                        ? statusBtnColor
                                        : Colors.black26,
                                    width: isSelected ? 1.5 : 1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () =>
                                  setState(() => _statusPengerjaan = status),
                              child: Text(
                                status,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Upload Foto Sebelum'),
                    _buildPhotoBox(
                      imageBytes: _fotoSebelumBytes,
                      imageUrl: _fotoSebelumUrl,
                      onTap: () => _pickImage(true),
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Upload Foto Sesudah (Wajib jika CLOSED)'),
                    _buildPhotoBox(
                      imageBytes: _fotoSesudahBytes,
                      imageUrl: _fotoSesudahUrl,
                      onTap: () => _pickImage(false),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: primaryBlue, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'BATAL',
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22)),
                                elevation: 0,
                              ),
                              onPressed: _savePatrol,
                              child: const Text(
                                'SIMPAN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  BoxDecoration _buildInputBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black26),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
      fillColor: const Color(0xFFF8F9FA),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
    );
  }

  Widget _buildPhotoBox({
    required Uint8List? imageBytes,
    required String? imageUrl,
    required VoidCallback onTap,
  }) {
    const primaryBlue = Color(0xFF00569E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              )
            : (imageUrl != null && imageUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt_outlined,
                          color: primaryBlue, size: 30),
                      SizedBox(height: 6),
                      Text(
                        'Ambil / Upload Foto',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}