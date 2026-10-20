import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/travel_order.dart';
import 'travel_order_detail_screen.dart';
import 'travel_order_add_screen.dart';

/// Body-only.
class TravelOrdersScreen extends StatefulWidget {
  const TravelOrdersScreen({super.key});

  @override
  State<TravelOrdersScreen> createState() => _TravelOrdersScreenState();
}

class _TravelOrdersScreenState extends State<TravelOrdersScreen> {
  List<TravelOrder> _orders = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

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
      final list = await AdminService(session.api).travelOrderList(search: _searchCtrl.text.trim());
      if (mounted) setState(() => _orders = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Forwarded':
        return Colors.blue;
      case 'Returned':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const TravelOrderAddScreen()),
          );
          if (added == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(hintText: 'Search officer, destination, purpose…', prefixIcon: Icon(Icons.search), isDense: true),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _orders.isEmpty
                          ? const Center(child: Text('No travel orders found.'))
                          : ListView.builder(
                              itemCount: _orders.length,
                              itemBuilder: (context, i) {
                                final o = _orders[i];
                                return ListTile(
                                  title: Text(o.destination),
                                  subtitle: Text('${o.officerNames.split('\n').first}${o.officerNames.contains('\n') ? ' +more' : ''}\n${o.periodFrom ?? ''} – ${o.periodTo ?? o.periodFrom ?? ''}'),
                                  isThreeLine: true,
                                  trailing: Chip(
                                    label: Text(o.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                    backgroundColor: _statusColor(o.status),
                                  ),
                                  onTap: () async {
                                    final changed = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(builder: (_) => TravelOrderDetailScreen(orderId: o.id)),
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
