/// ユーザーのプロフィール情報を保持するクラス
class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.createdAt,
    this.messageCount = 0,
  });

  Profile.fromMap(Map<String, dynamic> map)
    : id = map['id'] as String,
      username = map['username'] as String,
      createdAt = DateTime.parse(map['created_at'] as String),
      messageCount = map['message_count'] as int? ?? 0;

  /// ユーザーのID
  final String id;

  /// ユーザー名
  final String username;

  /// ユーザーの作成日時
  final DateTime createdAt;

  /// ユーザーのメッセージ投稿数
  final int messageCount;
}
