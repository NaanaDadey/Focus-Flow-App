import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? task;
  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _courseCtrl;

  late String _category;
  late String _priority;
  late DateTime _deadline;
  late int _estimatedMinutes;
  bool _useEarlyStart = true;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _courseCtrl = TextEditingController(text: t?.courseCode ?? '');
    _category = t?.category ?? AppConstants.taskCategories.first;
    _priority = t?.priority ?? 'medium';
    _deadline = t?.deadline ?? DateTime.now().add(const Duration(days: 1));
    _estimatedMinutes = t?.estimatedMinutes ?? 60;
    _useEarlyStart = t?.suggestedStart != null || t == null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  /// Nudges the student to start before procrastination sets in: the
  /// earlier of (a) 24h before the deadline, or (b) halfway between now
  /// and the deadline — whichever leaves more buffer, capped at "now".
  DateTime? _computeSuggestedStart() {
    if (!_useEarlyStart) return null;
    final now = DateTime.now();
    if (_deadline.isBefore(now)) return null;
    final halfway = now.add(_deadline.difference(now) ~/ 2);
    final dayBefore = _deadline.subtract(const Duration(hours: 24));
    final suggestion = dayBefore.isAfter(now) && dayBefore.isBefore(halfway)
        ? dayBefore
        : halfway;
    return suggestion.isAfter(now) ? suggestion : null;
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (time == null) return;
    setState(() {
      _deadline =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TaskProvider>();
    final suggestedStart = _computeSuggestedStart();

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _category,
        priority: _priority,
        deadline: _deadline,
        suggestedStart: suggestedStart,
        estimatedMinutes: _estimatedMinutes,
        courseCode:
            _courseCtrl.text.trim().isEmpty ? null : _courseCtrl.text.trim(),
      );
      await provider.updateTask(updated);
    } else {
      await provider.addTask(
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _category,
        priority: _priority,
        deadline: _deadline,
        suggestedStart: suggestedStart,
        estimatedMinutes: _estimatedMinutes,
        courseCode:
            _courseCtrl.text.trim().isEmpty ? null : _courseCtrl.text.trim(),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<TaskProvider>().deleteTask(widget.task!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = _computeSuggestedStart();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'New task'),
        actions: [
          if (_isEditing)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _courseCtrl,
              decoration:
                  const InputDecoration(labelText: 'Course code (optional)'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 18),
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.taskCategories.map((c) {
                return ChoiceChip(
                  label: Text(c[0].toUpperCase() + c.substring(1)),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('Priority',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.taskPriorities.map((p) {
                final color = AppTheme.priorityColor(p);
                final selected = _priority == p;
                return ChoiceChip(
                  label: Text(p[0].toUpperCase() + p.substring(1)),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _priority = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('Deadline',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.event),
              label:
                  Text(DateFormat('EEE, MMM d, y • h:mm a').format(_deadline)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text('Estimated time: $_estimatedMinutes min',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            Slider(
              value: _estimatedMinutes.toDouble(),
              min: 15,
              max: 480,
              divisions: 31,
              label: '$_estimatedMinutes min',
              onChanged: (v) => setState(() => _estimatedMinutes = v.round()),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Suggest an early start time'),
              subtitle: Text(
                suggestion != null
                    ? "We'll nudge you on ${DateFormat('MMM d, h:mm a').format(suggestion)} — before procrastination kicks in."
                    : 'Get reminded to start before the deadline creeps up.',
              ),
              value: _useEarlyStart,
              onChanged: (v) => setState(() => _useEarlyStart = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save changes' : 'Create task'),
            ),
          ],
        ),
      ),
    );
  }
}
