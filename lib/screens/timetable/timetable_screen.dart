import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/timetable_provider.dart';
import '../../widgets/empty_state.dart';
import 'add_timetable_entry_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final todayIndex = DateTime.now().weekday - 1; // 0=Mon
    _tabController =
        TabController(length: 7, vsync: this, initialIndex: todayIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timetable = context.watch<TimetableProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: AppConstants.weekdayShort.map((d) => Tab(text: d)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddTimetableEntryScreen(
                initialDay: _tabController.index + 1))),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(7, (i) {
          final dayEntries = timetable.forDay(i + 1);
          if (dayEntries.isEmpty) {
            return const EmptyState(
              icon: Icons.free_breakfast_outlined,
              title: 'No classes',
              message: 'Nothing scheduled for this day.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: dayEntries.length,
            itemBuilder: (context, idx) {
              final e = dayEntries[idx];
              final color = Color(
                  int.parse(e.colorHex.replaceFirst('#', '0xFF')));
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddTimetableEntryScreen(entry: e))),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 44,
                            decoration: BoxDecoration(
                                color: color, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${e.courseCode} — ${e.courseName}',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  '${e.startTime} - ${e.endTime}'
                                  '${e.location != null ? ' • ${e.location}' : ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
