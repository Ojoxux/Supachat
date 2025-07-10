import 'package:equatable/equatable.dart';
import '../../domain/entities/profile.dart';

/// プロフィール状態の基底クラス
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// ローディング状態
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// プロフィール読み込み済み状態
class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profiles);

  final Map<String, Profile> profiles;

  @override
  List<Object?> get props => [profiles];
}

/// エラー状態
class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
