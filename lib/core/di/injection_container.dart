import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/network_info.dart';

final getIt = GetIt.instance;

/// 依存性注入の設定
Future<void> setupDependencies() async {
  // Core
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // External
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
}
