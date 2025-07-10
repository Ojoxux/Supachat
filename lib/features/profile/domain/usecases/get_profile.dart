import '../../../../core/utils/typedef.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// プロフィール取得のUse Case
class GetProfile {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  /// プロフィールを取得
  ResultFuture<Profile> call({required String profileId}) async {
    return await _repository.getProfile(profileId: profileId);
  }
}
