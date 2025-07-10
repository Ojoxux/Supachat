import '../../../../core/utils/typedef.dart';
import '../../domain/entities/user.dart';

/// ユーザーのデータモデル
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.createdAt,
  });

  /// MapからUserModelを作成
  factory UserModel.fromMap(DataMap map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      username: map['username'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// UserModelをMapに変換
  DataMap toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// UserModelをUserエンティティに変換
  User toEntity() {
    return User(id: id, email: email, username: username, createdAt: createdAt);
  }
}
