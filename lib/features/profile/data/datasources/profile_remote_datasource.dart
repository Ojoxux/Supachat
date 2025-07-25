import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../models/profile_model.dart';

/// プロフィールのリモートデータソースのインターフェース
abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile({required String profileId});
  Future<List<ProfileModel>> getProfiles({required List<String> profileIds});
  Future<void> updateProfile({
    required String profileId,
    required String username,
  });
}

/// プロフィールのリモートデータソースの実装
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<ProfileModel> getProfile({required String profileId}) async {
    try {
      final response = await _client
          .from('profiles')
          .select('''
            *,
            message_count:messages(count)
          ''')
          .eq('id', profileId)
          .single();

      // メッセージ数を取得
      final messageCount = response['message_count'] as List?;
      final count = messageCount?.isNotEmpty == true 
          ? messageCount!.first['count'] as int? ?? 0
          : 0;

      // レスポンスにメッセージ数を追加
      final profileData = Map<String, dynamic>.from(response);
      profileData['message_count'] = count;
      profileData.remove('message_count'); // 元のmessage_countフィールドを削除
      profileData['message_count'] = count; // 正しい値を設定

      return ProfileModel.fromMap(profileData);
    } on PostgrestException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<ProfileModel>> getProfiles({
    required List<String> profileIds,
  }) async {
    try {
      final response = await _client
          .from('profiles')
          .select('''
            *,
            message_count:messages(count)
          ''')
          .inFilter('id', profileIds);

      return response.map((map) {
        // メッセージ数を取得
        final messageCount = map['message_count'] as List?;
        final count = messageCount?.isNotEmpty == true 
            ? messageCount!.first['count'] as int? ?? 0
            : 0;

        // レスポンスにメッセージ数を追加
        final profileData = Map<String, dynamic>.from(map);
        profileData['message_count'] = count;
        profileData.remove('message_count'); // 元のmessage_countフィールドを削除
        profileData['message_count'] = count; // 正しい値を設定

        return ProfileModel.fromMap(profileData);
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> updateProfile({
    required String profileId,
    required String username,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({'username': username})
          .eq('id', profileId);
    } on PostgrestException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
