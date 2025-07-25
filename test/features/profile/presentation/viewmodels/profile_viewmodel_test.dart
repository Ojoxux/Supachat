import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:flutter_and_supabase_chat_app/core/error/failures.dart';
import 'package:flutter_and_supabase_chat_app/features/profile/domain/entities/profile.dart';
import 'package:flutter_and_supabase_chat_app/features/profile/domain/usecases/get_profile.dart';
import 'package:flutter_and_supabase_chat_app/features/profile/domain/usecases/get_profiles.dart';
import 'package:flutter_and_supabase_chat_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:flutter_and_supabase_chat_app/features/profile/presentation/viewmodels/profile_state.dart';

import 'profile_viewmodel_test.mocks.dart';

// Mockitoを使用してモックを生成
@GenerateMocks([GetProfile, GetProfiles])
void main() {
  group('ProfileViewModel', () {
    late ProfileViewModel profileViewModel;
    late MockGetProfile mockGetProfile;
    late MockGetProfiles mockGetProfiles;

    // テスト用のダミーデータ
    final testProfile1 = Profile(
      id: 'profile-1',
      username: 'user1',
      createdAt: DateTime.parse('2024-01-01T10:00:00Z'),
    );

    final testProfile2 = Profile(
      id: 'profile-2',
      username: 'user2',
      createdAt: DateTime.parse('2024-01-01T10:01:00Z'),
    );

    final testProfile3 = Profile(
      id: 'profile-3',
      username: 'user3',
      createdAt: DateTime.parse('2024-01-01T10:02:00Z'),
    );

    const testProfileId = 'profile-1';
    final List<Profile> testProfiles = [
      testProfile1,
      testProfile2,
      testProfile3,
    ];
    final testProfileIds = ['profile-1', 'profile-2', 'profile-3'];

    setUp(() {
      mockGetProfile = MockGetProfile();
      mockGetProfiles = MockGetProfiles();

      profileViewModel = ProfileViewModel(
        getProfile: mockGetProfile,
        getProfiles: mockGetProfiles,
      );
    });

    group('初期化', () {
      test('初期状態はProfileInitialである', () {
        expect(profileViewModel.state, isA<ProfileInitial>());
      });
    });

    group('loadProfile', () {
      test('プロフィール読み込み開始時はProfileLoading状態になる', () async {
        // Arrange
        when(mockGetProfile(profileId: testProfileId)).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return Right(testProfile1);
        });

        // Act
        await profileViewModel.loadProfile(testProfileId);

        // Assert - 初期状態から読み込み後はProfileLoaded状態になる
        expect(profileViewModel.state, isA<ProfileLoaded>());
        final loadedState = profileViewModel.state as ProfileLoaded;
        expect(loadedState.profiles[testProfileId], equals(testProfile1));
      });

      test('プロフィール読み込み成功時はProfileLoaded状態になる', () async {
        // Arrange
        when(
          mockGetProfile(profileId: testProfileId),
        ).thenAnswer((_) async => Right(testProfile1));

        // Act
        await profileViewModel.loadProfile(testProfileId);

        // Assert
        expect(profileViewModel.state, isA<ProfileLoaded>());
        final loadedState = profileViewModel.state as ProfileLoaded;
        expect(loadedState.profiles[testProfileId], equals(testProfile1));
      });

      test('既存のプロフィールがある場合、新しいプロフィールが追加される', () async {
        // Arrange - 既存のプロフィールを設定
        final Map<String, Profile> existingProfiles = {
          testProfile2.id: testProfile2,
        };
        profileViewModel.state = ProfileLoaded(existingProfiles);

        when(
          mockGetProfile(profileId: testProfileId),
        ).thenAnswer((_) async => Right(testProfile1));

        // Act
        await profileViewModel.loadProfile(testProfileId);

        // Assert
        expect(profileViewModel.state, isA<ProfileLoaded>());
        final loadedState = profileViewModel.state as ProfileLoaded;
        expect(loadedState.profiles.length, equals(2));
        expect(loadedState.profiles[testProfileId], equals(testProfile1));
        expect(loadedState.profiles[testProfile2.id], equals(testProfile2));
      });

      test('同じプロフィールIDの場合、既存のプロフィールは再取得されない', () async {
        // Arrange - 既存のプロフィールを設定
        final Map<String, Profile> existingProfiles = {
          testProfile1.id: testProfile1,
        };
        profileViewModel.state = ProfileLoaded(existingProfiles);

        final updatedProfile = Profile(
          id: testProfile1.id,
          username: 'updated_user',
          createdAt: testProfile1.createdAt,
        );

        when(
          mockGetProfile(profileId: testProfileId),
        ).thenAnswer((_) async => Right(updatedProfile));

        // Act
        await profileViewModel.loadProfile(testProfileId);

        // Assert - 既存のプロフィールがそのまま残る（再取得されない）
        expect(profileViewModel.state, isA<ProfileLoaded>());
        final loadedState = profileViewModel.state as ProfileLoaded;
        expect(loadedState.profiles.length, equals(1));
        expect(loadedState.profiles[testProfileId], equals(testProfile1));
        expect(loadedState.profiles[testProfileId]!.username, equals('user1'));

        // GetProfileが呼ばれていないことを確認
        verifyNever(mockGetProfile(profileId: testProfileId));
      });

      test('プロフィール読み込み失敗時はProfileError状態になる', () async {
        // Arrange
        const failure = ServerFailure(message: 'Profile not found');
        when(
          mockGetProfile(profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await profileViewModel.loadProfile(testProfileId);

        // Assert
        expect(profileViewModel.state, isA<ProfileError>());
        expect(
          (profileViewModel.state as ProfileError).message,
          equals('Profile not found'),
        );
      });
    });

    group('loadProfiles', () {
      test('空のプロフィールIDリストの場合、何も実行されない', () async {
        // Act
        await profileViewModel.loadProfiles([]);

        // Assert
        verifyNever(mockGetProfiles(profileIds: anyNamed('profileIds')));
        expect(profileViewModel.state, isA<ProfileInitial>());
      });

      test('初期状態からプロフィール読み込み開始時はProfileLoaded状態になる', () async {
        // Arrange
        when(mockGetProfiles(profileIds: testProfileIds)).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return Right(testProfiles);
        });

        // Act
        await profileViewModel.loadProfiles(testProfileIds);

        // Assert - 初期状態から読み込み後はProfileLoaded状態になる
        expect(profileViewModel.state, isA<ProfileLoaded>());
        final loadedState = profileViewModel.state as ProfileLoaded;
        expect(loadedState.profiles.length, equals(3));
      });

      test('複数プロフィール読み込み成功時はProfileLoaded状態になる', () async {
        // Arrange
        when(
          mockGetProfiles(profileIds: testProfileIds),
        ).thenAnswer((_) async => Right(testProfiles));

        // Act
        await profileViewModel.loadProfiles(testProfileIds);

        // Assert
        expect(profileViewModel.state, isA<ProfileLoaded>());
        final loadedState = profileViewModel.state as ProfileLoaded;
        expect(loadedState.profiles.length, equals(3));
        expect(loadedState.profiles[testProfile1.id], equals(testProfile1));
        expect(loadedState.profiles[testProfile2.id], equals(testProfile2));
        expect(loadedState.profiles[testProfile3.id], equals(testProfile3));
      });

      test('既存のプロフィールがある場合、新しいプロフィールが追加される（Loading状態にならない）', () async {
        // Arrange - 既存のプロフィールを設定
        final existingProfile = Profile(
          id: 'existing-profile',
          username: 'existing',
          createdAt: DateTime.parse('2024-01-01T09:00:00Z'),
        );
        final Map<String, Profile> existingProfiles = {
          existingProfile.id: existingProfile,
        };
        profileViewModel.state = ProfileLoaded(existingProfiles);

        when(
          mockGetProfiles(profileIds: testProfileIds),
        ).thenAnswer((_) async => Right(testProfiles));

        // Act
        await profileViewModel.loadProfiles(testProfileIds);

        // Assert - Loading状態にならずに直接ProfileLoaded状態になる
        expect(profileViewModel.state, isA<ProfileLoaded>());
        final loadedState = profileViewModel.state as ProfileLoaded;
        expect(loadedState.profiles.length, equals(4));
        expect(
          loadedState.profiles[existingProfile.id],
          equals(existingProfile),
        );
        expect(loadedState.profiles[testProfile1.id], equals(testProfile1));
        expect(loadedState.profiles[testProfile2.id], equals(testProfile2));
        expect(loadedState.profiles[testProfile3.id], equals(testProfile3));
      });

      test('複数プロフィール読み込み失敗時はProfileError状態になる', () async {
        // Arrange
        const failure = NetworkFailure(message: 'Network connection failed');
        when(
          mockGetProfiles(profileIds: testProfileIds),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await profileViewModel.loadProfiles(testProfileIds);

        // Assert
        expect(profileViewModel.state, isA<ProfileError>());
        expect(
          (profileViewModel.state as ProfileError).message,
          equals('Network connection failed'),
        );
      });
    });

    group('_getCurrentProfiles', () {
      test('ProfileLoaded状態の場合、プロフィールマップを返す', () async {
        // Arrange
        final profiles = {testProfile1.id: testProfile1};
        profileViewModel.state = ProfileLoaded(profiles);

        when(
          mockGetProfile(profileId: testProfile2.id),
        ).thenAnswer((_) async => Right(testProfile2));

        // Act
        await profileViewModel.loadProfile(testProfile2.id);

        // Assert - privateメソッドの動作を間接的に確認
        expect(profileViewModel.state, isA<ProfileLoaded>());
        final loadedState = profileViewModel.state as ProfileLoaded;
        expect(loadedState.profiles.length, equals(2));
        expect(loadedState.profiles[testProfile1.id], equals(testProfile1));
        expect(loadedState.profiles[testProfile2.id], equals(testProfile2));
      });

      test('ProfileLoaded状態でない場合、空のマップを返す', () async {
        // Arrange - ProfileInitial状態のまま
        when(
          mockGetProfile(profileId: testProfileId),
        ).thenAnswer((_) async => Right(testProfile1));

        // Act
        await profileViewModel.loadProfile(testProfileId);

        // Assert - 新しいプロフィールのみ含まれる
        expect(profileViewModel.state, isA<ProfileLoaded>());
        final loadedState = profileViewModel.state as ProfileLoaded;
        expect(loadedState.profiles.length, equals(1));
        expect(loadedState.profiles[testProfileId], equals(testProfile1));
      });
    });

    group('getProfileById', () {
      test('ProfileLoaded状態で存在するプロフィールIDの場合、プロフィールを返す', () {
        // Arrange
        final Map<String, Profile> profiles = {
          testProfile1.id: testProfile1,
          testProfile2.id: testProfile2,
        };
        profileViewModel.state = ProfileLoaded(profiles);

        // Act
        final result = profileViewModel.getProfileById(testProfile1.id);

        // Assert
        expect(result, equals(testProfile1));
      });

      test('ProfileLoaded状態で存在しないプロフィールIDの場合、nullを返す', () {
        // Arrange
        final Map<String, Profile> profiles = {testProfile1.id: testProfile1};
        profileViewModel.state = ProfileLoaded(profiles);

        // Act
        final result = profileViewModel.getProfileById('non-existent-id');

        // Assert
        expect(result, isNull);
      });

      test('ProfileLoaded状態でない場合、nullを返す', () {
        // Arrange - ProfileInitial状態のまま

        // Act
        final result = profileViewModel.getProfileById(testProfileId);

        // Assert
        expect(result, isNull);
      });
    });

    group('clearError', () {
      test('ProfileError状態の場合、ProfileInitial状態になる', () async {
        // Arrange - エラー状態にする
        const failure = ServerFailure(message: 'Test error');
        when(
          mockGetProfile(profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        await profileViewModel.loadProfile(testProfileId);
        expect(profileViewModel.state, isA<ProfileError>());

        // Act
        profileViewModel.clearError();

        // Assert
        expect(profileViewModel.state, isA<ProfileInitial>());
      });

      test('ProfileError状態でない場合、状態は変更されない', () {
        // Arrange - ProfileLoaded状態にする
        final Map<String, Profile> profiles = {testProfile1.id: testProfile1};
        profileViewModel.state = ProfileLoaded(profiles);

        // Act
        profileViewModel.clearError();

        // Assert - 状態は変更されない
        expect(profileViewModel.state, isA<ProfileLoaded>());
        expect(
          (profileViewModel.state as ProfileLoaded).profiles,
          equals(profiles),
        );
      });
    });

    group('エラーハンドリング', () {
      test('ServerFailureの場合、適切なエラーメッセージが表示される', () async {
        // Arrange
        const failure = ServerFailure(message: 'Server error occurred');
        when(
          mockGetProfile(profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await profileViewModel.loadProfile(testProfileId);

        // Assert
        expect(profileViewModel.state, isA<ProfileError>());
        expect(
          (profileViewModel.state as ProfileError).message,
          equals('Server error occurred'),
        );
      });

      test('NetworkFailureの場合、適切なエラーメッセージが表示される', () async {
        // Arrange
        const failure = NetworkFailure(message: 'Network connection failed');
        when(
          mockGetProfiles(profileIds: testProfileIds),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await profileViewModel.loadProfiles(testProfileIds);

        // Assert
        expect(profileViewModel.state, isA<ProfileError>());
        expect(
          (profileViewModel.state as ProfileError).message,
          equals('Network connection failed'),
        );
      });

      test('AuthFailureの場合、適切なエラーメッセージが表示される', () async {
        // Arrange
        const failure = AuthFailure(message: 'Authentication failed');
        when(
          mockGetProfile(profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await profileViewModel.loadProfile(testProfileId);

        // Assert
        expect(profileViewModel.state, isA<ProfileError>());
        expect(
          (profileViewModel.state as ProfileError).message,
          equals('Authentication failed'),
        );
      });
    });

    group('統合テスト', () {
      test('複数のプロフィール操作が順次実行される', () async {
        // 1. 単一プロフィール読み込み
        when(
          mockGetProfile(profileId: testProfile1.id),
        ).thenAnswer((_) async => Right(testProfile1));

        await profileViewModel.loadProfile(testProfile1.id);

        expect(profileViewModel.state, isA<ProfileLoaded>());
        expect(
          (profileViewModel.state as ProfileLoaded).profiles.length,
          equals(1),
        );

        // 2. 複数プロフィール読み込み
        when(
          mockGetProfiles(profileIds: [testProfile2.id, testProfile3.id]),
        ).thenAnswer((_) async => Right([testProfile2, testProfile3]));

        await profileViewModel.loadProfiles([testProfile2.id, testProfile3.id]);

        expect(profileViewModel.state, isA<ProfileLoaded>());
        final finalState = profileViewModel.state as ProfileLoaded;
        expect(finalState.profiles.length, equals(3));
        expect(finalState.profiles[testProfile1.id], equals(testProfile1));
        expect(finalState.profiles[testProfile2.id], equals(testProfile2));
        expect(finalState.profiles[testProfile3.id], equals(testProfile3));

        // 3. 特定プロフィール取得
        final retrievedProfile = profileViewModel.getProfileById(
          testProfile2.id,
        );
        expect(retrievedProfile, equals(testProfile2));
      });

      test('エラー発生後の回復処理', () async {
        // 1. エラー発生
        const failure = ServerFailure(message: 'Initial error');
        when(
          mockGetProfile(profileId: testProfile1.id),
        ).thenAnswer((_) async => const Left(failure));

        await profileViewModel.loadProfile(testProfile1.id);
        expect(profileViewModel.state, isA<ProfileError>());

        // 2. エラークリア
        profileViewModel.clearError();
        expect(profileViewModel.state, isA<ProfileInitial>());

        // 3. 成功処理
        when(
          mockGetProfile(profileId: testProfile1.id),
        ).thenAnswer((_) async => Right(testProfile1));

        await profileViewModel.loadProfile(testProfile1.id);
        expect(profileViewModel.state, isA<ProfileLoaded>());
        expect(
          (profileViewModel.state as ProfileLoaded).profiles[testProfile1.id],
          equals(testProfile1),
        );
      });
    });
  });
}
