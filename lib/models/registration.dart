class PendingRegistration {
  final int id;
  final String? empId;
  final String name;
  final String? email;
  final String? contactNumber;
  final String? designation;
  final String? department;
  final String? createdDate;

  PendingRegistration({
    required this.id,
    this.empId,
    this.name = '',
    this.email,
    this.contactNumber,
    this.designation,
    this.department,
    this.createdDate,
  });

  factory PendingRegistration.fromJson(Map<String, dynamic> j) => PendingRegistration(
        id: j['id'] as int,
        empId: j['empId'] as String?,
        name: j['name'] as String? ?? '',
        email: j['email'] as String?,
        contactNumber: j['contactNumber'] as String?,
        designation: j['designation'] as String?,
        department: j['department'] as String?,
        createdDate: j['createdDate'] as String?,
      );
}

class AdminAccount {
  final int id;
  final String name;
  final String email;
  final String username;
  final bool isActive;

  AdminAccount({
    required this.id,
    this.name = '',
    this.email = '',
    this.username = '',
    this.isActive = true,
  });

  factory AdminAccount.fromJson(Map<String, dynamic> j) => AdminAccount(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        username: j['username'] as String? ?? '',
        isActive: j['isActive'] as bool? ?? true,
      );
}
