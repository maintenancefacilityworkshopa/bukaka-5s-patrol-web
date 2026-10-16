import 'package:flutter/material.dart';
import '../../models/patrol_schedule_model.dart';

class PatrolScheduleDialog extends StatefulWidget {
  final PatrolScheduleModel? schedule;
  final ValueChanged<PatrolScheduleModel> onSave;

  const PatrolScheduleDialog({
    super.key,
    this.schedule,
    required this.onSave,
  });

  @override
  State<PatrolScheduleDialog> createState() => _PatrolScheduleDialogState();
}

class _PatrolScheduleDialogState extends State<PatrolScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _areaController;
  late TextEditingController _locationsController;
  late TextEditingController _inspectorsController;
  late TextEditingController _inspectorNameController;
  late TextEditingController _dateController;
  
  String _status = 'Aktif';
  String _shift = 'Shift 1';

  static const primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    final item = widget.schedule;
    _titleController = TextEditingController(text: item?.title ?? '');
    _areaController = TextEditingController(text: item?.area ?? '');
    _locationsController = TextEditingController(text: item?.totalLocations.toString() ?? '0');
    _inspectorsController = TextEditingController(text: item?.totalInspectors.toString() ?? '0');
    _inspectorNameController = TextEditingController(text: item?.inspectorName ?? '');
    _dateController = TextEditingController(text: item?.date ?? '');
    _status = item?.status ?? 'Aktif';
    _shift = item?.shift ?? 'Shift 1';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _areaController.dispose();
    _locationsController.dispose();
    _inspectorsController.dispose();
    _inspectorNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newSchedule = PatrolScheduleModel(
        id: widget.schedule?.id,
        title: _titleController.text.trim(),
        area: _areaController.text.trim(),
        status: _status,
        totalLocations: int.tryParse(_locationsController.text.trim()) ?? 0,
        totalInspectors: int.tryParse(_inspectorsController.text.trim()) ?? 0,
        inspectorName: _inspectorNameController.text.trim(),
        weekNumber: widget.schedule?.weekNumber ?? 1,
        month: widget.schedule?.month ?? 'Agustus',
        year: widget.schedule?.year ?? '2026',
        date: _dateController.text.trim(),
        shift: _shift,
      );

      widget.onSave(newSchedule);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.schedule != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Schedule Patrol' : 'Buat Schedule Patrol Baru',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Judul Schedule', _titleController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Area', _areaController)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: ['Aktif', 'Selesai', 'Draft']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (val) => setState(() => _status = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Jumlah Lokasi', _locationsController, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Jumlah Petugas', _inspectorsController, isNumber: true)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('Nama Inspektur Utama / PJ', _inspectorNameController),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                    onPressed: _submit,
                    child: Text(isEdit ? 'Simpan' : 'Buat Schedule', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Wajib diisi';
            }
            return null;
          },
        ),
      ],
    );
  }
}