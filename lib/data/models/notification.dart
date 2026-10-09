class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.header,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.subHeader,
    this.deepLink,
    this.ctaText,
    this.ctaUrl,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        type: (json['type'] ?? 'system').toString(),
        category: (json['notificationCategory'] ?? 'system').toString(),
        header: (json['mainHeader'] ?? json['header'] ?? 'Transfa').toString(),
        subHeader: json['subHeader']?.toString(),
        body: (json['body'] ?? '').toString(),
        isRead: json['isRead'] == true,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        deepLink: json['deepLink']?.toString(),
        ctaText: json['ctaText']?.toString(),
        ctaUrl: json['ctaUrl']?.toString(),
      );

  final String id;
  final String type;
  final String category;
  final String header;
  final String? subHeader;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? deepLink;
  final String? ctaText;
  final String? ctaUrl;
}
