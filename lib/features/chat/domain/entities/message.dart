import 'package:equatable/equatable.dart';

/// チャットメッセージのエンティティ
class Message extends Equatable {
  const Message({
    required this.id,
    required this.profileId,
    required this.content,
    required this.createdAt,
    required this.isMine,
    this.likeCount = 0,
    this.isLikedByMe = false,
  });

  final String id;
  final String profileId;
  final String content;
  final DateTime createdAt;
  final bool isMine;
  final int likeCount;
  final bool isLikedByMe;

  /// いいね状態を更新した新しいMessageインスタンスを作成
  Message copyWithLike({required int likeCount, required bool isLikedByMe}) {
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

  @override
  List<Object?> get props => [
    id,
    profileId,
    content,
    createdAt,
    isMine,
    likeCount,
    isLikedByMe,
  ];
}
