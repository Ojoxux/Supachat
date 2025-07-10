import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/message.dart';
import '../model/profile.dart';
import '../constants.dart';
import 'register_page.dart';

/// 他のユーザーとチャットができるページ
///
/// モダンな白と黒を基調としたシンプルなデザインのチャット画面
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const ChatPage());
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// メッセージをロードするためのストリーム
  late final Stream<List<Message>> _messagesStream;

  /// プロフィール情報をメモリー内にキャッシュしておくための変数
  final Map<String, Profile> _profileCache = {};

  /// メッセージのサブスクリプション
  late final StreamSubscription<List<Message>> _messagesSubscription;

  @override
  void initState() {
    final myUserId = supabase.auth.currentUser!.id;
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map(
          (maps) =>
              maps
                  .map((map) => Message.fromMap(map: map, myUserId: myUserId))
                  .toList(),
        );
    _messagesSubscription = _messagesStream.listen((messages) {
      for (final message in messages) {
        _loadProfileCache(message.profileId);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    // きちんとcancelしてメモリリークを防ぐ
    _messagesSubscription.cancel();
    super.dispose();
  }

  /// 特定のユーザーのプロフィール情報をロードしてキャッシュする
  Future<void> _loadProfileCache(String profileId) async {
    if (_profileCache[profileId] != null) {
      return;
    }
    final data =
        await supabase
            .from('profiles')
            .select('*')
            .eq('id', profileId)
            .single();
    final profile = Profile.fromMap(data);
    setState(() {
      _profileCache[profileId] = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              supabase.auth.signOut();
              Navigator.of(
                context,
              ).pushAndRemoveUntil(RegisterPage.route(), (route) => false);
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
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final messages = snapshot.data!;
                  return messages.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.black12,
                            ),
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
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final profile = _profileCache[message.profileId];
                          if (profile == null) {
                            return const SizedBox.shrink(); // プロフィールがロードされていない場合は空のウィジェットを返す
                          }
                          return ModernMessageCard(
                            message: message,
                            profile: profile,
                          );
                        },
                      );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      strokeWidth: 2,
                    ),
                  );
                }
              },
            ),
          ),
          // 区切り線
          Container(height: 1, color: Colors.grey[200]),
          const _ModernMessageBar(),
        ],
      ),
    );
  }
}

/// モダンなメッセージ入力バー
class _ModernMessageBar extends StatefulWidget {
  const _ModernMessageBar();

  @override
  State<_ModernMessageBar> createState() => _ModernMessageBarState();
}

class _ModernMessageBarState extends State<_ModernMessageBar> {
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
              onTap: _isComposing ? _submitMessage : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isComposing ? Colors.black : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: _isComposing ? Colors.white : Colors.grey[600],
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
    final myUserId = supabase.auth.currentUser!.id;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content': text,
      });
    } on PostgrestException catch (error) {
      if (mounted) context.showErrorSnackBar(message: error.message);
    } catch (_) {
      if (mounted) context.showErrorSnackBar(message: unexpectedErrorMessage);
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
