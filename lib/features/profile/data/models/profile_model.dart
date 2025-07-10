import '../../../../core/utils/typedef.dart';
import '../../domain/entities/profile.dart';

/// プロフィールのデータモデル
class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.username,
    required super.createdAt,
  });

  /// MapからProfileModelを作成
  factory ProfileModel.fromMap(DataMap map) {
    return ProfileModel(
      id: map['id'] as String,
      username: map['username'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// ProfileModelをMapに変換
  DataMap toMap() {
    return {
      'id': id,
      'username': username,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// ProfileModelをProfileエンティティに変換
  Profile toEntity() {
    return Profile(id: id, username: username, createdAt: createdAt);
  }
}
