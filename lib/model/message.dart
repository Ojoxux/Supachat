class Message {
  Message({
    required this.id,
    required this.profileId,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  /// [map]にSupabaseからのデータを渡し、[myUserId]には自分のauthのユーザーIDを渡すと[Message]のインスタンスを作成できる。
  Message.fromMap({required Map<String, dynamic> map, required String myUserId})
    : id = map['id'] as String,
      profileId = map['profile_id'] as String,
      content = map['content'] as String,
      createdAt = DateTime.parse(map['created_at'] as String),
      isMine = myUserId == map['profile_id'];

  /// メッセージのID
  final String id;

  /// メッセージを送信した人のユーザーID
  final String profileId;

  /// メッセージの内容
  final String content;

  /// メッセージの送信日時
  final DateTime createdAt;

  /// このメッセージを送ったのが自分かどうか
  final bool isMine;
}
