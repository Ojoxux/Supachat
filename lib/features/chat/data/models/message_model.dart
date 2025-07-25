import '../../../../core/utils/typedef.dart';
import '../../domain/entities/message.dart';

/// メッセージのデータモデル
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.profileId,
    required super.content,
    required super.createdAt,
    required super.isMine,
    super.likeCount = 0,
    super.isLikedByMe = false,
  });

  /// MapからMessageModelを作成
  factory MessageModel.fromMap({
    required DataMap map,
    required String currentUserId,
  }) {
    return MessageModel(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isMine: currentUserId == map['profile_id'],
      likeCount: map['like_count'] as int? ?? 0,
      isLikedByMe: map['is_liked_by_me'] as bool? ?? false,
    );
  }

  /// MessageModelをMapに変換
  DataMap toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// MessageModelをMessageエンティティに変換
  Message toEntity() {
    return Message(
      id: id,
      profileId: profileId,
      content: content,
      createdAt: createdAt,
      isMine: isMine,
      likeCount: likeCount,
      isLikedByMe: isLikedByMe,
    );
  }
}
