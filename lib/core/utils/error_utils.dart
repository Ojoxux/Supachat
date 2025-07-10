import '../error/failures.dart';

/// Failureからエラーメッセージを取得するヘルパー関数
String getErrorMessage(Failure failure) {
  switch (failure) {
    case ServerFailure():
      return failure.message;
    case NetworkFailure():
      return failure.message;
    case AuthFailure():
      return failure.message;
    case ValidationFailure():
      return failure.message;
    case CacheFailure():
      return failure.message;
    default:
      return '予期せぬエラーが発生しました';
  }
}
