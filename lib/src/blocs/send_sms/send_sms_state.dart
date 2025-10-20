part of 'send_sms_bloc.dart';

// الحالات
abstract class SMSState {}

class SMSInitial extends SMSState {}

class SMSLoading extends SMSState {}

class RecipientsLoaded extends SMSState {
  final List<Map<String, dynamic>> recipients;

  RecipientsLoaded(this.recipients);
}

class MessagesHistoryLoaded extends SMSState {
  final List<Message> messages;

  MessagesHistoryLoaded(this.messages);
}

class SMSStatsLoaded extends SMSState {
  final Map<String, dynamic> stats;

  SMSStatsLoaded(this.stats);
}

class SMSSentSuccess extends SMSState {}

class SMSError extends SMSState {
  final String message;

  SMSError(this.message);
}