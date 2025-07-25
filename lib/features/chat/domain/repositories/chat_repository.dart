import '../../../../core/utils/typedef.dart';
import '../entities/message.dart';

/// チャットリポジトリのインターフェース
abstract class ChatRepository {
  /// メッセージを送信
  ResultVoid sendMessage({required String content, required String profileId});

  /// メッセージ一覧を取得
  ResultFuture<List<Message>> getMessages({required String currentUserId});

  /// メッセージのリアルタイム更新を監視
  Stream<List<Message>> watchMessages({required String currentUserId});

  /// メッセージのいいねを切り替え
  ResultVoid toggleLike({required String messageId, required String userId});

  /// メッセージを編集
  ResultVoid editMessage({
    required String messageId,
    required String newContent,
  });
}
