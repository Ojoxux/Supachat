import '../error/failures.dart';

/// Failureからエラーメッセージを取得するヘルパー関数
String getErrorMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure _:
      return (failure as ServerFailure).message;
    case NetworkFailure _:
      return (failure as NetworkFailure).message;
    case AuthFailure _:
      return (failure as AuthFailure).message;
    case ValidationFailure _:
      return (failure as ValidationFailure).message;
    case CacheFailure _:
      return (failure as CacheFailure).message;
    default:
      return '予期せぬエラーが発生しました';
  }
}
