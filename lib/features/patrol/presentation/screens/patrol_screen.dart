import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/patrol_remote_datasource.dart';
import '../../data/repositories/patrol_repository_impl.dart';
import '../../domain/repositories/patrol_repository.dart';
import '../widgets/patrol_card_item.dart';
import '../widgets/patrol_header_filter.dart';

class PatrolScreen extends StatefulWidget {
  const PatrolScreen({super.key});

  @override
  State<PatrolScreen> createState() => _PatrolScreenState();
}

class _PatrolScreenState extends State<PatrolScreen> {
  late final PatrolRepository _repository;

  String _searchQuery = '';
  String _selectedStatus = 'Semua Status';
  String _selectedLokasi = 'Semua Lokasi';
  SortOption _selectedSort = SortOption.terbaru;

  bool _isAdmin = false;
  String? _currentUserId;
  bool _isLoadingRole = true;

  // Map lokal penampung cache profil pelapor agar tidak melakukan fetch ulang terus menerus
  final Map<String, String> _cachedProfiles = {};

  final List<String> _statusOptions = const [
    'Semua Status',
    'OPEN',
    'IN PROGRESS',
    'CLOSED',
  ];

  final List<String> _lokasiOptions = const [
    'Semua Lokasi',
    'Area Production Line A',
    'Area Production Line B',
    'Area Production Line C',
    'Area Production Line D-E',
    'Area Production Line F',
    'Area Production Line G',
    'Area Line Blasting Painting',
    'Area Line Corrugated',
    'Area Longspan',
    'Area Stockyard Packing',
    'Area Warehouse Utama',
    'Maintenance Area',
  ];

  @override
  void initState() {
    super.initState();
    final remoteDatasource = PatrolRemoteDatasource(Supabase.instance.client);
    _repository = PatrolRepositoryImpl(remoteDatasource);
    _checkUserRole();
  }

  @override
  void dispose() {
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    _currentUserId = _repository.getCurrentUserId();
    if (_currentUserId != null) {
      try {
        final roleStr = await _repository.getCurrentUserRole();
        if (mounted) {
          setState(() {
            _isAdmin = (roleStr?.toUpperCase() == 'ADMIN');
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetch user role: $e');
        if (mounted) setState(() => _isLoadingRole = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _checkUserRole();
    if (mounted) {
      setState(() {});
    }
  }

  void _showAccessDeniedBanner(String ownerName) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        backgroundColor: const Color(0xFFDC2626),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Akses Ditolak: Patrol ini milik $ownerName',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sinkronisasi profil tanpa memblokir/re-render UI utama secara langsung
  void _syncProfilesIfNeeded(List<Map<String, dynamic>> rawPatrols) {
    final missingUserIds = rawPatrols
        .map((e) => e['created_by']?.toString())
        .where((id) => id != null && !_cachedProfiles.containsKey(id))
        .cast<String>()
        .toSet()
        .toList();

    if (missingUserIds.isNotEmpty) {
      _repository.getProfilesMap(missingUserIds).then((newMap) {
        if (mounted && newMap.isNotEmpty) {
          setState(() {
            _cachedProfiles.addAll(newMap);
          });
        }
      }).catchError((e) {
        debugPrint('Error fetching profiles: $e');
      });
    }
  }

  List<Map<String, dynamic>> _processAndFilterData(
      List<Map<String, dynamic>> rawList) {
    List<Map<String, dynamic>> list = rawList.map((patrol) {
      final createdBy = patrol['created_by']?.toString();
      final updatedPatrol = Map<String, dynamic>.from(patrol);
      updatedPatrol['pelapor_nama'] = _cachedProfiles[createdBy] ??
          patrol['pelapor_nama'] ??
          patrol['created_by_name'] ??
          'Pengguna';
      return updatedPatrol;
    }).toList();

    if (_selectedStatus != 'Semua Status') {
      final filterKey = _selectedStatus.replaceAll(' ', '_').toUpperCase();
      list = list.where((item) {
        final st =
            (item['status'] ?? '').toString().replaceAll(' ', '_').toUpperCase();
        return st == filterKey;
      }).toList();
    }

    if (_selectedLokasi != 'Semua Lokasi') {
      list = list.where((item) => item['lokasi'] == _selectedLokasi).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) {
        final lokasi = (item['lokasi'] ?? '').toString().toLowerCase();
        final item5s = (item['item_5s'] ?? '').toString().toLowerCase();
        final deskripsi = (item['deskripsi'] ?? '').toString().toLowerCase();
        final kode =
            (item['kode_patrol'] ?? item['kode'] ?? '').toString().toLowerCase();
        final pelapor = (item['pelapor_nama'] ?? '').toString().toLowerCase();
        return lokasi.contains(q) ||
            item5s.contains(q) ||
            deskripsi.contains(q) ||
            kode.contains(q) ||
            pelapor.contains(q);
      }).toList();
    }

    list.sort((a, b) {
      final kodeA = (a['kode_patrol'] ?? a['kode'] ?? '').toString();
      final kodeB = (b['kode_patrol'] ?? b['kode'] ?? '').toString();

      final dateA = DateTime.tryParse(a['created_at'] ?? a['tanggal'] ?? '') ??
          DateTime.now();
      final dateB = DateTime.tryParse(b['created_at'] ?? b['tanggal'] ?? '') ??
          DateTime.now();

      final lokasiA = (a['lokasi'] ?? '').toString().toLowerCase();
      final lokasiB = (b['lokasi'] ?? '').toString().toLowerCase();

      switch (_selectedSort) {
        case SortOption.terbaru:
          if (kodeA.isNotEmpty && kodeB.isNotEmpty) {
            return kodeB.compareTo(kodeA);
          }
          return dateB.compareTo(dateA);

        case SortOption.terdahulu:
          if (kodeA.isNotEmpty && kodeB.isNotEmpty) {
            return kodeA.compareTo(kodeB);
          }
          return dateA.compareTo(dateB);

        case SortOption.alfabetAsc:
          return lokasiA.compareTo(lokasiB);

        case SortOption.alfabetDesc:
          return lokasiB.compareTo(lokasiA);
      }
    });

    return list;
  }

  void _confirmDeletePatrol(dynamic id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Patrol?'),
        content:
            const Text('Data ini akan dihapus secara permanen dari database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF04438),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);

              try {
                await _repository.deletePatrol(id);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Patrol berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: _isLoadingRole
            ? const Center(
                child: CircularProgressIndicator(color: primaryBlue))
            : Column(
                children: [
                  PatrolHeaderFilter(
                    onSearchChanged: (val) =>
                        setState(() => _searchQuery = val),
                    selectedStatus: _selectedStatus,
                    statusOptions: _statusOptions,
                    onStatusChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                    selectedLokasi: _selectedLokasi,
                    lokasiOptions: _lokasiOptions,
                    onLokasiChanged: (val) {
                      if (val != null) setState(() => _selectedLokasi = val);
                    },
                    selectedSort: _selectedSort,
                    onSortChanged: (sort) =>
                        setState(() => _selectedSort = sort),
                  ),

                  Expanded(
                    child: StreamBuilder(
                      stream: _repository.getPatrolsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: primaryBlue));
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child:
                                  Text('Terjadi Kesalahan: ${snapshot.error}'));
                        }

                        final patrolModels = snapshot.data ?? [];
                        final rawList =
                            patrolModels.map((e) => e.toMap()).toList();

                        // Ambil profil baru di latar belakang tanpa memblokir proses render UI
                        _syncProfilesIfNeeded(rawList);

                        final patrols = _processAndFilterData(rawList);

                        if (patrols.isEmpty) {
                          return RefreshIndicator(
                            color: primaryBlue,
                            onRefresh: _handleRefresh,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 200),
                                Center(
                                  child: Text('Belum ada data patroli.',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: primaryBlue,
                          onRefresh: _handleRefresh,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 110),
                            itemCount: patrols.length,
                            itemBuilder: (context, index) {
                              final item = patrols[index];
                              final pelaporNama =
                                  item['pelapor_nama'] ?? 'Pengguna';
                              final isOwner =
                                  item['created_by'] == _currentUserId;
                              final canManage = _isAdmin || isOwner;

                              return PatrolCardItem(
                                key: ValueKey(item['id']),
                                item: item,
                                indexNumber: index + 1,
                                onDelete: () {
                                  if (canManage) {
                                    _confirmDeletePatrol(item['id']);
                                  } else {
                                    _showAccessDeniedBanner(pelaporNama);
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}