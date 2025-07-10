import '../../../../core/utils/typedef.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// 複数プロフィール取得のUse Case
class GetProfiles {
  const GetProfiles(this._repository);

  final ProfileRepository _repository;

  /// 複数のプロフィールを取得
  ResultFuture<List<Profile>> call({required List<String> profileIds}) async {
    return await _repository.getProfiles(profileIds: profileIds);
  }
}
