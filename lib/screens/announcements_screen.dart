import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/announcement.dart';
import '../models/employee.dart';
import '../models/department.dart';
import '../widgets/pickers.dart';

/// Body-only. Two tabs: Send, and History (read back from grouped
/// tbltask rows — see ADMIN_API_SETUP.md).
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          tabs: const [Tab(text: 'Send'), Tab(text: 'History')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_SendTab(), _HistoryTab()],
          ),
        ),
      ],
    );
  }
}

class _SendTab extends StatefulWidget {
  const _SendTab();

  @override
  State<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<_SendTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  String _recipientMode = 'all';
  Department? _department;
  final List<Employee> _specificEmployees = [];
  String? _filePath;
  bool _sending = false;
  String? _error;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 2));
    if (picked != null) {
      _dateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      _timeCtrl.text = picked.format(context);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx']);
    if (result != null && result.files.single.path != null) {
      setState(() => _filePath = result.files.single.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipientMode == 'division' && _department == null) {
      setState(() => _error = 'Pick a department.');
      return;
    }
    if (_recipientMode == 'specific' && _specificEmployees.isEmpty) {
      setState(() => _error = 'Pick at least one employee.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final fields = {
        'recipientMode': _recipientMode,
        'title': _titleCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'time': _timeCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'source': _sourceCtrl.text.trim(),
        if (_recipientMode == 'division') 'departmentId': '${_department!.id}',
        if (_recipientMode == 'specific') 'employeeIds': _specificEmployees.map((e) => e.id).join(','),
      };
      final count = await AdminService(session.api).announcementSend(fields, filePath: _filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sent to $count recipient(s).')));
        _titleCtrl.clear();
        _descCtrl.clear();
        _sourceCtrl.clear();
        setState(() {
          _specificEmployees.clear();
          _department = null;
          _filePath = null;
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminService(context.read<Session>().api);
    return Form(
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
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(labelText: 'Date'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _timeCtrl,
                readOnly: true,
                onTap: _pickTime,
                decoration: const InputDecoration(labelText: 'Time'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(controller: _sourceCtrl, decoration: const InputDecoration(labelText: 'Source of Announcement (optional)')),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'division', label: Text('Department')),
              ButtonSegment(value: 'specific', label: Text('Specific')),
            ],
            selected: {_recipientMode},
            onSelectionChanged: (s) => setState(() => _recipientMode = s.first),
          ),
          const SizedBox(height: 10),
          if (_recipientMode == 'division')
            ListTile(
              tileColor: Colors.grey.shade100,
              leading: const Icon(Icons.account_tree_outlined),
              title: Text(_department?.name ?? 'Tap to choose department'),
              onTap: () async {
                final picked = await pickDepartment(context, service);
                if (picked != null) setState(() => _department = picked);
              },
            ),
          if (_recipientMode == 'specific') ...[
            Wrap(
              spacing: 6,
              children: _specificEmployees
                  .map((e) => Chip(
                        label: Text(e.name),
                        onDeleted: () => setState(() => _specificEmployees.remove(e)),
                      ))
                  .toList(),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Employee'),
              onPressed: () async {
                final picked = await pickEmployee(context, service);
                if (picked != null && !_specificEmployees.any((e) => e.id == picked.id)) {
                  setState(() => _specificEmployees.add(picked));
                }
              },
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.attach_file),
            label: Text(_filePath == null ? 'Attach File (optional)' : 'File attached ✓'),
            onPressed: _pickFile,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send Announcement'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<SentAnnouncement> _history = [];
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
      final list = await AdminService(session.api).announcementHistory();
      if (mounted) setState(() => _history = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _history.isEmpty
                  ? const Center(child: Text('No announcements sent yet.'))
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, i) {
                        final a = _history[i];
                        return ExpansionTile(
                          title: Text(a.title),
                          subtitle: Text('${a.date ?? ''} ${a.time ?? ''} · ${a.recipientCount} recipient(s)'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.description),
                                  const SizedBox(height: 8),
                                  Text('Sent to: ${a.recipients ?? ''}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
    );
  }
}
