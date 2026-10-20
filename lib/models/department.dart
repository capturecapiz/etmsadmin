class Department {
  final int id;
  final String name;
  final String? divisionHead;

  Department({required this.id, required this.name, this.divisionHead});

  factory Department.fromJson(Map<String, dynamic> j) => Department(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        divisionHead: j['divisionHead'] as String?,
      );
}
