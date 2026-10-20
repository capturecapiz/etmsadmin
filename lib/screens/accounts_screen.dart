import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/registration.dart';

/// Body-only. Managing OTHER admin accounts (this app's own admin/account
/// management requirement) — see profile_screen.dart for "my own" profile
/// and password.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<AdminAccount> _admins = [];
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
      final list = await AdminService(session.api).adminsList();
      if (mounted) setState(() => _admins = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddForm() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Admin Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Admin Name')),
              TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password (min 6 chars)'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (saved != true) return;
    try {
      final session = context.read<Session>();
      await AdminService(session.api).adminAdd(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        username: usernameCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggle(AdminAccount a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${a.isActive ? 'Deactivate' : 'Reactivate'} "${a.username}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final session = context.read<Session>();
      await AdminService(session.api).adminToggle(a.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _resetPassword(AdminAccount a) async {
    final ctrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reset password for "${a.username}"'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'New password (min 6 chars)'), obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (saved != true || ctrl.text.length < 6) return;
    try {
      final session = context.read<Session>();
      await AdminService(session.api).adminResetPassword(a.id, ctrl.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(onPressed: _showAddForm, child: const Icon(Icons.add)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView.builder(
                    itemCount: _admins.length,
                    itemBuilder: (context, i) {
                      final a = _admins[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: a.isActive ? const Color(0xFFE8EEFC) : Colors.grey.shade200,
                          child: Icon(Icons.person, color: a.isActive ? const Color(0xFF3B82F6) : Colors.grey),
                        ),
                        title: Text(a.name.isEmpty ? a.username : a.name),
                        subtitle: Text('${a.username} · ${a.email}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'toggle') _toggle(a);
                            if (v == 'reset') _resetPassword(a);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'toggle', child: Text(a.isActive ? 'Deactivate' : 'Reactivate')),
                            const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
