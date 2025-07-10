import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart';

import '../../../../constants.dart';
import '../../domain/entities/message.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../profile/presentation/viewmodels/profile_state.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/chat_state.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/pages/register_page.dart';

/// 他のユーザーとチャットができるページ
///
/// モダンな白と黒を基調としたシンプルなデザインのチャット画面
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const ChatPage());
  }

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    // ChatViewModelを初期化してメッセージの監視を開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        ref
            .read(chatViewModelProvider.notifier)
            .startWatchingMessages(currentUserId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'チャット',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
              if (context.mounted) {
                unawaited(
                  Navigator.of(
                    context,
                  ).pushAndRemoveUntil(RegisterPage.route(), (route) => false),
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.black54, size: 20),
            label: const Text(
              'ログアウト',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 区切り線
          Container(height: 1, color: Colors.grey[200]),
          // メッセージリスト
          Expanded(child: _buildMessagesList(chatState)),
          // 区切り線
          Container(height: 1, color: Colors.grey[200]),
          const _ModernMessageBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatState chatState) {
    if (chatState is ChatLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          strokeWidth: 2,
        ),
      );
    }

    if (chatState is ChatError) {
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
              chatState.message,
              style: const TextStyle(fontSize: 14, color: Colors.black38),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final currentUserId = supabase.auth.currentUser?.id;
                if (currentUserId != null) {
                  ref
                      .read(chatViewModelProvider.notifier)
                      .startWatchingMessages(currentUserId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (chatState is ChatLoaded) {
      final messages = chatState.messages;

      if (messages.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.black12),
              SizedBox(height: 16),
              Text(
                'メッセージがありません',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '最初のメッセージを送信してみましょう',
                style: TextStyle(fontSize: 14, color: Colors.black38),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Consumer(
            builder: (context, ref, child) {
              final profileState = ref.watch(profileViewModelProvider);

              if (profileState is ProfileLoaded) {
                final profile = profileState.profiles[message.profileId];

                if (profile == null) {
                  // プロフィールがロードされていない場合は空のウィジェットを返す
                  return const SizedBox.shrink();
                }

                return ModernMessageCard(message: message, profile: profile);
              }

              return const SizedBox.shrink();
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

/// モダンなメッセージ入力バー
class _ModernMessageBar extends ConsumerStatefulWidget {
  const _ModernMessageBar();

  @override
  ConsumerState<_ModernMessageBar> createState() => _ModernMessageBarState();
}

class _ModernMessageBarState extends ConsumerState<_ModernMessageBar> {
  late final TextEditingController _textController = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _isComposing = _textController.text.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);
    final isSending = chatState is ChatLoading;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitMessage(),
                  enabled: !isSending,
                  decoration: const InputDecoration(
                    hintText: 'メッセージを入力...',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: (_isComposing && !isSending) ? _submitMessage : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      (_isComposing && !isSending)
                          ? Colors.black
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child:
                    isSending
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Icon(
                          Icons.send,
                          color:
                              (_isComposing && !isSending)
                                  ? Colors.white
                                  : Colors.grey[600],
                          size: 20,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// メッセージを送信する
  void _submitMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _textController.clear();
    setState(() {
      _isComposing = false;
    });

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      await ref
          .read(chatViewModelProvider.notifier)
          .sendMessageAction(content: text, profileId: currentUserId);
    }
  }
}

/// モダンなメッセージカード
class ModernMessageCard extends StatelessWidget {
  const ModernMessageCard({
    super.key,
    required this.message,
    required this.profile,
  });

  final Message message;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            message.isMine
                ? [
                  // 自分のメッセージは右揃え
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ユーザー名と時間
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              format(message.createdAt, locale: 'en_short'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black38,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profile.username,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // メッセージテキスト
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.content,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // アバター
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.username
                            .substring(0, min(2, profile.username.length))
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ]
                : [
                  // 他のユーザーのメッセージは左揃え
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.username
                            .substring(0, min(2, profile.username.length))
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // メッセージ内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ユーザー名と時間
                        Row(
                          children: [
                            Text(
                              profile.username,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              format(message.createdAt, locale: 'en_short'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // メッセージテキスト
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.content,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
      ),
    );
  }
}
