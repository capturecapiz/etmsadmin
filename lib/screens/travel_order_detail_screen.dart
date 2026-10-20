import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/travel_order.dart';

class TravelOrderDetailScreen extends StatefulWidget {
  final int orderId;
  const TravelOrderDetailScreen({super.key, required this.orderId});

  @override
  State<TravelOrderDetailScreen> createState() => _TravelOrderDetailScreenState();
}

class _TravelOrderDetailScreenState extends State<TravelOrderDetailScreen> {
  TravelOrder? _order;
  bool _loading = true;
  String? _error;
  bool _changed = false;

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
      final o = await AdminService(session.api).travelOrderDetail(widget.orderId);
      if (mounted) setState(() => _order = o);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advance(String to) async {
    try {
      final session = context.read<Session>();
      await AdminService(session.api).travelOrderAdvance(widget.orderId, to);
      _changed = true;
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_changed),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(context, _order!),
    );
  }

  Widget _buildBody(BuildContext context, TravelOrder o) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text('${o.periodFrom ?? ''} – ${o.periodTo ?? o.periodFrom ?? ''}', style: TextStyle(color: Colors.grey[600])),
                const Divider(height: 24),
                Text('Officers', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(o.officerNames),
                const SizedBox(height: 12),
                Text('Purpose', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(o.purpose),
                const SizedBox(height: 12),
                if (o.natureOfficialTime) const Chip(label: Text('Official Time')),
                if (o.natureOfficialBusiness) const Chip(label: Text('Official Business')),
                const Divider(height: 24),
                _row('Recommending', '${o.recommendingName} (${o.recommendingDesignation})'),
                _row('Approving', '${o.approvingName} (${o.approvingDesignation})'),
                _row('Status', o.status),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No in-app Approve/Disapprove — the Governor\'s office signs the printed copy by hand. '
          'This just tracks the paper\'s own trip through the office.',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (o.status == 'Pending')
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Mark as Forwarded'),
            onPressed: () => _advance('Forwarded'),
          ),
        if (o.status == 'Forwarded')
          ElevatedButton.icon(
            icon: const Icon(Icons.assignment_return),
            label: const Text('Mark as Returned'),
            onPressed: () => _advance('Returned'),
          ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
