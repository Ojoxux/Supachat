import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/viewmodels/auth_state.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/profile_state.dart';

/// プロフィール画面
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ProfilePage());
  }

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // 現在のユーザーのプロフィールを取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authViewModelProvider);
      if (authState is AuthAuthenticated) {
        ref
            .read(profileViewModelProvider.notifier)
            .loadProfile(authState.user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final profileState = ref.watch(profileViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
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
      body: _buildBody(authState, profileState),
    );
  }

  Widget _buildBody(AuthState authState, ProfileState profileState) {
    if (authState is! AuthAuthenticated) {
      return const Center(
        child: Text(
          'ログインが必要です',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (profileState is ProfileLoading) {
      return preloader;
    }

    if (profileState is ProfileError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profileState.message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(profileViewModelProvider.notifier)
                    .loadProfile(authState.user.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (profileState is ProfileLoaded) {
      final profile = profileState.profiles[authState.user.id];
      if (profile == null) {
        return const Center(
          child: Text(
            'プロフィールが見つかりません',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // プロフィール画像
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
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
            const SizedBox(height: 8),

            // メールアドレス
            Text(
              authState.user.email,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                    'アカウント情報',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('ユーザーID', authState.user.id),
                  const SizedBox(height: 12),
                  _buildInfoRow('登録日', _formatDate(authState.user.createdAt)),
                  const SizedBox(height: 12),
                  _buildInfoRow('メッセージ投稿数', '${profile.messageCount}件'),
                  const SizedBox(height: 12),
                  _buildInfoRow('作成日', _formatDate(profile.createdAt)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ログアウトボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await ref.read(authViewModelProvider.notifier).signOutUser();
                  if (context.mounted) {
                    navigator.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red[200]!),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ログアウト',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Text(
        'プロフィールを読み込み中...',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
