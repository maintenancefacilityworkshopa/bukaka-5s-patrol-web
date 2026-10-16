import 'package:flutter/material.dart';
import '../../data/notification_service.dart';
import '../../models/notification_model.dart';
import '../widgets/notification_preferences.dart';

class NotificationScreen extends StatefulWidget {
  final bool isAdmin;

  const NotificationScreen({super.key, this.isAdmin = false});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();
  String _selectedTab = 'Semua';

  static const primaryBlue = Color(0xFF00569E);

  List<String> get _tabs {
    if (widget.isAdmin) {
      return ['Semua', 'Permintaan', 'Patrol', 'Sistem'];
    } else {
      return ['Semua', 'Patrol', 'Profile', 'Sistem'];
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        // Tombol Kembali (Turn Back Button)
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: primaryBlue,
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tab Bar (Sudah diperbaiki: color dimasukkan ke dalam BoxDecoration)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _tabs.map((tab) {
                final isSelected = _selectedTab == tab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? primaryBlue : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected ? primaryBlue : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Real-time Stream Notification List
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _service.streamNotifications(isAdmin: widget.isAdmin),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawList = snapshot.data ?? [];

                final filteredList = rawList.where((item) {
                  final typeLower = item.type.toLowerCase();
                  if (_selectedTab == 'Semua') return true;
                  if ((_selectedTab == 'Permintaan' ||
                          _selectedTab == 'Profile') &&
                      (typeLower.contains('profile') ||
                          typeLower.contains('edit'))) {
                    return true;
                  }
                  if (_selectedTab == 'Patrol' &&
                      typeLower.contains('patrol')) {
                    return true;
                  }
                  if (_selectedTab == 'Sistem' &&
                      typeLower.contains('system')) {
                    return true;
                  }
                  return false;
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada notifikasi',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return _buildNotificationCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel item) {
    final typeLower = item.type.toLowerCase();
    final isPatrol = typeLower.contains('patrol');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (!item.isRead) {
            await _service.markAsRead(item.id);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF86EFAC),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPatrol
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPatrol ? Icons.assignment_outlined : Icons.calendar_month,
                  color: isPatrol ? Colors.green : Colors.amber.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: item.isRead
                                  ? FontWeight.bold
                                  : FontWeight.w900,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.message,
                      maxLines: 2,
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
                    _formatTimeAgo(item.createdAt),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
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
  }
}