import 'package:equatable/equatable.dart';

/// チャットメッセージのエンティティ
class Message extends Equatable {
  const Message({
    required this.id,
    required this.profileId,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String profileId;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  @override
  List<Object?> get props => [id, profileId, content, createdAt, isMine];
}
