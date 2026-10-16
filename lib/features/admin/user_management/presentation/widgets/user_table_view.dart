import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class UserTableView extends StatelessWidget {
  final List<UserModel> users;
  final Function(UserModel) onEdit;
  final Function(String) onDelete;

  const UserTableView({
    super.key,
    required this.users,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Deteksi apakah tampilan berjalan di Web/Desktop (layar > 600px)
        final bool isDesktop = constraints.maxWidth > 600;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SingleChildScrollView(
              // Jika di Mobile/Tablet, aktifkan scroll horizontal agar tidak terpotong
              scrollDirection: isDesktop ? Axis.vertical : Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Memaksa lebar tabel minimal sama dengan lebar container layar
                  minWidth: constraints.maxWidth,
                ),
                child: DataTable(
                  horizontalMargin: 16,
                  columnSpacing: isDesktop ? 24 : 16,
                  headingRowHeight: 48,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: [
                    DataColumn(
                      label: Expanded(
                        flex: 3,
                        child: Text(
                          'Nama',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 13 : 12,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        flex: 4,
                        child: Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 13 : 12,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        flex: 2,
                        child: Text(
                          'Role',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 13 : 12,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        flex: 2,
                        child: Text(
                          'Terakhir Aktif',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 13 : 12,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Aksi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 13 : 12,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                  rows: users.map((user) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            user.fullName.isNotEmpty ? user.fullName : '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            user.email.isNotEmpty ? user.email : '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataCell(_buildRoleBadge(user.displayRole)),
                        DataCell(
                          Text(
                            _formatLastActive(user.updatedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () => onEdit(user),
                              ),
                              PopupMenuButton<String>(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') onDelete(user.id);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Hapus Pengguna',
                                          style: TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String displayRole) {
    Color bgColor;
    Color textColor;

    switch (displayRole) {
      case 'Admin':
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF2563EB);
        break;
      case 'Intern':
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFEA580C);
        break;
      case 'Staff Ahli':
      default:
        bgColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF16A34A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayRole,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatLastActive(DateTime? date) {
    if (date == null) return '-';
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes} jam lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }
}