import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/semester_provider.dart';

/// Lets a student key in their semester outline course-by-course:
/// code, name, credit hours, and instructor. Feeds the "Courses" tab
/// and gives tasks/exams a `courseCode` to link back to.
class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _instructorCtrl = TextEditingController();
  double _creditHours = 3;
  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _instructorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<SemesterProvider>().addCourse(
          courseCode: _codeCtrl.text.trim(),
          courseName: _nameCtrl.text.trim(),
          creditHours: _creditHours,
          instructor: _instructorCtrl.text.trim().isEmpty
              ? null
              : _instructorCtrl.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add course')),
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
              controller: _instructorCtrl,
              decoration:
                  const InputDecoration(labelText: 'Instructor (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 18),
            Text('Credit hours: ${_creditHours.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Slider(
              value: _creditHours,
              min: 1,
              max: 6,
              divisions: 5,
              label: _creditHours.toStringAsFixed(0),
              onChanged: (v) => setState(() => _creditHours = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add course'),
            ),
          ],
        ),
      ),
    );
  }
}
