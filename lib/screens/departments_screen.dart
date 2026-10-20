import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/department.dart';

/// Body-only. Division Head assignment (HeadEmployeeID) is shown
/// read-only here — assigning/changing it is a separate web-only feature
/// (division-head.php) not in this app's Phase 1 scope.
class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  List<Department> _departments = [];
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
      final list = await AdminService(session.api).departmentList();
      if (mounted) setState(() => _departments = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForm({Department? existing}) async {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Department' : 'Edit Department'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Department Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || ctrl.text.trim().isEmpty) return;
    try {
      final session = context.read<Session>();
      final service = AdminService(session.api);
      if (existing == null) {
        await service.departmentAdd(ctrl.text.trim());
      } else {
        await service.departmentEdit(existing.id, ctrl.text.trim());
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView.builder(
                    itemCount: _departments.length,
                    itemBuilder: (context, i) {
                      final d = _departments[i];
                      return ListTile(
                        leading: const Icon(Icons.account_tree_outlined),
                        title: Text(d.name),
                        subtitle: d.divisionHead != null ? Text('Division Head: ${d.divisionHead}') : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showForm(existing: d),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
