class Employee {
  final int id;
  final int? departmentId;
  final String department;
  final String empId;
  final String name;
  final String email;
  final String contactNumber;
  final String designation;
  final String dateOfBirth;
  final String address;
  final String dateOfJoining;
  final String description;
  final String classification;
  final String employmentStatus;
  final String registrationStatus;
  final String? photoUrl;

  Employee({
    required this.id,
    this.departmentId,
    this.department = '',
    this.empId = '',
    this.name = '',
    this.email = '',
    this.contactNumber = '',
    this.designation = '',
    this.dateOfBirth = '',
    this.address = '',
    this.dateOfJoining = '',
    this.description = '',
    this.classification = '',
    this.employmentStatus = 'Active',
    this.registrationStatus = 'Approved',
    this.photoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: j['id'] as int,
        departmentId: j['departmentId'] as int?,
        department: j['department'] as String? ?? '',
        empId: j['empId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        contactNumber: j['contactNumber'] as String? ?? '',
        designation: j['designation'] as String? ?? '',
        dateOfBirth: j['dateOfBirth'] as String? ?? '',
        address: j['address'] as String? ?? '',
        dateOfJoining: j['dateOfJoining'] as String? ?? '',
        description: j['description'] as String? ?? '',
        classification: j['classification'] as String? ?? '',
        employmentStatus: j['employmentStatus'] as String? ?? 'Active',
        registrationStatus: j['registrationStatus'] as String? ?? 'Approved',
        photoUrl: j['photoUrl'] as String?,
      );
}
