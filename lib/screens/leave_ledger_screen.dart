import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/leave_models.dart';

class LeaveLedgerScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  const LeaveLedgerScreen({super.key, required this.employeeId, required this.employeeName});

  @override
  State<LeaveLedgerScreen> createState() => _LeaveLedgerScreenState();
}

class _LeaveLedgerScreenState extends State<LeaveLedgerScreen> {
  List<LeaveLedgerEntry> _entries = [];
  List<LeaveBalance> _balances = [];
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
      final service = AdminService(context.read<Session>().api);
      final (entries, balances) = await service.leaveLedger(widget.employeeId);
      final types = await service.leaveTypesList();
      if (mounted) setState(() {
        _entries = entries;
        _balances = balances;
        _types = types;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreditForm() async {
    String? leaveType = _types.isNotEmpty ? _types.first.name : null;
    String txnType = 'Earned';
    final amountCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    DateTime date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          title: const Text('Add Leave Credit / Deduction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: leaveType,
                  decoration: const InputDecoration(labelText: 'Leave Type'),
                  items: _types.map((t) => DropdownMenuItem(value: t.name, child: Text(t.name))).toList(),
                  onChanged: (v) => setD(() => leaveType = v),
                ),
                DropdownButtonFormField<String>(
                  initialValue: txnType,
                  decoration: const InputDecoration(labelText: 'Transaction Type'),
                  items: const [
                    DropdownMenuItem(value: 'Earned', child: Text('Earned (add)')),
                    DropdownMenuItem(value: 'Deduction', child: Text('Deduction (subtract)')),
                  ],
                  onChanged: (v) => setD(() => txnType = v ?? 'Earned'),
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (days)'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${date.toIso8601String().substring(0, 10)}'),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(DateTime.now().year + 2),
                    );
                    if (picked != null) setD(() => date = picked);
                  },
                ),
                TextField(controller: remarksCtrl, decoration: const InputDecoration(labelText: 'Remarks')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        );
      }),
    );

    if (saved != true || leaveType == null) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0) return;
    try {
      final service = AdminService(context.read<Session>().api);
      await service.leaveCreditAdd(
        employeeId: widget.employeeId,
        leaveType: leaveType!,
        transactionType: txnType,
        amount: amount,
        particularDate: '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        remarks: remarksCtrl.text.trim(),
      );
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showEditForm(LeaveLedgerEntry entry) async {
    final earnedCtrl = TextEditingController(text: entry.earned.toString());
    final deductionCtrl = TextEditingController(text: entry.deduction.toString());
    final remarksCtrl = TextEditingController(text: entry.remarks);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Correct Entry (${entry.leaveType})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: earnedCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Earned'),
            ),
            TextField(
              controller: deductionCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Deduction'),
            ),
            TextField(controller: remarksCtrl, decoration: const InputDecoration(labelText: 'Remarks')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    try {
      final service = AdminService(context.read<Session>().api);
      await service.leaveLedgerEdit(
        ledgerId: entry.id,
        employeeId: widget.employeeId,
        earned: double.tryParse(earnedCtrl.text) ?? entry.earned,
        deduction: double.tryParse(deductionCtrl.text) ?? entry.deduction,
        remarks: remarksCtrl.text.trim(),
      );
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.employeeName} — Leave Ledger')),
      floatingActionButton: FloatingActionButton(onPressed: _showCreditForm, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_balances.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: _balances.map((b) {
                                return Chip(label: Text('${b.leaveType}: ${b.balance.toStringAsFixed(2)}d'));
                              }).toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ..._entries.map((e) {
                        return Card(
                          child: ListTile(
                            title: Text('${e.leaveType} · ${e.particularDate ?? ''}'),
                            subtitle: Text(
                                'Earned ${e.earned} / Deduction ${e.deduction} → Balance ${e.balance.toStringAsFixed(2)}${e.remarks.isNotEmpty ? '\n${e.remarks}' : ''}'),
                            isThreeLine: e.remarks.isNotEmpty,
                            trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showEditForm(e)),
                          ),
                        );
                      }),
                      if (_entries.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No ledger entries yet.'))),
                    ],
                  ),
                ),
    );
  }
}
