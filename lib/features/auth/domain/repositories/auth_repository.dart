import '../../../../core/utils/typedef.dart';
import '../entities/user.dart';

/// 認証リポジトリのインターフェース
abstract class AuthRepository {
  /// ユーザー登録
  ResultFuture<User> signUp({
    required String email,
    required String password,
    required String username,
  });

  /// ログイン
  ResultFuture<User> signIn({required String email, required String password});

  /// ログアウト
  ResultVoid signOut();

  /// 現在のユーザーを取得
  ResultFuture<User?> getCurrentUser();

  /// 認証状態の変更を監視
  Stream<User?> get authStateChanges;
}
