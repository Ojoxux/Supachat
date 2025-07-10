import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// メッセージ監視のUse Case
class WatchMessages {
  const WatchMessages(this._repository);

  final ChatRepository _repository;

  /// メッセージのリアルタイム更新を監視
  Stream<List<Message>> call({required String currentUserId}) {
    return _repository.watchMessages(currentUserId: currentUserId);
  }
}
