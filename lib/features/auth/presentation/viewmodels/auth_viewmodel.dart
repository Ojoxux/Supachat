import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/error_utils.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_current_user.dart';
import 'auth_state.dart';

/// 認証ViewModelのProvider
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(
    signUp: getIt<SignUp>(),
    signIn: getIt<SignIn>(),
    signOut: getIt<SignOut>(),
    getCurrentUser: getIt<GetCurrentUser>(),
  ),
);

/// 認証ViewModel
class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel({
    required this.signUp,
    required this.signIn,
    required this.signOut,
    required this.getCurrentUser,
  }) : super(const AuthInitial()) {
    checkAuthStatus();
  }

  final SignUp signUp;
  final SignIn signIn;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;

  /// 認証状態をチェック
  Future<void> checkAuthStatus() async {
    state = const AuthLoading();

    final result = await getCurrentUser();

    result.fold((failure) => state = AuthError(getErrorMessage(failure)), (
      user,
    ) {
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    });
  }

  /// ユーザー登録
  Future<void> signUpUser({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AuthLoading();

    final result = await signUp(
      email: email,
      password: password,
      username: username,
    );

    result.fold(
      (failure) => state = AuthError(getErrorMessage(failure)),
      (user) => state = AuthAuthenticated(user),
    );
  }

  /// ログイン
  Future<void> signInUser({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    final result = await signIn(email: email, password: password);

    result.fold(
      (failure) => state = AuthError(getErrorMessage(failure)),
      (user) => state = AuthAuthenticated(user),
    );
  }

  /// ログアウト
  Future<void> signOutUser() async {
    state = const AuthLoading();

    final result = await signOut();

    result.fold(
      (failure) => state = AuthError(getErrorMessage(failure)),
      (_) => state = const AuthUnauthenticated(),
    );
  }

  /// エラーをクリア
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}
