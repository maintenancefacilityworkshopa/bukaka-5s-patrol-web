import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../notification/presentation/screens/notification_screen.dart';
import '../../data/models/notification_item_model.dart';
import '../../../patrol/presentation/screens/detail_patrol_screen.dart';

class DashboardNotificationList extends StatelessWidget {
  final List<NotificationItemModel> notifications;
  final Function(NotificationItemModel)? onItemTap;
  final VoidCallback? onRefreshRequested;

  const DashboardNotificationList({
    super.key,
    required this.notifications,
    this.onItemTap,
    this.onRefreshRequested,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _handleNotificationClick(BuildContext context, NotificationItemModel n) async {
    if (onItemTap != null) {
      onItemTap!(n);
    }

    final patrolId = n.referenceId;
    if (patrolId == null || patrolId.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('patrols')
          .select()
          .or('kode_patrol.eq.$patrolId,id.eq.$patrolId')
          .maybeSingle();

      if (context.mounted) Navigator.pop(context);

      if (response != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPatrolScreen(
              patrolData: Map<String, dynamic>.from(response),
            ),
          ),
        ).then((_) {
          if (onRefreshRequested != null) onRefreshRequested!();
        });
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data patroli tidak ditemukan di database')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail patroli: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'NOTIFIKASI',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                ).then((_) {
                  if (onRefreshRequested != null) onRefreshRequested!();
                });
              },
              child: const Text(
                'Lihat semua >',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (notifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Text(
              'Tidak ada notifikasi terbaru',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          )
        else
          // TAMPILKAN 5 NOTIFIKASI TERBARU
          ...notifications.take(5).map((n) {
            final typeLower = n.type.toLowerCase();
            final isPatrol = typeLower.contains('patrol');
            final isProfile = typeLower.contains('profile');

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleNotificationClick(context, n),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: n.isRead ? Colors.white : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: n.isRead
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF86EFAC),
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPatrol
                                  ? const Color(0xFFDCFCE7)
                                  : isProfile
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPatrol
                                  ? Icons.assignment_outlined
                                  : isProfile
                                      ? Icons.person_outline_rounded
                                      : Icons.notifications_active_rounded,
                              color: isPatrol
                                  ? const Color(0xFF16A34A)
                                  : isProfile
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFD97706),
                              size: 18,
                            ),
                          ),
                          if (!n.isRead)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: n.isRead
                                    ? FontWeight.bold
                                    : FontWeight.w900,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTimeAgo(n.createdAt),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}