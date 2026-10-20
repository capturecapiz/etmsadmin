import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';
import 'dashboard_screen.dart';
import 'employees_screen.dart';
import 'departments_screen.dart';
import 'tasks_screen.dart';
import 'leave_screen.dart';
import 'travel_orders_screen.dart';
import 'announcements_screen.dart';
import 'accounts_screen.dart';
import 'registrations_screen.dart';
import 'profile_screen.dart';

/// Drawer-based shell: full admin parity has far more sections than fit a
/// 5-item bottom bar, so this uses a NavigationDrawer the same way the web
/// admin panel uses its sidebar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const _NavItem(this.label, this.icon, this.screen);
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static final _items = <_NavItem>[
    const _NavItem('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
    const _NavItem('Employees', Icons.people_outline, EmployeesScreen()),
    const _NavItem('Departments', Icons.account_tree_outlined, DepartmentsScreen()),
    const _NavItem('Tasks', Icons.checklist_outlined, TasksScreen()),
    const _NavItem('Leave', Icons.event_available_outlined, LeaveScreen()),
    const _NavItem('Travel Orders', Icons.card_travel_outlined, TravelOrdersScreen()),
    const _NavItem('Announcements', Icons.campaign_outlined, AnnouncementsScreen()),
    const _NavItem('Registrations', Icons.person_add_alt_outlined, RegistrationsScreen()),
    const _NavItem('Admin Accounts', Icons.manage_accounts_outlined, AccountsScreen()),
    const _NavItem('My Profile', Icons.person_outline, ProfileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<Session>().admin;
    return Scaffold(
      appBar: AppBar(title: Text(_items[_index].label)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF3B82F6)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(height: 8),
                  Text(admin?.name ?? 'Admin',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(admin?.username ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            for (var i = 0; i < _items.length; i++)
              ListTile(
                leading: Icon(_items[i].icon),
                title: Text(_items[i].label),
                selected: _index == i,
                onTap: () {
                  setState(() => _index = i);
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<Session>().logout();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: _items.map((e) => e.screen).toList(),
      ),
    );
  }
}
