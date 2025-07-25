import 'package:equatable/equatable.dart';

/// ユーザープロフィールのエンティティ
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.username,
    required this.createdAt,
    this.messageCount = 0,
  });

  final String id;
  final String username;
  final DateTime createdAt;
  final int messageCount;

  @override
  List<Object?> get props => [id, username, createdAt, messageCount];
}
