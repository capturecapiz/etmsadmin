import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/employee.dart';
import 'employee_edit_screen.dart';
import 'leave_ledger_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  Employee? _employee;
  bool _loading = true;
  String? _error;
  bool _changed = false;

  static const _statusOptions = ['Active', 'Resigned', 'AWOL', 'Terminated', 'Inactive'];

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
      final e = await AdminService(session.api).employeeDetail(widget.employeeId);
      if (mounted) setState(() => _employee = e);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Set status to "$newStatus"?'),
        content: newStatus != 'Active'
            ? const Text('This will also cancel this employee\'s open tasks.')
            : null,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final session = context.read<Session>();
      final cancelled = await AdminService(session.api).employeeSetStatus(widget.employeeId, newStatus);
      _changed = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cancelled > 0 ? 'Status updated — $cancelled task(s) cancelled.' : 'Status updated.')),
        );
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_employee?.name ?? 'Employee'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          actions: [
            if (_employee != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final edited = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => EmployeeEditScreen(employee: _employee)),
                  );
                  if (edited == true) {
                    _changed = true;
                    _load();
                  }
                },
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _buildBody(context, _employee!),
    );
  }

  Widget _buildBody(BuildContext context, Employee e) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFE8EEFC),
            backgroundImage: e.photoUrl != null ? CachedNetworkImageProvider(e.photoUrl!) : null,
            child: e.photoUrl == null
                ? Text(e.name.isNotEmpty ? e.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32))
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        Center(child: Text(e.designation, style: TextStyle(color: Colors.grey[600]))),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _row('Employee ID', e.empId),
              _row('Department', e.department),
              _row('Email', e.email),
              _row('Contact Number', e.contactNumber),
              _row('Date of Birth', e.dateOfBirth),
              _row('Date of Joining', e.dateOfJoining),
              _row('Address', e.address),
              if (e.classification.isNotEmpty) _row('Classification', e.classification),
              _row('Registration Status', e.registrationStatus),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.event_available_outlined),
          title: const Text('View Leave Ledger'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LeaveLedgerScreen(employeeId: e.id, employeeName: e.name)),
          ),
        ),
        const SizedBox(height: 16),
        Text('Employment Status: ${e.employmentStatus}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _statusOptions.where((s) => s != e.employmentStatus).map((s) {
            return OutlinedButton(onPressed: () => _setStatus(s), child: Text('Set $s'));
          }).toList(),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}
