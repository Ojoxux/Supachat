import 'package:equatable/equatable.dart';

/// 認証ユーザーのエンティティ
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String username;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, email, username, createdAt];
}
