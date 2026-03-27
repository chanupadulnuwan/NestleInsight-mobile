class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.metadata,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];

    return ActivityEntry(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      metadata: rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : null,
    );
  }

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
}
