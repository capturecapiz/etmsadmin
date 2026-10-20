class Admin {
  final int id;
  final String name;
  final String email;
  final String username;
  final String? mobileNumber;
  final String? registeredDate;
  final bool isActive;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.mobileNumber,
    this.registeredDate,
    this.isActive = true,
  });

  factory Admin.fromJson(Map<String, dynamic> j) => Admin(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        username: j['username'] as String? ?? '',
        mobileNumber: j['mobileNumber'] as String?,
        registeredDate: j['registeredDate'] as String?,
        isActive: j['isActive'] as bool? ?? true,
      );
}
