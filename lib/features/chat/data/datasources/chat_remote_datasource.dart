import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../models/message_model.dart';

/// チャットのリモートデータソースのインターフェース
abstract class ChatRemoteDataSource {
  Future<void> sendMessage({
    required String content,
    required String profileId,
  });

  Future<List<MessageModel>> getMessages({required String currentUserId});

  Stream<List<MessageModel>> watchMessages({required String currentUserId});

  Future<void> toggleLike({required String messageId, required String userId});

  Future<void> editMessage({
    required String messageId,
    required String newContent,
  });
}

/// チャットのリモートデータソースの実装
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  const ChatRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> sendMessage({
    required String content,
    required String profileId,
  }) async {
    try {
      await _client.from('messages').insert({
        'profile_id': profileId,
        'content': content,
      });
    } on PostgrestException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<MessageModel>> getMessages({
    required String currentUserId,
  }) async {
    try {
      final response = await _client
          .from('messages_with_likes')
          .select('*')
          .order('created_at', ascending: false);

      return response
          .map(
            (map) =>
                MessageModel.fromMap(map: map, currentUserId: currentUserId),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Stream<List<MessageModel>> watchMessages({required String currentUserId}) {
    try {
      late StreamController<List<MessageModel>> controller;
      StreamSubscription<List<Map<String, dynamic>>>? messagesSubscription;
      StreamSubscription<List<Map<String, dynamic>>>? likesSubscription;

      Future<void> fetchAndEmitMessages() async {
        try {
          final messages = await getMessages(currentUserId: currentUserId);
          if (!controller.isClosed) {
            controller.add(messages);
          }
        } catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      }

      controller = StreamController<List<MessageModel>>(
        onListen: () {
          // 初回データ取得
          fetchAndEmitMessages();

          // messagesテーブルの変更を監視
          messagesSubscription = _client
              .from('messages')
              .stream(primaryKey: ['id'])
              .listen(
                (_) => fetchAndEmitMessages(),
                onError: (Object error) {
                  if (!controller.isClosed) {
                    controller.addError(error);
                  }
                },
              );

          // message_likesテーブルの変更を監視
          likesSubscription = _client
              .from('message_likes')
              .stream(primaryKey: ['id'])
              .listen(
                (_) => fetchAndEmitMessages(),
                onError: (Object error) {
                  if (!controller.isClosed) {
                    controller.addError(error);
                  }
                },
              );
        },
        onCancel: () {
          messagesSubscription?.cancel();
          likesSubscription?.cancel();
          controller.close();
        },
      );

      return controller.stream;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> toggleLike({
    required String messageId,
    required String userId,
  }) async {
    try {
      // 既存のいいねを確認
      final existingLike =
          await _client
              .from('message_likes')
              .select('id')
              .eq('message_id', messageId)
              .eq('user_id', userId)
              .maybeSingle();

      if (existingLike != null) {
        // いいねを削除
        await _client
            .from('message_likes')
            .delete()
            .eq('message_id', messageId)
            .eq('user_id', userId);
      } else {
        // いいねを追加
        await _client.from('message_likes').insert({
          'message_id': messageId,
          'user_id': userId,
        });
      }
    } on PostgrestException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      await _client
          .from('messages')
          .update({'content': newContent})
          .eq('id', messageId);
    } on PostgrestException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
