class TaskTracking {
  final String remark;
  final String? status;
  final int? workCompleted;
  final String? date;

  TaskTracking({required this.remark, this.status, this.workCompleted, this.date});

  factory TaskTracking.fromJson(Map<String, dynamic> j) => TaskTracking(
        remark: j['remark'] as String? ?? '',
        status: j['status'] as String?,
        workCompleted: j['workCompleted'] as int?,
        date: j['date'] as String?,
      );
}

class TaskItem {
  final int id;
  final String title;
  final String description;
  final String priority;
  final String? status;
  final int workCompleted;
  final String? assignedDate;
  final String? dueDate;
  final int? employeeId;
  final String? employeeName;
  final int? departmentId;
  final String? departmentName;

  TaskItem({
    required this.id,
    this.title = '',
    this.description = '',
    this.priority = '',
    this.status,
    this.workCompleted = 0,
    this.assignedDate,
    this.dueDate,
    this.employeeId,
    this.employeeName,
    this.departmentId,
    this.departmentName,
  });

  /// Matches dashboard.php's own bucket definitions exactly.
  String get bucketLabel {
    if (status == 'Completed') return 'Completed';
    if (status == 'Cancelled') return 'Cancelled';
    if (status == 'Inprogress') return 'In Progress';
    if (status == null) return 'Not Started';
    return status!;
  }

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        priority: j['priority'] as String? ?? '',
        status: j['status'] as String?,
        workCompleted: j['workCompleted'] as int? ?? 0,
        assignedDate: j['assignedDate'] as String?,
        dueDate: j['dueDate'] as String?,
        employeeId: j['employeeId'] as int?,
        employeeName: j['employeeName'] as String?,
        departmentId: j['departmentId'] as int?,
        departmentName: j['departmentName'] as String?,
      );
}
