class SentAnnouncement {
  final String? date;
  final String? time;
  final String title;
  final String description;
  final String? source;
  final String? filePath;
  final int recipientCount;
  final String? recipients;

  SentAnnouncement({
    this.date,
    this.time,
    this.title = '',
    this.description = '',
    this.source,
    this.filePath,
    this.recipientCount = 0,
    this.recipients,
  });

  factory SentAnnouncement.fromJson(Map<String, dynamic> j) => SentAnnouncement(
        date: j['date'] as String?,
        time: j['time'] as String?,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        source: j['source'] as String?,
        filePath: j['filePath'] as String?,
        recipientCount: j['recipientCount'] as int? ?? 0,
        recipients: j['recipients'] as String?,
      );
}
