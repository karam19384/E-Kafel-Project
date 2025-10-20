import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_kafel/src/services/sms_service.dart';
import '../../models/massege_model.dart';
part 'send_sms_even.dart';
part 'send_sms_state.dart';

// البلوك
class SMSBloc extends Bloc<SMSEvent, SMSState> {
  final SMSService _smsService;

  SMSBloc(this._smsService) : super(SMSInitial()) {
    on<LoadRecipientsEvent>(_onLoadRecipients);
    on<SearchRecipientsEvent>(_onSearchRecipients);
    on<SendSMSEvent>(_onSendSMS);
    on<LoadMessagesHistoryEvent>(_onLoadMessagesHistory);
    on<LoadSMSStatsEvent>(_onLoadSMSStats);
  }

  Future<void> _onLoadRecipients(LoadRecipientsEvent event, Emitter<SMSState> emit) async {
    emit(SMSLoading());
    try {
      final recipientsStream = _smsService.getRecipientsByType(event.recipientType);
      await for (final recipients in recipientsStream) {
        emit(RecipientsLoaded(recipients));
        break;
      }
    } catch (e) {
      emit(SMSError('فشل في تحميل المستلمين: $e'));
    }
  }

  Future<void> _onSearchRecipients(SearchRecipientsEvent event, Emitter<SMSState> emit) async {
    emit(SMSLoading());
    try {
      final recipients = await _smsService.searchRecipients(event.query, event.recipientType);
      emit(RecipientsLoaded(recipients));
    } catch (e) {
      emit(SMSError('فشل في البحث: $e'));
    }
  }

  Future<void> _onSendSMS(SendSMSEvent event, Emitter<SMSState> emit) async {
    emit(SMSLoading());
    try {
      await _smsService.sendMessage(event.message);
      emit(SMSSentSuccess());
    } catch (e) {
      emit(SMSError('فشل في إرسال الرسالة: $e'));
    }
  }

  Future<void> _onLoadMessagesHistory(LoadMessagesHistoryEvent event, Emitter<SMSState> emit) async {
    emit(SMSLoading());
    try {
      await for (final messages in _smsService.getMessagesHistory()) {
        emit(MessagesHistoryLoaded(messages));
        break;
      }
    } catch (e) {
      emit(SMSError('فشل في تحميل سجل الرسائل: $e'));
    }
  }

  Future<void> _onLoadSMSStats(LoadSMSStatsEvent event, Emitter<SMSState> emit) async {
    try {
      final stats = await _smsService.getSMSStats();
      emit(SMSStatsLoaded(stats));
    } catch (e) {
      emit(SMSError('فشل في تحميل الإحصائيات: $e'));
    }
  }
}