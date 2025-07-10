import 'package:equatable/equatable.dart';

/// ユーザープロフィールのエンティティ
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  final String id;
  final String username;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, username, createdAt];
}
