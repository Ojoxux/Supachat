import '../../../../core/utils/typedef.dart';
import '../repositories/auth_repository.dart';

/// ログアウトのUse Case
class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  /// ログアウトを実行
  ResultVoid call() async {
    return _repository.signOut();
  }
}
