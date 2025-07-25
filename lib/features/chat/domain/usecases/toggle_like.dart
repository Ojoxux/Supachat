import '../../../../core/utils/typedef.dart';
import '../repositories/chat_repository.dart';

/// いいねを切り替えるユースケース
class ToggleLike {
  const ToggleLike(this._repository);

  final ChatRepository _repository;

  /// いいねを切り替え
  ResultVoid call({required String messageId, required String userId}) async {
    return _repository.toggleLike(messageId: messageId, userId: userId);
  }
}
