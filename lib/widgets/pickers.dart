import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/employee.dart';
import '../models/department.dart';

/// Simple searchable bottom-sheet pickers reused across the Task,
/// Announcement, and Leave screens instead of building one ad hoc
/// employee/department dropdown per screen.
Future<Employee?> pickEmployee(BuildContext context, AdminService service, {bool activeOnly = true}) {
  return showModalBottomSheet<Employee>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _EmployeePickerSheet(service: service, activeOnly: activeOnly),
  );
}

Future<Department?> pickDepartment(BuildContext context, AdminService service) async {
  final departments = await service.departmentList();
  if (!context.mounted) return null;
  return showModalBottomSheet<Department>(
    context: context,
    builder: (ctx) => ListView(
      shrinkWrap: true,
      children: departments
          .map((d) => ListTile(title: Text(d.name), onTap: () => Navigator.pop(ctx, d)))
          .toList(),
    ),
  );
}

class _EmployeePickerSheet extends StatefulWidget {
  final AdminService service;
  final bool activeOnly;
  const _EmployeePickerSheet({required this.service, required this.activeOnly});

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  List<Employee> _results = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final list = await widget.service
          .employeeList(search: _searchCtrl.text.trim(), activeOnly: widget.activeOnly);
      if (mounted) setState(() => _results = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Search employee', prefixIcon: Icon(Icons.search)),
              onSubmitted: (_) => _search(),
              onChanged: (_) => _search(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final e = _results[i];
                      return ListTile(
                        title: Text(e.name),
                        subtitle: Text('${e.designation} · ${e.department}'),
                        onTap: () => Navigator.pop(context, e),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
