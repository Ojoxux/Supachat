import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:flutter_and_supabase_chat_app/core/error/failures.dart';
import 'package:flutter_and_supabase_chat_app/features/auth/domain/entities/user.dart';
import 'package:flutter_and_supabase_chat_app/features/auth/domain/usecases/sign_up.dart';
import 'package:flutter_and_supabase_chat_app/features/auth/domain/usecases/sign_in.dart';
import 'package:flutter_and_supabase_chat_app/features/auth/domain/usecases/sign_out.dart';
import 'package:flutter_and_supabase_chat_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_and_supabase_chat_app/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter_and_supabase_chat_app/features/auth/presentation/viewmodels/auth_state.dart';

import 'auth_viewmodel_test.mocks.dart';

// Mockitoを使用してモックを生成
@GenerateMocks([SignUp, SignIn, SignOut, GetCurrentUser])
void main() {
  group('AuthViewModel', () {
    late AuthViewModel authViewModel;
    late MockSignUp mockSignUp;
    late MockSignIn mockSignIn;
    late MockSignOut mockSignOut;
    late MockGetCurrentUser mockGetCurrentUser;
    late User testUser;

    // テスト用のダミーデータ

    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUsername = 'testuser';

    setUp(() {
      mockSignUp = MockSignUp();
      mockSignIn = MockSignIn();
      mockSignOut = MockSignOut();
      mockGetCurrentUser = MockGetCurrentUser();

      // テスト用のダミーデータを初期化
      testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        username: 'testuser',
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      // GetCurrentUserのデフォルト動作を設定（初期化時に呼ばれる）
      when(mockGetCurrentUser()).thenAnswer((_) async => const Right(null));

      authViewModel = AuthViewModel(
        signUp: mockSignUp,
        signIn: mockSignIn,
        signOut: mockSignOut,
        getCurrentUser: mockGetCurrentUser,
      );
    });

    group('初期化', () {
      test('初期状態はAuthInitialであるが、すぐにcheckAuthStatusが呼ばれる', () async {
        // GetCurrentUserをモックして初期化を制御
        when(mockGetCurrentUser()).thenAnswer((_) async => const Right(null));

        final viewModel = AuthViewModel(
          signUp: mockSignUp,
          signIn: mockSignIn,
          signOut: mockSignOut,
          getCurrentUser: mockGetCurrentUser,
        );

        // 初期状態はAuthInitialまたはAuthLoading
        expect(viewModel.state, anyOf(isA<AuthInitial>(), isA<AuthLoading>()));

        // 少し待ってから最終状態を確認
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(viewModel.state, isA<AuthUnauthenticated>());
      });

      test('初期化時にcheckAuthStatusが呼ばれる', () async {
        // 少し待ってからverify
        await Future<void>.delayed(Duration.zero);
        verify(mockGetCurrentUser()).called(1);
      });
    });

    group('checkAuthStatus', () {
      test('ユーザーが存在する場合、AuthAuthenticated状態になる', () async {
        // Arrange
        when(mockGetCurrentUser()).thenAnswer((_) async => Right(testUser));

        // Act
        await authViewModel.checkAuthStatus();

        // Assert
        expect(authViewModel.state, isA<AuthAuthenticated>());
        expect(
          (authViewModel.state as AuthAuthenticated).user,
          equals(testUser),
        );
      });

      test('ユーザーが存在しない場合、AuthUnauthenticated状態になる', () async {
        // Arrange
        when(mockGetCurrentUser()).thenAnswer((_) async => const Right(null));

        // Act
        await authViewModel.checkAuthStatus();

        // Assert
        expect(authViewModel.state, isA<AuthUnauthenticated>());
      });

      test('エラーが発生した場合、AuthError状態になる', () async {
        // Arrange
        const failure = AuthFailure(message: 'Authentication failed');
        when(mockGetCurrentUser()).thenAnswer((_) async => const Left(failure));

        // Act
        await authViewModel.checkAuthStatus();

        // Assert
        expect(authViewModel.state, isA<AuthError>());
        expect(
          (authViewModel.state as AuthError).message,
          equals('Authentication failed'),
        );
      });

      test('実行中はAuthLoading状態になる', () async {
        // Arrange
        when(mockGetCurrentUser()).thenAnswer((_) async {
          // ローディング状態を確認するため少し遅延
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return Right(testUser);
        });

        // Act
        final future = authViewModel.checkAuthStatus();

        // Assert - 実行中はローディング状態
        expect(authViewModel.state, isA<AuthLoading>());

        // 完了を待つ
        await future;
        expect(authViewModel.state, isA<AuthAuthenticated>());
      });
    });

    group('signUpUser', () {
      test('成功した場合、AuthAuthenticated状態になる', () async {
        // Arrange
        when(
          mockSignUp(
            email: testEmail,
            password: testPassword,
            username: testUsername,
          ),
        ).thenAnswer((_) async => Right(testUser));

        // Act
        await authViewModel.signUpUser(
          email: testEmail,
          password: testPassword,
          username: testUsername,
        );

        // Assert
        expect(authViewModel.state, isA<AuthAuthenticated>());
        expect(
          (authViewModel.state as AuthAuthenticated).user,
          equals(testUser),
        );
      });

      test('失敗した場合、AuthError状態になる', () async {
        // Arrange
        const failure = AuthFailure(message: 'Sign up failed');
        when(
          mockSignUp(
            email: testEmail,
            password: testPassword,
            username: testUsername,
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await authViewModel.signUpUser(
          email: testEmail,
          password: testPassword,
          username: testUsername,
        );

        // Assert
        expect(authViewModel.state, isA<AuthError>());
        expect(
          (authViewModel.state as AuthError).message,
          equals('Sign up failed'),
        );
      });

      test('実行中はAuthLoading状態になる', () async {
        // Arrange
        when(
          mockSignUp(
            email: testEmail,
            password: testPassword,
            username: testUsername,
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return Right(testUser);
        });

        // Act
        final future = authViewModel.signUpUser(
          email: testEmail,
          password: testPassword,
          username: testUsername,
        );

        // Assert - 実行中はローディング状態
        expect(authViewModel.state, isA<AuthLoading>());

        // 完了を待つ
        await future;
        expect(authViewModel.state, isA<AuthAuthenticated>());
      });
    });

    group('signInUser', () {
      test('成功した場合、AuthAuthenticated状態になる', () async {
        // Arrange
        when(
          mockSignIn(email: testEmail, password: testPassword),
        ).thenAnswer((_) async => Right(testUser));

        // Act
        await authViewModel.signInUser(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(authViewModel.state, isA<AuthAuthenticated>());
        expect(
          (authViewModel.state as AuthAuthenticated).user,
          equals(testUser),
        );
      });

      test('失敗した場合、AuthError状態になる', () async {
        // Arrange
        const failure = AuthFailure(message: 'Sign in failed');
        when(
          mockSignIn(email: testEmail, password: testPassword),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await authViewModel.signInUser(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(authViewModel.state, isA<AuthError>());
        expect(
          (authViewModel.state as AuthError).message,
          equals('Sign in failed'),
        );
      });

      test('実行中はAuthLoading状態になる', () async {
        // Arrange
        when(mockSignIn(email: testEmail, password: testPassword)).thenAnswer((
          _,
        ) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return Right(testUser);
        });

        // Act
        final future = authViewModel.signInUser(
          email: testEmail,
          password: testPassword,
        );

        // Assert - 実行中はローディング状態
        expect(authViewModel.state, isA<AuthLoading>());

        // 完了を待つ
        await future;
        expect(authViewModel.state, isA<AuthAuthenticated>());
      });
    });

    group('signOutUser', () {
      test('成功した場合、AuthUnauthenticated状態になる', () async {
        // Arrange
        when(mockSignOut()).thenAnswer((_) async => const Right(null));

        // Act
        await authViewModel.signOutUser();

        // Assert
        expect(authViewModel.state, isA<AuthUnauthenticated>());
      });

      test('失敗した場合、AuthError状態になる', () async {
        // Arrange
        const failure = AuthFailure(message: 'Sign out failed');
        when(mockSignOut()).thenAnswer((_) async => const Left(failure));

        // Act
        await authViewModel.signOutUser();

        // Assert
        expect(authViewModel.state, isA<AuthError>());
        expect(
          (authViewModel.state as AuthError).message,
          equals('Sign out failed'),
        );
      });

      test('実行中はAuthLoading状態になる', () async {
        // Arrange
        when(mockSignOut()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const Right(null);
        });

        // Act
        final future = authViewModel.signOutUser();

        // Assert - 実行中はローディング状態
        expect(authViewModel.state, isA<AuthLoading>());

        // 完了を待つ
        await future;
        expect(authViewModel.state, isA<AuthUnauthenticated>());
      });
    });

    group('clearError', () {
      test('AuthError状態の場合、AuthUnauthenticated状態になる', () async {
        // Arrange - エラー状態にする
        const failure = AuthFailure(message: 'Test error');
        when(
          mockSignIn(email: testEmail, password: testPassword),
        ).thenAnswer((_) async => const Left(failure));

        await authViewModel.signInUser(
          email: testEmail,
          password: testPassword,
        );

        expect(authViewModel.state, isA<AuthError>());

        // Act
        authViewModel.clearError();

        // Assert
        expect(authViewModel.state, isA<AuthUnauthenticated>());
      });

      test('AuthError状態でない場合、状態は変更されない', () async {
        // Arrange - 認証済み状態にする
        when(
          mockSignIn(email: testEmail, password: testPassword),
        ).thenAnswer((_) async => Right(testUser));

        await authViewModel.signInUser(
          email: testEmail,
          password: testPassword,
        );

        expect(authViewModel.state, isA<AuthAuthenticated>());

        // Act
        authViewModel.clearError();

        // Assert - 状態は変更されない
        expect(authViewModel.state, isA<AuthAuthenticated>());
      });
    });

    group('エラーハンドリング', () {
      test('ServerFailureの場合、適切なエラーメッセージが表示される', () async {
        // Arrange
        const failure = ServerFailure(message: 'Server error occurred');
        when(
          mockSignIn(email: testEmail, password: testPassword),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await authViewModel.signInUser(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(authViewModel.state, isA<AuthError>());
        expect(
          (authViewModel.state as AuthError).message,
          equals('Server error occurred'),
        );
      });

      test('NetworkFailureの場合、適切なエラーメッセージが表示される', () async {
        // Arrange
        const failure = NetworkFailure(message: 'Network connection failed');
        when(
          mockSignIn(email: testEmail, password: testPassword),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await authViewModel.signInUser(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(authViewModel.state, isA<AuthError>());
        expect(
          (authViewModel.state as AuthError).message,
          equals('Network connection failed'),
        );
      });
    });
  });
}
