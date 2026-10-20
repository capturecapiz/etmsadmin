import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';

/// Body-only.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

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
      final p = await AdminService(session.api).profileGet();
      if (mounted) {
        setState(() {
          _profile = p;
          _nameCtrl.text = p['name'] ?? '';
          _mobileCtrl.text = p['mobileNumber'] ?? '';
          _emailCtrl.text = p['email'] ?? '';
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final session = context.read<Session>();
      await AdminService(session.api).profileEdit(
        name: _nameCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showChangePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentCtrl, decoration: const InputDecoration(labelText: 'Current Password'), obscureText: true),
            TextField(controller: newCtrl, decoration: const InputDecoration(labelText: 'New Password (min 6 chars)'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );
    if (saved != true) return;
    try {
      final session = context.read<Session>();
      await AdminService(session.api).changePassword(currentCtrl.text, newCtrl.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Admin Name')),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Username'),
                    enabled: false,
                    controller: TextEditingController(text: _profile?['username'] ?? ''),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _mobileCtrl, decoration: const InputDecoration(labelText: 'Contact Number')),
                  const SizedBox(height: 10),
                  TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Profile'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: _showChangePassword, child: const Text('Change Password')),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                    onPressed: () => context.read<Session>().logout(),
                  ),
                ],
              );
  }
}
