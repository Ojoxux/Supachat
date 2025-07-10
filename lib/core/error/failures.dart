import 'package:equatable/equatable.dart';

/// アプリケーション全体で使用するFailureの基底クラス
abstract class Failure extends Equatable {
  const Failure([List<dynamic> properties = const <dynamic>[]]);

  @override
  List<Object> get props => [];
}

/// サーバーエラー
class ServerFailure extends Failure {
  const ServerFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

/// ネットワークエラー
class NetworkFailure extends Failure {
  const NetworkFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

/// 認証エラー
class AuthFailure extends Failure {
  const AuthFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

/// バリデーションエラー
class ValidationFailure extends Failure {
  const ValidationFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

/// キャッシュエラー
class CacheFailure extends Failure {
  const CacheFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}
