import '../../../../core/utils/typedef.dart';
import '../repositories/chat_repository.dart';

/// メッセージ送信のUse Case
class SendMessage {
  const SendMessage(this._repository);

  final ChatRepository _repository;

  /// メッセージを送信
  ResultVoid call({required String content, required String profileId}) async {
    return _repository.sendMessage(content: content, profileId: profileId);
  }
}
