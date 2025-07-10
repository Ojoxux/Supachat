import 'package:equatable/equatable.dart';

/// アプリケーション全体で使用するFailureの基底クラス
abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);

  @override
  List<Object> get props => [];
}

/// サーバーエラー
class ServerFailure extends Failure {
  final String message;

  const ServerFailure({required this.message});

  @override
  List<Object> get props => [message];
}

/// ネットワークエラー
class NetworkFailure extends Failure {
  final String message;

  const NetworkFailure({required this.message});

  @override
  List<Object> get props => [message];
}

/// 認証エラー
class AuthFailure extends Failure {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}

/// バリデーションエラー
class ValidationFailure extends Failure {
  final String message;

  const ValidationFailure({required this.message});

  @override
  List<Object> get props => [message];
}

/// キャッシュエラー
class CacheFailure extends Failure {
  final String message;

  const CacheFailure({required this.message});

  @override
  List<Object> get props => [message];
}
