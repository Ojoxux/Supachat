import '../../../../core/utils/typedef.dart';
import '../repositories/chat_repository.dart';

/// メッセージ編集ユースケース
class EditMessage {
  const EditMessage(this._repository);

  final ChatRepository _repository;

  /// メッセージを編集
  ResultVoid call({
    required String messageId,
    required String newContent,
  }) async {
    if (newContent.trim().isEmpty) {
      throw ArgumentError('メッセージ内容が空です');
    }

    return _repository.editMessage(
      messageId: messageId,
      newContent: newContent.trim(),
    );
  }
}
