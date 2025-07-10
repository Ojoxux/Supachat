import '../../../../core/utils/typedef.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// ユーザー登録のUse Case
class SignUp {
  const SignUp(this._repository);

  final AuthRepository _repository;

  /// ユーザー登録を実行
  ResultFuture<User> call({
    required String email,
    required String password,
    required String username,
  }) async {
    return await _repository.signUp(
      email: email,
      password: password,
      username: username,
    );
  }
}
