class Message {
  final String id;
  final String recipientType;
  final List<String> recipientIds;
  final List<String> recipientPhones;
  final String messageText;
  final DateTime scheduledTime;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime createdAt;
final String senderId;
final String senderName;
  Message({
    required this.id,
    required this.recipientType,
    required this.recipientIds,
    required this.recipientPhones,
    required this.messageText,
    required this.scheduledTime,
    this.isSent = false,
    this.sentAt,
    required this.createdAt, 
    required  this.senderId,
     required this.senderName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientType': recipientType,
      'recipientIds': recipientIds,
      'recipientPhones': recipientPhones,
      'messageText': messageText,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'isSent': isSent,
      'sentAt': sentAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'senderId':senderId,
      'senderName':senderName,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      recipientType: map['recipientType'],
      recipientIds: List<String>.from(map['recipientIds']),
      recipientPhones: List<String>.from(map['recipientPhones']),
      messageText: map['messageText'],
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledTime']),
      isSent: map['isSent'],
      sentAt: map['sentAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['sentAt']) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      senderId: map['senderId'],
      senderName: map['senderName'],
    );
  }
}