import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';

/// Known v1 simplification (see ADMIN_API_SETUP.md): the optional
/// "PGDH is absent — delegate signing" feature is not exposed here; that
/// specific case is created from the web admin panel instead.
class TravelOrderAddScreen extends StatefulWidget {
  const TravelOrderAddScreen({super.key});

  @override
  State<TravelOrderAddScreen> createState() => _TravelOrderAddScreenState();
}

class _TravelOrderAddScreenState extends State<TravelOrderAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officerNamesCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _recommendingNameCtrl = TextEditingController();
  final _recommendingDesignationCtrl = TextEditingController();
  final _approvingNameCtrl = TextEditingController();
  final _approvingDesignationCtrl = TextEditingController();
  bool _natureTime = false;
  bool _natureBusiness = false;
  bool _saving = false;
  String? _error;

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 2));
    if (picked != null) {
      ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      await AdminService(session.api).travelOrderAdd({
        'officerNames': _officerNamesCtrl.text.trim(),
        'destination': _destinationCtrl.text.trim(),
        'periodFrom': _fromCtrl.text.trim(),
        'periodTo': _toCtrl.text.trim(),
        'purpose': _purposeCtrl.text.trim(),
        'natureOfficialTime': _natureTime ? '1' : '',
        'natureOfficialBusiness': _natureBusiness ? '1' : '',
        'recommendingName': _recommendingNameCtrl.text.trim(),
        'recommendingDesignation': _recommendingDesignationCtrl.text.trim(),
        'approvingName': _approvingNameCtrl.text.trim(),
        'approvingDesignation': _approvingDesignationCtrl.text.trim(),
      });
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
      appBar: AppBar(title: const Text('Add Travel Order')),
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
              controller: _officerNamesCtrl,
              decoration: const InputDecoration(
                labelText: 'Officer Names',
                helperText: 'One name per line, e.g.\nRENZ DARIELLE MACEDA\nREY VINCENT YAP - Driver',
              ),
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _destinationCtrl,
              decoration: const InputDecoration(labelText: 'Destination'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _fromCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(_fromCtrl),
                  decoration: const InputDecoration(labelText: 'Period From'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _toCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(_toCtrl),
                  decoration: const InputDecoration(labelText: 'Period To (optional)'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextFormField(
              controller: _purposeCtrl,
              decoration: const InputDecoration(labelText: 'Purpose of Travel'),
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _natureTime,
              onChanged: (v) => setState(() => _natureTime = v ?? false),
              title: const Text('Official Time'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _natureBusiness,
              onChanged: (v) => setState(() => _natureBusiness = v ?? false),
              title: const Text('Official Business'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 20),
            TextFormField(controller: _recommendingNameCtrl, decoration: const InputDecoration(labelText: 'Recommending Approval — Name')),
            const SizedBox(height: 10),
            TextFormField(controller: _recommendingDesignationCtrl, decoration: const InputDecoration(labelText: 'Recommending Approval — Designation')),
            const SizedBox(height: 10),
            TextFormField(controller: _approvingNameCtrl, decoration: const InputDecoration(labelText: 'Approving Authority — Name')),
            const SizedBox(height: 10),
            TextFormField(controller: _approvingDesignationCtrl, decoration: const InputDecoration(labelText: 'Approving Authority — Designation')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Travel Order'),
            ),
          ],
        ),
      ),
    );
  }
}
