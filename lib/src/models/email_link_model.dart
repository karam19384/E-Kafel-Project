// lib/src/models/email_link_model.dart
class EmailLinkRequest {
  final String email;
  final String userId;
  final DateTime requestedAt;
  final String status; // pending, verified, expired
  final String? verificationCode;

  EmailLinkRequest({
    required this.email,
    required this.userId,
    required this.requestedAt,
    this.status = 'pending',
    this.verificationCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'userId': userId,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status,
      'verificationCode': verificationCode,
    };
  }

  factory EmailLinkRequest.fromMap(Map<String, dynamic> map) {
    return EmailLinkRequest(
      email: map['email'] ?? '',
      userId: map['userId'] ?? '',
      requestedAt: DateTime.parse(map['requestedAt']),
      status: map['status'] ?? 'pending',
      verificationCode: map['verificationCode'],
    );
  }
}