import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/employee.dart';
import '../models/department.dart';
import '../widgets/pickers.dart';

class TaskAddScreen extends StatefulWidget {
  const TaskAddScreen({super.key});

  @override
  State<TaskAddScreen> createState() => _TaskAddScreenState();
}

class _TaskAddScreenState extends State<TaskAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();
  String _priority = 'Medium';
  String _assignMode = 'employee'; // 'employee' or 'department' (broadcast)
  Employee? _employee;
  Department? _department;
  bool _saving = false;
  String? _error;

  static const _priorities = ['Low', 'Medium', 'High', 'Normal', 'Urgent'];

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      _dueDateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assignMode == 'employee' && _employee == null) {
      setState(() => _error = 'Pick an employee to assign to.');
      return;
    }
    if (_assignMode == 'department' && _department == null) {
      setState(() => _error = 'Pick a department to broadcast to.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final created = await AdminService(session.api).taskAdd(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priority: _priority,
        dueDate: _dueDateCtrl.text.trim(),
        employeeId: _assignMode == 'employee' ? _employee!.id : null,
        departmentId: _assignMode == 'department' ? _department!.id : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task created for $created employee(s).')),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminService(context.read<Session>().api);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Task Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _dueDateCtrl,
              readOnly: true,
              onTap: _pickDueDate,
              decoration: const InputDecoration(labelText: 'Due Date', suffixIcon: Icon(Icons.calendar_today)),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'employee', label: Text('One Employee'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'department', label: Text('Whole Department'), icon: Icon(Icons.groups)),
              ],
              selected: {_assignMode},
              onSelectionChanged: (s) => setState(() => _assignMode = s.first),
            ),
            const SizedBox(height: 10),
            if (_assignMode == 'employee')
              ListTile(
                tileColor: Colors.grey.shade100,
                leading: const Icon(Icons.person_outline),
                title: Text(_employee?.name ?? 'Tap to choose employee'),
                onTap: () async {
                  final picked = await pickEmployee(context, service);
                  if (picked != null) setState(() => _employee = picked);
                },
              )
            else
              ListTile(
                tileColor: Colors.grey.shade100,
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(_department?.name ?? 'Tap to choose department'),
                subtitle: const Text('Creates one copy of this task for every active employee in the department.'),
                onTap: () async {
                  final picked = await pickDepartment(context, service);
                  if (picked != null) setState(() => _department = picked);
                },
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}
