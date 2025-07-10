import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/typedef.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// 認証リポジトリの実装
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  ResultFuture<User> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      final result = await remoteDataSource.signUp(
        email: email,
        password: password,
        username: username,
      );

      return Right(result.toEntity());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      final result = await remoteDataSource.signIn(
        email: email,
        password: password,
      );

      return Right(result.toEntity());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultVoid signOut() async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      await remoteDataSource.signOut();
      return const Right(null);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<User?> getCurrentUser() async {
    try {
      final result = await remoteDataSource.getCurrentUser();
      return Right(result?.toEntity());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return remoteDataSource.authStateChanges.map(
      (userModel) => userModel?.toEntity(),
    );
  }
}
