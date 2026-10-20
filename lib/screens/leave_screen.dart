import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/leave_models.dart';
import '../widgets/pickers.dart';
import 'leave_ledger_screen.dart';

/// Body-only. Three tabs: Leave Types (admin-configurable), Applications
/// (view-only — no approve/reject workflow exists, see ADMIN_API_SETUP.md),
/// and a shortcut into an employee's ledger (credits/deductions).
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          tabs: const [
            Tab(text: 'Leave Types'),
            Tab(text: 'Applications'),
            Tab(text: 'Employee Ledger'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _LeaveTypesTab(),
              _ApplicationsTab(),
              _EmployeeLedgerTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaveTypesTab extends StatefulWidget {
  const _LeaveTypesTab();

  @override
  State<_LeaveTypesTab> createState() => _LeaveTypesTabState();
}

class _LeaveTypesTabState extends State<_LeaveTypesTab> {
  List<LeaveType> _types = [];
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
      final list = await AdminService(session.api).leaveTypesList();
      if (mounted) setState(() => _types = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForm({LeaveType? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final rateCtrl = TextEditingController(text: (existing?.defaultDeductionPerDay ?? 1.0).toString());
    final accrualCtrl = TextEditingController(text: existing?.monthlyAccrual?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Leave Type' : 'Edit Leave Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (existing == null)
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Default Deduction / Day'),
            ),
            TextField(
              controller: accrualCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monthly Auto-Accrual (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    final rate = double.tryParse(rateCtrl.text) ?? 1.0;
    final accrual = accrualCtrl.text.trim().isEmpty ? null : double.tryParse(accrualCtrl.text);
    try {
      final session = context.read<Session>();
      final service = AdminService(session.api);
      if (existing == null) {
        await service.leaveTypeAdd(nameCtrl.text.trim(), rate, accrual);
      } else {
        await service.leaveTypeEdit(existing.id, rate, accrual);
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
                    itemCount: _types.length,
                    itemBuilder: (context, i) {
                      final t = _types[i];
                      return ListTile(
                        title: Text(t.name),
                        subtitle: Text(
                            'Deduct ${t.defaultDeductionPerDay}/day${t.monthlyAccrual != null ? ' · Accrue ${t.monthlyAccrual}/mo' : ''}'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            Chip(
                              label: Text(t.isActive ? 'Active' : 'Inactive', style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: t.isActive ? Colors.green.shade50 : Colors.grey.shade200,
                            ),
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showForm(existing: t)),
                            IconButton(
                              icon: Icon(t.isActive ? Icons.toggle_on : Icons.toggle_off, color: t.isActive ? Colors.green : Colors.grey),
                              onPressed: () async {
                                await AdminService(context.read<Session>().api).leaveTypeToggle(t.id);
                                _load();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _ApplicationsTab extends StatefulWidget {
  const _ApplicationsTab();

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  List<LeaveApplication> _applications = [];
  bool _loading = true;
  String _filter = 'today';
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
      final list = await AdminService(session.api).leaveApplications(dateFilter: _filter);
      if (mounted) setState(() => _applications = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('On Leave Today'),
                selected: _filter == 'today',
                onSelected: (_) {
                  setState(() => _filter = 'today');
                  _load();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('All Filed'),
                selected: _filter == 'all',
                onSelected: (_) {
                  setState(() => _filter = 'all');
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
                    : _applications.isEmpty
                        ? const Center(child: Text('No leave applications to show.'))
                        : ListView.builder(
                            itemCount: _applications.length,
                            itemBuilder: (context, i) {
                              final a = _applications[i];
                              return ListTile(
                                leading: const Icon(Icons.event_busy_outlined),
                                title: Text(a.employeeName ?? 'Employee #${a.employeeId}'),
                                subtitle: Text('${a.leaveType} · ${a.start ?? ''} – ${a.end ?? ''}\n${a.department ?? ''}'),
                                isThreeLine: true,
                                trailing: Chip(label: Text(a.status, style: const TextStyle(fontSize: 11))),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}

class _EmployeeLedgerTab extends StatelessWidget {
  const _EmployeeLedgerTab();

  @override
  Widget build(BuildContext context) {
    final service = AdminService(context.read<Session>().api);
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.search),
        label: const Text('Find Employee Ledger'),
        onPressed: () async {
          final employee = await pickEmployee(context, service, activeOnly: false);
          if (employee != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LeaveLedgerScreen(employeeId: employee.id, employeeName: employee.name),
              ),
            );
          }
        },
      ),
    );
  }
}
