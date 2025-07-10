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
          .from('messages')
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
      return _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map(
            (maps) =>
                maps
                    .map(
                      (map) => MessageModel.fromMap(
                        map: map,
                        currentUserId: currentUserId,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
