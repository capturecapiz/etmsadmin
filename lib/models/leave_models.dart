class LeaveType {
  final int id;
  final String name;
  final double defaultDeductionPerDay;
  final double? monthlyAccrual;
  final bool isActive;

  LeaveType({
    required this.id,
    required this.name,
    this.defaultDeductionPerDay = 1.0,
    this.monthlyAccrual,
    this.isActive = true,
  });

  factory LeaveType.fromJson(Map<String, dynamic> j) => LeaveType(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        defaultDeductionPerDay: (j['defaultDeductionPerDay'] as num?)?.toDouble() ?? 1.0,
        monthlyAccrual: (j['monthlyAccrual'] as num?)?.toDouble(),
        isActive: j['isActive'] as bool? ?? true,
      );
}

class LeaveLedgerEntry {
  final int id;
  final String leaveType;
  final String? year;
  final String? month;
  final String? particularDate;
  final double earned;
  final double deduction;
  final double balance;
  final String remarks;

  LeaveLedgerEntry({
    required this.id,
    required this.leaveType,
    this.year,
    this.month,
    this.particularDate,
    this.earned = 0,
    this.deduction = 0,
    this.balance = 0,
    this.remarks = '',
  });

  factory LeaveLedgerEntry.fromJson(Map<String, dynamic> j) => LeaveLedgerEntry(
        id: j['id'] as int,
        leaveType: j['leaveType'] as String? ?? '',
        year: j['year']?.toString(),
        month: j['month'] as String?,
        particularDate: j['particularDate'] as String?,
        earned: (j['earned'] as num?)?.toDouble() ?? 0,
        deduction: (j['deduction'] as num?)?.toDouble() ?? 0,
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
        remarks: j['remarks'] as String? ?? '',
      );
}

class LeaveBalance {
  final String leaveType;
  final double balance;
  LeaveBalance({required this.leaveType, required this.balance});
  factory LeaveBalance.fromJson(Map<String, dynamic> j) => LeaveBalance(
        leaveType: j['leaveType'] as String? ?? '',
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
      );
}

class LeaveApplication {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String? designation;
  final String? department;
  final String leaveType;
  final String status;
  final String? start;
  final String? end;

  LeaveApplication({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.designation,
    this.department,
    this.leaveType = '',
    this.status = 'Pending',
    this.start,
    this.end,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> j) => LeaveApplication(
        id: j['id'] as int,
        employeeId: j['employeeId'] as int,
        employeeName: j['employeeName'] as String?,
        designation: j['designation'] as String?,
        department: j['department'] as String?,
        leaveType: j['leaveType'] as String? ?? '',
        status: j['status'] as String? ?? 'Pending',
        start: j['start'] as String?,
        end: j['end'] as String?,
      );
}
