import '../models/employee.dart';
import '../models/department.dart';
import '../models/task_item.dart';
import '../models/leave_models.dart';
import '../models/travel_order.dart';
import '../models/announcement.dart';
import '../models/registration.dart';
import 'api_client.dart';

/// One method per action on each admin/api/*.php endpoint. Grouped in a
/// single class, mirroring the "consolidated action-param" style of the
/// PHP side itself (employees.php/departments.php/etc. each take an
/// `action` field rather than being one-file-per-operation, since this
/// app's scope is much larger than edmate's).
class AdminService {
  final ApiClient api;
  AdminService(this.api);

  // ---------------- Dashboard ----------------

  Future<DashboardData> dashboard() async {
    final resp = await api.post('dashboard.php', {});
    return DashboardData.fromJson(resp);
  }

  // ---------------- Employees ----------------

  Future<List<Employee>> employeeList({String? search, bool activeOnly = false}) async {
    final resp = await api.post('employees.php', {
      'action': 'list',
      if (search != null && search.isNotEmpty) 'q': search,
      if (activeOnly) 'activeOnly': '1',
    });
    return ((resp['employees'] as List?) ?? [])
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Employee> employeeDetail(int id) async {
    final resp = await api.post('employees.php', {'action': 'detail', 'id': '$id'});
    return Employee.fromJson(resp['employee'] as Map<String, dynamic>);
  }

  Future<void> employeeAdd(Map<String, String> fields, {String? photoPath}) async {
    await api.postMultipart('employees.php', {'action': 'add', ...fields},
        filePath: photoPath, fileField: 'pic');
  }

  Future<void> employeeEdit(int id, Map<String, String> fields, {String? photoPath}) async {
    await api.postMultipart('employees.php', {'action': 'edit', 'id': '$id', ...fields},
        filePath: photoPath, fileField: 'pic');
  }

  Future<int> employeeSetStatus(int id, String status) async {
    final resp = await api.post('employees.php', {
      'action': 'set_status',
      'id': '$id',
      'status': status,
    });
    return resp['cancelledTasks'] as int? ?? 0;
  }

  // ---------------- Departments ----------------

  Future<List<Department>> departmentList() async {
    final resp = await api.post('departments.php', {'action': 'list'});
    return ((resp['departments'] as List?) ?? [])
        .map((e) => Department.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> departmentAdd(String name) async {
    await api.post('departments.php', {'action': 'add', 'name': name});
  }

  Future<void> departmentEdit(int id, String name) async {
    await api.post('departments.php', {'action': 'edit', 'id': '$id', 'name': name});
  }

  // ---------------- Tasks ----------------

  Future<List<TaskItem>> taskList({String bucket = 'all', int? employeeId}) async {
    final resp = await api.post('tasks.php', {
      'action': 'list',
      'bucket': bucket,
      if (employeeId != null) 'employeeId': '$employeeId',
    });
    return ((resp['tasks'] as List?) ?? [])
        .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<(TaskItem, List<TaskTracking>)> taskDetail(int id) async {
    final resp = await api.post('tasks.php', {'action': 'detail', 'id': '$id'});
    final task = TaskItem.fromJson(resp['task'] as Map<String, dynamic>);
    final tracking = ((resp['tracking'] as List?) ?? [])
        .map((e) => TaskTracking.fromJson(e as Map<String, dynamic>))
        .toList();
    return (task, tracking);
  }

  Future<int> taskAdd({
    required String title,
    required String description,
    required String priority,
    required String dueDate,
    int? employeeId,
    int? departmentId,
  }) async {
    final resp = await api.post('tasks.php', {
      'action': 'add',
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate,
      if (employeeId != null) 'employeeId': '$employeeId',
      if (departmentId != null) 'departmentId': '$departmentId',
    });
    return resp['created'] as int? ?? 0;
  }

  Future<void> taskEdit({
    required int id,
    required String title,
    required String description,
    required String priority,
    required String dueDate,
    required int employeeId,
    required int departmentId,
  }) async {
    await api.post('tasks.php', {
      'action': 'edit',
      'id': '$id',
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate,
      'employeeId': '$employeeId',
      'departmentId': '$departmentId',
    });
  }

  // ---------------- Leave ----------------

  Future<List<LeaveType>> leaveTypesList() async {
    final resp = await api.post('leave.php', {'action': 'types_list'});
    return ((resp['leaveTypes'] as List?) ?? [])
        .map((e) => LeaveType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> leaveTypeAdd(String name, double deductionPerDay, double? monthlyAccrual) async {
    await api.post('leave.php', {
      'action': 'type_add',
      'name': name,
      'deductionPerDay': '$deductionPerDay',
      'monthlyAccrual': monthlyAccrual?.toString() ?? '',
    });
  }

  Future<void> leaveTypeEdit(int id, double deductionPerDay, double? monthlyAccrual) async {
    await api.post('leave.php', {
      'action': 'type_edit',
      'id': '$id',
      'deductionPerDay': '$deductionPerDay',
      'monthlyAccrual': monthlyAccrual?.toString() ?? '',
    });
  }

  Future<void> leaveTypeToggle(int id) async {
    await api.post('leave.php', {'action': 'type_toggle', 'id': '$id'});
  }

  Future<(List<LeaveLedgerEntry>, List<LeaveBalance>)> leaveLedger(int employeeId) async {
    final resp = await api.post('leave.php', {'action': 'ledger_list', 'employeeId': '$employeeId'});
    final entries = ((resp['entries'] as List?) ?? [])
        .map((e) => LeaveLedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final balances = ((resp['balances'] as List?) ?? [])
        .map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>))
        .toList();
    return (entries, balances);
  }

  Future<void> leaveCreditAdd({
    required int employeeId,
    required String leaveType,
    required String transactionType,
    required double amount,
    required String particularDate,
    String remarks = '',
  }) async {
    await api.post('leave.php', {
      'action': 'credit_add',
      'employeeId': '$employeeId',
      'leaveType': leaveType,
      'transactionType': transactionType,
      'amount': '$amount',
      'particularDate': particularDate,
      'remarks': remarks,
    });
  }

  Future<void> leaveLedgerEdit({
    required int ledgerId,
    required int employeeId,
    required double earned,
    required double deduction,
    String remarks = '',
  }) async {
    await api.post('leave.php', {
      'action': 'ledger_edit',
      'ledgerId': '$ledgerId',
      'employeeId': '$employeeId',
      'earned': '$earned',
      'deduction': '$deduction',
      'remarks': remarks,
    });
  }

  Future<List<LeaveApplication>> leaveApplications({String dateFilter = 'today'}) async {
    final resp = await api.post('leave.php', {'action': 'applications_list', 'dateFilter': dateFilter});
    return ((resp['applications'] as List?) ?? [])
        .map((e) => LeaveApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------- Travel Orders ----------------

  Future<List<TravelOrder>> travelOrderList({String search = ''}) async {
    final resp = await api.post('travel.php', {
      'action': 'list',
      if (search.isNotEmpty) 'search': search,
    });
    return ((resp['travelOrders'] as List?) ?? [])
        .map((e) => TravelOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TravelOrder> travelOrderDetail(int id) async {
    final resp = await api.post('travel.php', {'action': 'detail', 'id': '$id'});
    return TravelOrder.fromJson(resp['travelOrder'] as Map<String, dynamic>);
  }

  Future<int> travelOrderAdd(Map<String, String> fields) async {
    final resp = await api.post('travel.php', {'action': 'add', ...fields});
    return resp['id'] as int;
  }

  Future<void> travelOrderAdvance(int id, String to) async {
    await api.post('travel.php', {'action': 'advance', 'id': '$id', 'to': to});
  }

  // ---------------- Announcements ----------------

  Future<int> announcementSend(Map<String, String> fields, {String? filePath}) async {
    final resp = await api.postMultipart('announcements.php', {'action': 'send', ...fields},
        filePath: filePath, fileField: 'file');
    return resp['recipientCount'] as int? ?? 0;
  }

  Future<List<SentAnnouncement>> announcementHistory() async {
    final resp = await api.post('announcements.php', {'action': 'sent_list'});
    return ((resp['announcements'] as List?) ?? [])
        .map((e) => SentAnnouncement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------- Accounts / Profile / Registrations ----------------

  Future<Map<String, dynamic>> profileGet() async {
    final resp = await api.post('accounts.php', {'action': 'profile_get'});
    return resp['admin'] as Map<String, dynamic>;
  }

  Future<void> profileEdit({required String name, required String mobileNumber, required String email}) async {
    await api.post('accounts.php', {
      'action': 'profile_edit',
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
    });
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await api.post('accounts.php', {
      'action': 'change_password',
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<List<AdminAccount>> adminsList() async {
    final resp = await api.post('accounts.php', {'action': 'admins_list'});
    return ((resp['admins'] as List?) ?? [])
        .map((e) => AdminAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> adminAdd({
    required String name,
    required String email,
    required String username,
    required String password,
  }) async {
    await api.post('accounts.php', {
      'action': 'admin_add',
      'name': name,
      'email': email,
      'username': username,
      'password': password,
    });
  }

  Future<bool> adminToggle(int id) async {
    final resp = await api.post('accounts.php', {'action': 'admin_toggle', 'id': '$id'});
    return resp['isActive'] as bool;
  }

  Future<void> adminResetPassword(int id, String newPassword) async {
    await api.post('accounts.php', {
      'action': 'admin_reset_password',
      'id': '$id',
      'newPassword': newPassword,
    });
  }

  Future<List<PendingRegistration>> registrationsList({String status = 'Pending'}) async {
    final resp = await api.post('accounts.php', {'action': 'registrations_list', 'status': status});
    return ((resp['registrations'] as List?) ?? [])
        .map((e) => PendingRegistration.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> registrationSetStatus(int id, String status) async {
    await api.post('accounts.php', {
      'action': 'registrations_set_status',
      'id': '$id',
      'status': status,
    });
  }
}

class DashboardData {
  final Map<String, int> counts;
  final List<Map<String, dynamic>> onLeaveToday;
  final List<Map<String, dynamic>> onTravelToday;
  final int pendingRegistrations;

  DashboardData({
    required this.counts,
    required this.onLeaveToday,
    required this.onTravelToday,
    required this.pendingRegistrations,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final counts = (json['counts'] as Map<String, dynamic>? ?? {});
    return DashboardData(
      counts: counts.map((k, v) => MapEntry(k, (v as num).toInt())),
      onLeaveToday: ((json['onLeaveToday'] as List?) ?? []).cast<Map<String, dynamic>>(),
      onTravelToday: ((json['onTravelToday'] as List?) ?? []).cast<Map<String, dynamic>>(),
      pendingRegistrations: (json['pendingRegistrations'] as num?)?.toInt() ?? 0,
    );
  }
}
