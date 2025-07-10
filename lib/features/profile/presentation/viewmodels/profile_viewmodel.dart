import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/error_utils.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/get_profiles.dart';
import 'profile_state.dart';

/// プロフィールViewModelのProvider
final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, ProfileState>(
      (ref) => ProfileViewModel(
        getProfile: getIt<GetProfile>(),
        getProfiles: getIt<GetProfiles>(),
      ),
    );

/// プロフィールViewModel
class ProfileViewModel extends StateNotifier<ProfileState> {
  ProfileViewModel({required this.getProfile, required this.getProfiles})
    : super(const ProfileInitial());

  final GetProfile getProfile;
  final GetProfiles getProfiles;

  /// 単一のプロフィールを取得
  Future<void> loadProfile(String profileId) async {
    final currentProfiles = _getCurrentProfiles();
    state = const ProfileLoading();

    final result = await getProfile(profileId: profileId);

    result.fold((failure) => state = ProfileError(getErrorMessage(failure)), (
      profile,
    ) {
      final updatedProfiles = Map<String, Profile>.from(currentProfiles);
      updatedProfiles[profileId] = profile;
      state = ProfileLoaded(updatedProfiles);
    });
  }

  /// 複数のプロフィールを取得
  Future<void> loadProfiles(List<String> profileIds) async {
    if (profileIds.isEmpty) return;

    final currentProfiles = _getCurrentProfiles();
    state = const ProfileLoading();

    final result = await getProfiles(profileIds: profileIds);

    result.fold((failure) => state = ProfileError(getErrorMessage(failure)), (
      profiles,
    ) {
      final updatedProfiles = Map<String, Profile>.from(currentProfiles);

      for (final profile in profiles) {
        updatedProfiles[profile.id] = profile;
      }

      state = ProfileLoaded(updatedProfiles);
    });
  }

  /// 現在のプロフィールマップを取得
  Map<String, Profile> _getCurrentProfiles() {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      return currentState.profiles;
    }
    return {};
  }

  /// 特定のプロフィールを取得
  Profile? getProfileById(String profileId) {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      return currentState.profiles[profileId];
    }
    return null;
  }

  /// エラーをクリア
  void clearError() {
    if (state is ProfileError) {
      state = const ProfileInitial();
    }
  }
}
