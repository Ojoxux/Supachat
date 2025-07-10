import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// 認証状態の基底クラス
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// ローディング状態
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// 認証済み状態
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

/// 未認証状態
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// エラー状態
class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
