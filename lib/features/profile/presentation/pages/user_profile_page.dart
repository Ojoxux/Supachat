import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../domain/entities/profile.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/profile_state.dart';

/// 他のユーザーのプロフィール画面
class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.profileId});

  final String profileId;

  static Route<void> route(String profileId) {
    return MaterialPageRoute<void>(
      builder: (_) => UserProfilePage(profileId: profileId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);

    // プロフィール情報をロード
    ref.listen(profileViewModelProvider, (previous, next) {
      if (next is ProfileLoaded && !next.profiles.containsKey(profileId)) {
        ref.read(profileViewModelProvider.notifier).loadProfile(profileId);
      }
    });

    // 初回ロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profileState is ProfileLoaded &&
          !profileState.profiles.containsKey(profileId)) {
        ref.read(profileViewModelProvider.notifier).loadProfile(profileId);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: const Text(
          'プロフィール',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(context, profileState),
    );
  }

  Widget _buildBody(BuildContext context, ProfileState profileState) {
    if (profileState is ProfileLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          strokeWidth: 2,
        ),
      );
    }

    if (profileState is ProfileError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profileState.message,
              style: const TextStyle(fontSize: 14, color: Colors.black38),
            ),
          ],
        ),
      );
    }

    if (profileState is ProfileLoaded) {
      final profile = profileState.profiles[profileId];
      if (profile == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'プロフィールを読み込み中...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return _buildProfileContent(profile);
    }

    return const SizedBox.shrink();
  }

  Widget _buildProfileContent(Profile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // プロフィール画像
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                profile.username
                    .substring(0, profile.username.length >= 2 ? 2 : 1)
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ユーザー名
          Text(
            profile.username,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),

          // プロフィール情報カード
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ユーザー情報',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('ユーザー名', profile.username),
                const SizedBox(height: 12),
                _buildInfoRow(
                  '作成日',
                  timeago.format(profile.createdAt, locale: 'ja'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
