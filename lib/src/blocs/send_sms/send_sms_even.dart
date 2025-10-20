part of 'send_sms_bloc.dart';

// الأحداث
abstract class SMSEvent {}

class LoadRecipientsEvent extends SMSEvent {
  final String recipientType;

  LoadRecipientsEvent(this.recipientType);
}

class SearchRecipientsEvent extends SMSEvent {
  final String query;
  final String recipientType;

  SearchRecipientsEvent(this.query, this.recipientType);
}

class SendSMSEvent extends SMSEvent {
  final Message message;

  SendSMSEvent(this.message);
}

class LoadMessagesHistoryEvent extends SMSEvent {}

class LoadSMSStatsEvent extends SMSEvent {}