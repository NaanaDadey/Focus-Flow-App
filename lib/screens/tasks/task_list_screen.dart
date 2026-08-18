import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'All (${provider.tasks.length})'),
            Tab(text: 'Pending (${provider.pending.length})'),
            Tab(text: 'Completed (${provider.completed.length})'),
            Tab(text: 'Overdue (${provider.overdue.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditTaskScreen())),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TaskListView(tasks: provider.tasks, provider: provider),
          _TaskListView(tasks: provider.pending, provider: provider),
          _TaskListView(tasks: provider.completed, provider: provider),
          _TaskListView(tasks: provider.overdue, provider: provider),
        ],
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  final List tasks;
  final TaskProvider provider;
  const _TaskListView({required this.tasks, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt,
        title: 'No tasks here',
        message: 'Tap the + button to add one.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TaskCard(
            task: task,
            onToggle: () => provider.toggleComplete(task),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task))),
            onDelete: () => provider.deleteTask(task),
          ),
        );
      },
    );
  }
}
