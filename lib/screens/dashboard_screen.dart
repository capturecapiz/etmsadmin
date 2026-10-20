import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import 'tasks_screen.dart';
import 'registrations_screen.dart';

/// Body-only (no own Scaffold/AppBar — HomeShell supplies the shared one).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  String? _error;
  bool _loading = true;

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
      final data = await AdminService(session.api).dashboard();
      if (mounted) setState(() => _data = data);
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
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Center(child: Text(_error!, textAlign: TextAlign.center)),
                    const SizedBox(height: 12),
                    Center(child: OutlinedButton(onPressed: _load, child: const Text('Retry'))),
                  ],
                )
              : _buildBody(context, _data!),
    );
  }

  Widget _buildBody(BuildContext context, DashboardData data) {
    final counts = data.counts;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (data.pendingRegistrations > 0)
          Card(
            color: Colors.amber.shade50,
            child: ListTile(
              leading: const Icon(Icons.person_add_alt, color: Colors.amber),
              title: Text('${data.pendingRegistrations} pending employee registration(s)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Registrations')),
                    body: const RegistrationsScreen(),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text('Tasks', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _kpiCard(context, 'Not Started', counts['notStarted'] ?? 0, Colors.blueGrey, 'notStarted'),
            _kpiCard(context, 'In Progress', counts['inProgress'] ?? 0, const Color(0xFF3B82F6), 'inProgress'),
            _kpiCard(context, 'Past Due', counts['pastDue'] ?? 0, Colors.redAccent, 'pastDue'),
            _kpiCard(context, 'Completed', counts['completed'] ?? 0, Colors.green, 'completed'),
            _kpiCard(context, 'Cancelled', counts['cancelled'] ?? 0, Colors.grey, 'cancelled'),
          ],
        ),
        if (data.onLeaveToday.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('On Leave Today', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: data.onLeaveToday.map((e) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_busy, color: Colors.orange),
                  title: Text('${e['name'] ?? ''}'),
                  subtitle: Text('${e['designation'] ?? ''} · ${e['division'] ?? ''} · ${e['leaveType'] ?? ''}'),
                );
              }).toList(),
            ),
          ),
        ],
        if (data.onTravelToday.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('On Travel Today', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: data.onTravelToday.map((e) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.card_travel, color: Colors.teal),
                  title: Text('${e['name'] ?? ''}'),
                  subtitle: Text('${e['destination'] ?? ''} · ${e['purpose'] ?? ''}'),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _kpiCard(BuildContext context, String label, int value, Color color, String bucket) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('Tasks — $label')),
            body: TasksScreen(initialBucket: bucket),
          ),
        ),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
