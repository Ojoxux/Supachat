import '../../../../core/utils/typedef.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// ログインのUse Case
class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  /// ログインを実行
  ResultFuture<User> call({
    required String email,
    required String password,
  }) async {
    return _repository.signIn(email: email, password: password);
  }
}
