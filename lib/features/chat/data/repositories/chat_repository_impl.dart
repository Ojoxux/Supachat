import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/typedef.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

/// チャットリポジトリの実装
class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ChatRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  ResultVoid sendMessage({
    required String content,
    required String profileId,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      await remoteDataSource.sendMessage(
        content: content,
        profileId: profileId,
      );

      return const Right(null);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<List<Message>> getMessages({
    required String currentUserId,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      final result = await remoteDataSource.getMessages(
        currentUserId: currentUserId,
      );

      return Right(result.map((model) => model.toEntity()).toList());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Message>> watchMessages({required String currentUserId}) {
    return remoteDataSource
        .watchMessages(currentUserId: currentUserId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  ResultVoid toggleLike({
    required String messageId,
    required String userId,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      await remoteDataSource.toggleLike(messageId: messageId, userId: userId);

      return const Right(null);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultVoid editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'ネットワークに接続されていません'));
      }

      await remoteDataSource.editMessage(
        messageId: messageId,
        newContent: newContent,
      );

      return const Right(null);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
