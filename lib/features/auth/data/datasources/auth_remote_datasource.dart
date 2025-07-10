import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedef.dart';
import '../models/user_model.dart';

/// 認証のリモートデータソースのインターフェース
abstract class AuthRemoteDataSource {
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<UserModel> signIn({required String email, required String password});

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;
}

/// 認証のリモートデータソースの実装
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user == null) {
        throw const ServerFailure(message: 'ユーザー登録に失敗しました');
      }

      // プロフィールテーブルにもデータを挿入
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'username': username,
      });

      return UserModel(
        id: response.user!.id,
        email: response.user!.email!,
        username: username,
        createdAt: DateTime.parse(response.user!.createdAt),
      );
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const ServerFailure(message: 'ログインに失敗しました');
      }

      // プロフィール情報を取得
      final profileData =
          await _client
              .from('profiles')
              .select('username')
              .eq('id', response.user!.id)
              .single();

      return UserModel(
        id: response.user!.id,
        email: response.user!.email!,
        username: profileData['username'] as String,
        createdAt: DateTime.parse(response.user!.createdAt),
      );
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      // プロフィール情報を取得
      final profileData =
          await _client
              .from('profiles')
              .select('username')
              .eq('id', user.id)
              .single();

      return UserModel(
        id: user.id,
        email: user.email!,
        username: profileData['username'] as String,
        createdAt: DateTime.parse(user.createdAt),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;

      // 注意: ストリームでのプロフィール取得は簡略化
      // 実際のプロジェクトではより適切な実装が必要
      return UserModel(
        id: user.id,
        email: user.email!,
        username: '', // ストリームでは空文字列
        createdAt: DateTime.parse(user.createdAt),
      );
    });
  }
}
