import '../../../../core/utils/typedef.dart';
import '../entities/profile.dart';

/// プロフィールリポジトリのインターフェース
abstract class ProfileRepository {
  /// プロフィールを取得
  ResultFuture<Profile> getProfile({required String profileId});

  /// 複数のプロフィールを取得
  ResultFuture<List<Profile>> getProfiles({required List<String> profileIds});

  /// プロフィールを更新
  ResultVoid updateProfile({
    required String profileId,
    required String username,
  });
}
