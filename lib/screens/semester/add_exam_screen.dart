import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/semester_provider.dart';

/// Adds an exam date to the semester outline. On save, [SemesterProvider]
/// schedules the countdown notifications (default 7/3/1 days out) via
/// [NotificationService] — this screen only collects the details.
class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _examDate = DateTime.now().add(const Duration(days: 14));
  TimeOfDay? _examTime;
  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _venueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _examDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _examTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) setState(() => _examTime = time);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final timeStr = _examTime != null
        ? '${_examTime!.hour.toString().padLeft(2, '0')}:${_examTime!.minute.toString().padLeft(2, '0')}'
        : null;
    await context.read<SemesterProvider>().addExam(
          courseCode: _codeCtrl.text.trim(),
          courseName: _nameCtrl.text.trim(),
          examDate: _examDate,
          examTime: timeStr,
          venue: _venueCtrl.text.trim().isEmpty ? null : _venueCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add exam')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Course code'),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Course name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _venueCtrl,
              decoration: const InputDecoration(labelText: 'Venue (optional)'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            const Text('Exam date', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(DateFormat('EEE, MMM d, y').format(_examDate)),
            ),
            const SizedBox(height: 14),
            const Text('Exam time (optional)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule),
              label: Text(_examTime == null ? 'TBA' : _examTime!.format(context)),
            ),
            const SizedBox(height: 8),
            Text(
              "We'll remind you 7, 3, and 1 day(s) before this exam — "
              'you can change the schedule in Settings.',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add exam'),
            ),
          ],
        ),
      ),
    );
  }
}
