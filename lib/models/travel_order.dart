class TravelOrder {
  final int id;
  final String officerNames;
  final String destination;
  final String? periodFrom;
  final String? periodTo;
  final String purpose;
  final bool natureOfficialTime;
  final bool natureOfficialBusiness;
  final String recommendingName;
  final String recommendingDesignation;
  final String approvingName;
  final String approvingDesignation;
  final String status;
  final String? creationDate;

  TravelOrder({
    required this.id,
    this.officerNames = '',
    this.destination = '',
    this.periodFrom,
    this.periodTo,
    this.purpose = '',
    this.natureOfficialTime = false,
    this.natureOfficialBusiness = false,
    this.recommendingName = '',
    this.recommendingDesignation = '',
    this.approvingName = '',
    this.approvingDesignation = '',
    this.status = 'Pending',
    this.creationDate,
  });

  factory TravelOrder.fromJson(Map<String, dynamic> j) => TravelOrder(
        id: j['id'] as int,
        officerNames: j['officerNames'] as String? ?? '',
        destination: j['destination'] as String? ?? '',
        periodFrom: j['periodFrom'] as String?,
        periodTo: j['periodTo'] as String?,
        purpose: j['purpose'] as String? ?? '',
        natureOfficialTime: j['natureOfficialTime'] as bool? ?? false,
        natureOfficialBusiness: j['natureOfficialBusiness'] as bool? ?? false,
        recommendingName: j['recommendingName'] as String? ?? '',
        recommendingDesignation: j['recommendingDesignation'] as String? ?? '',
        approvingName: j['approvingName'] as String? ?? '',
        approvingDesignation: j['approvingDesignation'] as String? ?? '',
        status: j['status'] as String? ?? 'Pending',
        creationDate: j['creationDate'] as String?,
      );
}
