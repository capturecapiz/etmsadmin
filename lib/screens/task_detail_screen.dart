import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/task_item.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  TaskItem? _task;
  List<TaskTracking> _tracking = [];
  bool _loading = true;
  String? _error;

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
      final (task, tracking) = await AdminService(session.api).taskDetail(widget.taskId);
      if (mounted) setState(() {
        _task = task;
        _tracking = tracking;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_task?.title ?? 'Task')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(context, _task!),
    );
  }

  Widget _buildBody(BuildContext context, TaskItem t) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(t.description),
                const Divider(height: 24),
                _row('Assigned To', t.employeeName ?? '—'),
                _row('Department', t.departmentName ?? '—'),
                _row('Priority', t.priority),
                _row('Status', t.bucketLabel),
                _row('Work Completed', '${t.workCompleted}%'),
                _row('Assigned Date', t.assignedDate ?? '—'),
                _row('Due Date', t.dueDate ?? '—'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Progress Updates', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_tracking.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No updates from the employee yet.'),
          )
        else
          Card(
            child: Column(
              children: _tracking.map((e) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.update),
                  title: Text(e.remark.isEmpty ? '(no remark)' : e.remark),
                  subtitle: Text('${e.status ?? ''} ${e.workCompleted != null ? '· ${e.workCompleted}%' : ''} · ${e.date ?? ''}'),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Admin views progress here read-only — the employee updates status/work-completed/remarks from the staff app.',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
