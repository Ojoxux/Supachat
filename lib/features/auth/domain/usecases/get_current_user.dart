import '../../../../core/utils/typedef.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// 現在のユーザー取得のUse Case
class GetCurrentUser {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  /// 現在のユーザーを取得
  ResultFuture<User?> call() async {
    return await _repository.getCurrentUser();
  }
}
