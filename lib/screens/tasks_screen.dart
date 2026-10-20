import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/task_item.dart';
import 'task_detail_screen.dart';
import 'task_add_screen.dart';

/// Body-only. [initialBucket] lets a dashboard KPI card deep-link straight
/// into a filtered view.
class TasksScreen extends StatefulWidget {
  final String initialBucket;
  const TasksScreen({super.key, this.initialBucket = 'all'});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late String _bucket = widget.initialBucket;
  List<TaskItem> _tasks = [];
  bool _loading = true;
  String? _error;

  static const _buckets = {
    'all': 'All',
    'notStarted': 'Not Started',
    'inProgress': 'In Progress',
    'pastDue': 'Past Due',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final list = await AdminService(session.api).taskList(bucket: _bucket);
      if (mounted) setState(() => _tasks = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const TaskAddScreen()),
          );
          if (added == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _buckets.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: _bucket == e.key,
                    onSelected: (_) {
                      setState(() => _bucket = e.key);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _tasks.isEmpty
                          ? const Center(child: Text('No tasks in this view.'))
                          : ListView.builder(
                              itemCount: _tasks.length,
                              itemBuilder: (context, i) {
                                final t = _tasks[i];
                                return ListTile(
                                  title: Text(t.title),
                                  subtitle: Text('${t.employeeName ?? ''} · ${t.departmentName ?? ''} · Due ${t.dueDate ?? '—'}'),
                                  trailing: Chip(
                                    label: Text(t.bucketLabel, style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t.id)),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
