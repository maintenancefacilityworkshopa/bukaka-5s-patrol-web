import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'buat_patrol_screen.dart';

class DetailPatrolScreen extends StatefulWidget {
  final Map<String, dynamic> patrolData;

  const DetailPatrolScreen({
    super.key,
    required this.patrolData,
  });

  @override
  State<DetailPatrolScreen> createState() => _DetailPatrolScreenState();
}

class _DetailPatrolScreenState extends State<DetailPatrolScreen> {
  final _supabase = Supabase.instance.client;
  late Map<String, dynamic> _currentData;
  bool _isLoadingLatest = false;

  bool _isAdmin = false;
  bool _isPicArea = false;
  String? _areaResponsibility;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentData = Map<String, dynamic>.from(widget.patrolData);
    _checkUserRoleAndPermissions();
    _fetchFreshData();
  }

  Future<void> _checkUserRoleAndPermissions() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      try {
        final data = await _supabase
            .from('profiles')
            .select('role, area_responsibility')
            .eq('id', user.id)
            .maybeSingle();

        if (mounted && data != null) {
          final roleStr = (data['role'] ?? '').toString().toUpperCase();
          setState(() {
            _isAdmin = (roleStr == 'ADMIN' || roleStr == 'ADMINISTRATOR');
            _isPicArea = (roleStr == 'PIC_AREA');
            _areaResponsibility = data['area_responsibility']?.toString();
          });
        }
      } catch (e) {
        debugPrint('Error fetch user role: $e');
      }
    }
  }

  Future<void> _fetchFreshData() async {
    final recordId = _currentData['id'];
    final kodePatrol = _currentData['kode_patrol'] ?? _currentData['kode'];
    if (recordId == null && kodePatrol == null) return;

    setState(() => _isLoadingLatest = true);
    try {
      final query = _supabase.from('patrols').select();
      final response = recordId != null
          ? await query.eq('id', recordId).maybeSingle()
          : await query.eq('kode_patrol', kodePatrol).maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _currentData = Map<String, dynamic>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetch fresh patrol data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLatest = false);
    }
  }

  bool _canUserEdit() {
    if (_isAdmin) return true;

    final createdBy = _currentData['created_by']?.toString();
    if (createdBy != null && createdBy == _currentUserId) return true;

    if (_isPicArea) {
      if (_areaResponsibility == null || _areaResponsibility!.isEmpty) {
        return false;
      }

      final userArea = _areaResponsibility!.toLowerCase().trim();
      final patrolLocation = (_currentData['lokasi'] ??
              _currentData['location'] ??
              '')
          .toString()
          .toLowerCase()
          .trim();

      return patrolLocation == userArea ||
          patrolLocation.contains(userArea) ||
          userArea.contains(patrolLocation);
    }

    return false;
  }

  void _handleEditAction() async {
    if (!_canUserEdit()) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Patroli ini bukan kebijakan anda',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final isUpdated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BuatPatrolScreen(
          editData: _currentData,
        ),
      ),
    );

    if (isUpdated == true) {
      _fetchFreshData();
    }
  }

  String _formatTanggal(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;

    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(parsed.toLocal());
    } catch (_) {
      return DateFormat('dd MMMM yyyy').format(parsed.toLocal());
    }
  }

  String? _resolveImageUrl(dynamic rawPath) {
    if (rawPath == null) return null;
    String pathStr = rawPath.toString().trim();
    if (pathStr.isEmpty) return null;

    if (pathStr.startsWith('http://') || pathStr.startsWith('https://')) {
      return pathStr;
    }

    if (pathStr.startsWith('patrol_images/')) {
      pathStr = pathStr.replaceFirst('patrol_images/', '');
    } else if (pathStr.startsWith('/patrol_images/')) {
      pathStr = pathStr.replaceFirst('/patrol_images/', '');
    }

    try {
      final publicUrl =
          _supabase.storage.from('patrol_images').getPublicUrl(pathStr);
      return publicUrl;
    } catch (e) {
      debugPrint('Error getPublicUrl: $e');
      return pathStr;
    }
  }

  Color _getStatusBgColor(String status) {
    final cleanStatus = status.replaceAll('_', ' ').toUpperCase();
    switch (cleanStatus) {
      case 'IN PROGRESS':
        return const Color(0xFFFEF0C7);
      case 'CLOSED':
        return const Color(0xFFD1FADF);
      case 'OPEN':
        return const Color(0xFFFCA5A5);
      default:
        return const Color(0xFFEAECF0);
    }
  }

  Color _getStatusTextColor(String status) {
    final cleanStatus = status.replaceAll('_', ' ').toUpperCase();
    switch (cleanStatus) {
      case 'IN PROGRESS':
        return const Color(0xFFDC6803);
      case 'CLOSED':
        return const Color(0xFF12B76A);
      case 'OPEN':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF667085);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    final rawStatus = (_currentData['status'] ?? 'OPEN').toString();
    final statusDisplay = rawStatus.replaceAll('_', ' ').toUpperCase();

    final patrolId = _currentData['kode_patrol'] ??
        _currentData['kode'] ??
        _currentData['id'] ??
        '-';
    final tanggal =
        _formatTanggal(_currentData['created_at'] ?? _currentData['tanggal']);
    final item5s = _currentData['item_5s'] ?? '-';
    final judul = _currentData['judul'] ?? _currentData['description'] ?? '-';
    final inspektor = _currentData['name_maker'] ??
        _currentData['nama_pembuat'] ??
        _currentData['pelapor_nama'] ??
        'Pengguna';
    final lokasi = _currentData['lokasi'] ?? _currentData['location'] ?? '-';
    final deskripsi = _currentData['description'] ??
        _currentData['deskripsi'] ??
        '-';
    final priorityTag = _currentData['priority_level'] ??
        _currentData['kelas_tingkatan'] ??
        'LOW';

    final rawFotoBefore = _currentData['photo_before_url'] ??
        _currentData['foto_sebelum_url'] ??
        _currentData['foto_before'];

    final rawFotoAfter = _currentData['photo_after_url'] ??
        _currentData['foto_sesudah_url'] ??
        _currentData['foto_after'];

    final fotoBeforeUrl = _resolveImageUrl(rawFotoBefore);
    final fotoAfterUrl = _resolveImageUrl(rawFotoAfter);

    final bool canEdit = _canUserEdit();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DETAIL PATROL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoadingLatest
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusBgColor(rawStatus),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusDisplay,
                                    style: TextStyle(
                                      color: _getStatusTextColor(rawStatus),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'ID : $patrolId',
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(0xFFF87171)),
                                  ),
                                  child: Text(
                                    priorityTag.toString().toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _LabelRow(
                                              icon: Icons.assignment_outlined,
                                              label: '5S Item'),
                                          SizedBox(height: 10),
                                          _LabelRow(
                                              icon: Icons
                                                  .calendar_today_outlined,
                                              label: 'Tanggal'),
                                          SizedBox(height: 10),
                                          _LabelRow(
                                              icon: Icons.description_outlined,
                                              label: 'Team Patroli'),
                                          SizedBox(height: 10),
                                          _LabelRow(
                                              icon: Icons.people_outline,
                                              label: 'Inspektor'),
                                          SizedBox(height: 10),
                                          _LabelRow(
                                              icon: Icons.location_on_outlined,
                                              label: 'Lokasi'),
                                          SizedBox(height: 10),
                                          _LabelRow(
                                              icon: Icons.error_outline,
                                              label: 'Deskripsi'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(
                                      width: 1,
                                      thickness: 1,
                                      color: Color(0xFFE5E7EB)),
                                  Expanded(
                                    flex: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item5s,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 10),
                                          Text(tanggal,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 10),
                                          Text(judul,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 10),
                                          Text(inspektor,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 10),
                                          Text(lokasi,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 10),
                                          Text(
                                            deskripsi,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Center(
                            child: Text(
                              'FOTO SEBELUM',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildImageCard(fotoBeforeUrl, title: 'FOTO SEBELUM'),

                          const SizedBox(height: 16),

                          const Center(
                            child: Text(
                              'FOTO SESUDAH',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildImageCard(fotoAfterUrl, title: 'FOTO SESUDAH'),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                            color: canEdit ? primaryBlue : Colors.grey,
                            width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                        backgroundColor: canEdit
                            ? const Color(0xFFF0F9FF)
                            : Colors.grey.shade100,
                      ),
                      onPressed: _handleEditAction,
                      child: Text(
                        'EDIT',
                        style: TextStyle(
                          color: canEdit ? primaryBlue : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'TUTUP',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String? imageUrl, {required String title}) {
    const primaryBlue = Color(0xFF00569E);
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: hasImage ? () => _openImageZoomViewer(imageUrl, title) : null,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryBlue, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: primaryBlue),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder(
                          icon: Icons.broken_image_outlined,
                          text: 'Gagal memuat foto',
                        );
                      },
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.zoom_in_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                )
              : _buildPlaceholder(
                  icon: Icons.image_not_supported_outlined,
                  text: 'Tidak ada foto',
                ),
        ),
      ),
    );
  }

  void _openImageZoomViewer(String imageUrl, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) => _ZoomableImageDialog(
        imageUrl: imageUrl,
        title: title,
      ),
    );
  }

  Widget _buildPlaceholder({required IconData icon, required String text}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black38, size: 36),
          const SizedBox(height: 6),
          Text(text,
              style: const TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LabelRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _ZoomableImageDialog extends StatefulWidget {
  final String imageUrl;
  final String title;

  const _ZoomableImageDialog({
    required this.imageUrl,
    required this.title,
  });

  @override
  State<_ZoomableImageDialog> createState() => _ZoomableImageDialogState();
}

class _ZoomableImageDialogState extends State<_ZoomableImageDialog> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final position = _doubleTapDetails!.localPosition;
      const double scale = 2.5;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (scale - 1),
          -position.dy * (scale - 1),
          0.0,
          1.0,
        )
        ..scaleByDouble(scale, scale, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.8,
                  maxScale: 5.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                color: Colors.white54, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'Gagal memuat gambar',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                    ),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 24),
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