import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/auth_state.dart';
import 'register_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';

/// ログイン状態に応じてユーザーをリダイレクトするページ
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // AuthViewModelは初期化時に自動的に認証状態をチェックする
  }

  @override
  Widget build(BuildContext context) {
    // AuthViewModelの状態を監視
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      // 状態変化時のナビゲーション処理
      if (next is AuthAuthenticated) {
        // 認証済みの場合はチャットページへ
        Navigator.of(
          context,
        ).pushAndRemoveUntil(ChatPage.route(), (route) => false);
      } else if (next is AuthUnauthenticated) {
        // 未認証の場合は登録ページへ
        Navigator.of(
          context,
        ).pushAndRemoveUntil(RegisterPage.route(), (route) => false);
      } else if (next is AuthError) {
        // エラーの場合も登録ページへ
        Navigator.of(
          context,
        ).pushAndRemoveUntil(RegisterPage.route(), (route) => false);
      }
    });

    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アプリロゴ
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),

            // アプリ名
            const Text(
              'Supachat',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // 状態に応じたメッセージ
            Text(
              _getStatusMessage(authState),
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),

            // ローディングインジケーター
            if (authState is AuthLoading) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                strokeWidth: 2,
              ),
            ],

            // エラー時の再試行ボタン
            if (authState is AuthError) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(authViewModelProvider.notifier).checkAuthStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusMessage(AuthState state) {
    switch (state.runtimeType) {
      case AuthLoading _:
        return '認証状態を確認中...';
      case AuthError _:
        return 'エラーが発生しました';
      default:
        return 'アプリを初期化中...';
    }
  }
}
