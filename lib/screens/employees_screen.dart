import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/employee.dart';
import 'employee_detail_screen.dart';
import 'employee_edit_screen.dart';

/// Body-only (no own Scaffold — HomeShell supplies the shared one).
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Employee> _employees = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  bool _activeOnly = false;

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
      final list = await AdminService(session.api)
          .employeeList(search: _searchCtrl.text.trim(), activeOnly: _activeOnly);
      if (mounted) setState(() => _employees = list);
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
            MaterialPageRoute(builder: (_) => const EmployeeEditScreen()),
          );
          if (added == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search name, ID, email, contact…',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      ),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Active only'),
                  selected: _activeOnly,
                  onSelected: (v) {
                    setState(() => _activeOnly = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _employees.isEmpty
                          ? const Center(child: Text('No employees found.'))
                          : ListView.builder(
                              itemCount: _employees.length,
                              itemBuilder: (context, i) {
                                final e = _employees[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFE8EEFC),
                                    backgroundImage:
                                        e.photoUrl != null ? CachedNetworkImageProvider(e.photoUrl!) : null,
                                    child: e.photoUrl == null
                                        ? Text(e.name.isNotEmpty ? e.name[0].toUpperCase() : '?')
                                        : null,
                                  ),
                                  title: Text(e.name),
                                  subtitle: Text('${e.designation} · ${e.department}'),
                                  trailing: e.employmentStatus != 'Active'
                                      ? Chip(
                                          label: Text(e.employmentStatus, style: const TextStyle(fontSize: 11)),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: Colors.red.shade50,
                                        )
                                      : null,
                                  onTap: () async {
                                    final changed = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(builder: (_) => EmployeeDetailScreen(employeeId: e.id)),
                                    );
                                    if (changed == true) _load();
                                  },
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
