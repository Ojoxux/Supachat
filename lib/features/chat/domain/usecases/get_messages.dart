import '../../../../core/utils/typedef.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// メッセージ取得のUse Case
class GetMessages {
  const GetMessages(this._repository);

  final ChatRepository _repository;

  /// メッセージ一覧を取得
  ResultFuture<List<Message>> call({required String currentUserId}) async {
    return await _repository.getMessages(currentUserId: currentUserId);
  }
}
