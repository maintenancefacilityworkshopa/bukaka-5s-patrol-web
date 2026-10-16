import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/detail_patrol_screen.dart';

class PatrolCardItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final int indexNumber;
  final VoidCallback onDelete;

  const PatrolCardItem({
    super.key,
    required this.item,
    required this.indexNumber,
    required this.onDelete,
  });

  @override
  State<PatrolCardItem> createState() => _PatrolCardItemState();
}

class _PatrolCardItemState extends State<PatrolCardItem> {
  // State lokal untuk mengontrol status terbuka/tertutupnya opsi aksi per card
  bool _isSelected = false;

  Color _getStatusColor(String status) {
    final st = status.replaceAll(' ', '_').toUpperCase();
    switch (st) {
      case 'CLOSED':
        return const Color(0xFF10B981);
      case 'IN_PROGRESS':
        return const Color(0xFFF59E0B);
      case 'OPEN':
      default:
        return const Color(0xFFF87171);
    }
  }

  Color _getStatusBgColor(String status) {
    final st = status.replaceAll(' ', '_').toUpperCase();
    switch (st) {
      case 'CLOSED':
        return const Color(0xFFA7F3D0);
      case 'IN_PROGRESS':
        return const Color(0xFFFEF3C7);
      case 'OPEN':
      default:
        return const Color(0xFFFECACA);
    }
  }

  String _formatStatusText(String status) {
    final st = status.replaceAll(' ', '_').toUpperCase();
    if (st == 'IN_PROGRESS') return 'IN PROGRESS';
    return st;
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemId = widget.item['id'];

    DateTime dateVal = DateTime.now();
    final rawDate = widget.item['created_at'] ?? widget.item['tanggal'];
    if (rawDate != null) {
      dateVal = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }
    final formattedTagDate = DateFormat('dd/MM/yyyy').format(dateVal);

    final status = (widget.item['status'] ?? 'OPEN').toString();
    final lokasi = widget.item['lokasi'] ?? '-';
    final item5s = widget.item['item_5s'] ?? '-';
    final deskripsi = widget.item['deskripsi'] ?? '-';
    final kodePatrol = widget.item['kode_patrol'] ??
        widget.item['kode'] ??
        'NP-2026-${widget.indexNumber.toString().padLeft(3, '0')}';
    final pelaporNama = widget.item['pelapor_nama'] ?? 'Pengguna';

    final statusColor = _getStatusColor(status);
    final statusBgColor = _getStatusBgColor(status);
    final statusLabel = _formatStatusText(status);

    return GestureDetector(
      onTap: () {
        // Toggle hanya state lokal card ini (tanpa mengganggu halaman utama)
        setState(() {
          _isSelected = !_isSelected;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indikator Garis Status Kiri
                Container(width: 5, color: statusColor),

                // Konten Utama Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Teks & Informational Chips
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$kodePatrol  •  $lokasi',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item5s,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                deskripsi,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildInfoChip(
                                        Icons.person_outline, pelaporNama),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                        Icons.calendar_today_outlined,
                                        formattedTagDate),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Badge Status / Tombol Aksi LIHAT & DELETE
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isSelected
                                ? Column(
                                    key: ValueKey<String>('actions_$itemId'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Tombol LIHAT
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailPatrolScreen(
                                                      patrolData: widget.item),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 72,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0E7FF),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: const Color(0xFFA5B4FC)),
                                          ),
                                          child: const Text(
                                            'LIHAT',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Color.fromARGB(
                                                  255, 116, 114, 152),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Tombol DELETE
                                      InkWell(
                                        onTap: widget.onDelete,
                                        child: Container(
                                          width: 72,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'DELETE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    key: ValueKey<String>('status_$itemId'),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
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
      ),
    );
  }
}