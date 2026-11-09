import 'package:flutter/material.dart';

class UserFilterBar extends StatelessWidget {
  final String searchQuery;
  final String selectedRole;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleChanged;

  const UserFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedRole,
    required this.onSearchChanged,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Cari nama, email, NIK...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRole,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              items: ['Semua Role', 'Admin', 'PIC Area', 'Staff Ahli', 'Staff Internship'].map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (val) {
                if (val != null) onRoleChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}