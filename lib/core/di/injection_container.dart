import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/network_info.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/send_message.dart';
import '../../features/chat/domain/usecases/get_messages.dart';
import '../../features/chat/domain/usecases/watch_messages.dart';
import '../../features/chat/domain/usecases/toggle_like.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/get_profiles.dart';

final getIt = GetIt.instance;

/// 依存性注入の設定
Future<void> setupDependencies() async {
  // Core
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // External
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt(), networkInfo: getIt()),
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: getIt(), networkInfo: getIt()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () =>
        ProfileRepositoryImpl(remoteDataSource: getIt(), networkInfo: getIt()),
  );

  // Use cases
  getIt.registerLazySingleton(() => SignUp(getIt()));
  getIt.registerLazySingleton(() => SignIn(getIt()));
  getIt.registerLazySingleton(() => SignOut(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUser(getIt()));
  getIt.registerLazySingleton(() => SendMessage(getIt()));
  getIt.registerLazySingleton(() => GetMessages(getIt()));
  getIt.registerLazySingleton(() => WatchMessages(getIt()));
  getIt.registerLazySingleton(() => ToggleLike(getIt()));
  getIt.registerLazySingleton(() => GetProfile(getIt()));
  getIt.registerLazySingleton(() => GetProfiles(getIt()));
}
