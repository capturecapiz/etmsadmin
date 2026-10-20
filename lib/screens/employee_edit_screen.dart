import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/employee.dart';
import '../models/department.dart';

/// Shared Add/Edit form — pass [employee] to edit, or omit to add new.
class EmployeeEditScreen extends StatefulWidget {
  final Employee? employee;
  const EmployeeEditScreen({super.key, this.employee});

  @override
  State<EmployeeEditScreen> createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends State<EmployeeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _empIdCtrl = TextEditingController(text: widget.employee?.empId ?? '');
  late final _nameCtrl = TextEditingController(text: widget.employee?.name ?? '');
  late final _emailCtrl = TextEditingController(text: widget.employee?.email ?? '');
  late final _contactCtrl = TextEditingController(text: widget.employee?.contactNumber ?? '');
  late final _telegramCtrl = TextEditingController();
  late final _designationCtrl = TextEditingController(text: widget.employee?.designation ?? '');
  late final _dobCtrl = TextEditingController(text: widget.employee?.dateOfBirth ?? '');
  late final _addressCtrl = TextEditingController(text: widget.employee?.address ?? '');
  late final _dojCtrl = TextEditingController(text: widget.employee?.dateOfJoining ?? '');
  late final _descCtrl = TextEditingController(text: widget.employee?.description ?? '');
  final _passwordCtrl = TextEditingController();

  int? _deptId;
  String? _classification;
  List<Department> _departments = [];
  bool _loadingDepts = true;
  bool _saving = false;
  String? _error;
  String? _photoPath;

  bool get _isEdit => widget.employee != null;

  static const _classifications = ['Permanent Employee', 'Contractual Employee', 'Job Order Employee'];

  @override
  void initState() {
    super.initState();
    _deptId = widget.employee?.departmentId;
    _classification = widget.employee?.classification.isNotEmpty == true ? widget.employee!.classification : null;
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final session = context.read<Session>();
      final depts = await AdminService(session.api).departmentList();
      if (mounted) setState(() => _departments = depts);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDepts = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final fields = {
      'deptId': _deptId?.toString() ?? '',
      'empId': _empIdCtrl.text.trim(),
      'empName': _nameCtrl.text.trim(),
      'empEmail': _emailCtrl.text.trim(),
      'telegramChatId': _telegramCtrl.text.trim(),
      'empContactNumber': _contactCtrl.text.trim(),
      'designation': _designationCtrl.text.trim(),
      'dateOfBirth': _dobCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'dateOfJoining': _dojCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'classification': _classification ?? '',
    };
    try {
      final session = context.read<Session>();
      final service = AdminService(session.api);
      if (_isEdit) {
        await service.employeeEdit(widget.employee!.id, fields, photoPath: _photoPath);
      } else {
        fields['password'] = _passwordCtrl.text;
        await service.employeeAdd(fields, photoPath: _photoPath);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Employee' : 'Add Employee')),
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
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFFE8EEFC),
                  backgroundImage: _photoPath != null
                      ? FileImage(File(_photoPath!))
                      : (widget.employee?.photoUrl != null ? NetworkImage(widget.employee!.photoUrl!) : null)
                          as ImageProvider?,
                  child: _photoPath == null && widget.employee?.photoUrl == null
                      ? const Icon(Icons.camera_alt_outlined, size: 28)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _empIdCtrl,
              decoration: const InputDecoration(labelText: 'Employee ID'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            _loadingDepts
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int>(
                    initialValue: _deptId,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: _departments
                        .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _deptId = v),
                  ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _designationCtrl,
              decoration: const InputDecoration(labelText: 'Designation'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _classification,
              decoration: const InputDecoration(labelText: 'Classification'),
              items: _classifications.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _classification = v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contactCtrl,
              decoration: const InputDecoration(labelText: 'Contact Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _telegramCtrl,
              decoration: const InputDecoration(labelText: 'Telegram Chat ID (optional)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _dobCtrl,
              decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _dojCtrl,
              decoration: const InputDecoration(labelText: 'Date of Joining (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description / Notes'),
              maxLines: 2,
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Initial Password (for portal/app login)'),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Save Changes' : 'Add Employee'),
            ),
          ],
        ),
      ),
    );
  }
}
