class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.status,
    required this.createdAt,
    this.subject,
    this.transactionId,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: (json['ticketId'] ?? json['id']).toString(),
    status: (json['status'] ?? 'open').toString(),
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    subject: json['subject']?.toString(),
    transactionId: json['transactionId']?.toString(),
    messages: (json['messages'] as List? ?? const [])
        .map(
          (message) => SupportMessage.fromJson(
            Map<String, dynamic>.from(message as Map),
          ),
        )
        .toList(),
  );

  final String id;
  final String status;
  final DateTime createdAt;
  final String? subject;
  final String? transactionId;
  final List<SupportMessage> messages;
}

class SupportMessage {
  const SupportMessage({
    required this.sender,
    required this.message,
    required this.createdAt,
    this.attachmentUrls = const [],
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    sender: (json['sender'] ?? 'support').toString(),
    message: (json['message'] ?? '').toString(),
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    attachmentUrls: (json['attachmentUrls'] as List? ?? const [])
        .map((url) => url.toString())
        .toList(),
  );

  final String sender;
  final String message;
  final DateTime createdAt;
  final List<String> attachmentUrls;
}

class SupportAttachment {
  const SupportAttachment({
    required this.url,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });

  factory SupportAttachment.fromJson(Map<String, dynamic> json) =>
      SupportAttachment(
        url: json['attachmentUrl'].toString(),
        fileName: json['fileName'].toString(),
        fileType: json['fileType'].toString(),
        fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      );

  final String url;
  final String fileName;
  final String fileType;
  final int fileSize;
}
