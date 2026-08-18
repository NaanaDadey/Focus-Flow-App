import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/timetable_entry_model.dart';
import '../../providers/timetable_provider.dart';

const _swatches = [
  '#6C63FF',
  '#E74C3C',
  '#2ECC71',
  '#F5A623',
  '#3498DB',
  '#E67E22',
];

class AddTimetableEntryScreen extends StatefulWidget {
  final TimetableEntryModel? entry;
  final int? initialDay;
  const AddTimetableEntryScreen({super.key, this.entry, this.initialDay});

  @override
  State<AddTimetableEntryScreen> createState() => _AddTimetableEntryScreenState();
}

class _AddTimetableEntryScreenState extends State<AddTimetableEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late int _dayOfWeek;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late String _color;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _codeCtrl = TextEditingController(text: e?.courseCode ?? '');
    _nameCtrl = TextEditingController(text: e?.courseName ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _dayOfWeek = e?.dayOfWeek ?? widget.initialDay ?? DateTime.now().weekday;
    _start = e != null ? _parseTime(e.startTime) : const TimeOfDay(hour: 9, minute: 0);
    _end = e != null ? _parseTime(e.endTime) : const TimeOfDay(hour: 11, minute: 0);
    _color = e?.colorHex ?? _swatches.first;
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TimetableProvider>();

    if (_isEditing) {
      final updated = widget.entry!
        ..courseCode = _codeCtrl.text.trim()
        ..courseName = _nameCtrl.text.trim()
        ..dayOfWeek = _dayOfWeek
        ..startTime = _fmt(_start)
        ..endTime = _fmt(_end)
        ..location = _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim()
        ..colorHex = _color;
      await provider.updateEntry(updated);
    } else {
      await provider.addEntry(
        courseCode: _codeCtrl.text.trim(),
        courseName: _nameCtrl.text.trim(),
        dayOfWeek: _dayOfWeek,
        startTime: _fmt(_start),
        endTime: _fmt(_end),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        colorHex: _color,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await context.read<TimetableProvider>().deleteEntry(widget.entry!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit class' : 'Add class'),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Course code'),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Course name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
            ),
            const SizedBox(height: 18),
            const Text('Day', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                return ChoiceChip(
                  label: Text(AppConstants.weekdayShort[i]),
                  selected: _dayOfWeek == day,
                  onSelected: (_) => setState(() => _dayOfWeek = day),
                );
              }),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Start',
                    time: _start,
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _start);
                      if (t != null) setState(() => _start = t);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _TimeField(
                    label: 'End',
                    time: _end,
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _end);
                      if (t != null) setState(() => _end = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _swatches.map((hex) {
                final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final selected = _color == hex;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: AppTheme.seed, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save changes' : 'Add to timetable'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeField({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text('$label: ${time.format(context)}'),
    );
  }
}
