import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/typedef.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// プロフィールリポジトリの実装
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ProfileRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  ResultFuture<Profile> getProfile({required String profileId}) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      final result = await remoteDataSource.getProfile(profileId: profileId);
      return Right(result.toEntity());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<List<Profile>> getProfiles({
    required List<String> profileIds,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      final result = await remoteDataSource.getProfiles(profileIds: profileIds);
      return Right(result.map((model) => model.toEntity()).toList());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultVoid updateProfile({
    required String profileId,
    required String username,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      await remoteDataSource.updateProfile(
        profileId: profileId,
        username: username,
      );
      return const Right(null);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
