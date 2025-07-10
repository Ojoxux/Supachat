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
      final response =
          await _client
              .from('profiles')
              .select('*')
              .eq('id', profileId)
              .single();

      return ProfileModel.fromMap(response as Map<String, dynamic>);
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
          .select('*')
          .inFilter('id', profileIds);

      return response
          .map((map) => ProfileModel.fromMap(map as Map<String, dynamic>))
          .toList();
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
