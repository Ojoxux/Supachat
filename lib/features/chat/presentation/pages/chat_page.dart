import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart';

import '../../../../constants.dart';
import '../../domain/entities/message.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../profile/presentation/viewmodels/profile_state.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/chat_state.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';

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
  final ScrollController _scrollController = ScrollController();
  int _previousMessageCount = 0;
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    // スクロールリスナーを追加
    _scrollController.addListener(_onScroll);
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

  /// スクロール位置を監視して自動スクロールの有効/無効を切り替え
  void _onScroll() {
    if (_scrollController.hasClients) {
      final isAtBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100;
      if (_shouldAutoScroll != isAtBottom) {
        setState(() {
          _shouldAutoScroll = isAtBottom;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 一番下までスクロール
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () {
              Navigator.of(context).push(ProfilePage.route());
            },
            icon: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
        title: const Text(
          'チャット',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
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

      // 新しいメッセージが追加されたときのみ自動スクロール
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (messages.length > _previousMessageCount && _shouldAutoScroll) {
          _scrollToBottom();
        }
        _previousMessageCount = messages.length;
      });

      return AnimatedList(
        controller: _scrollController,
        reverse: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        initialItemCount: messages.length,
        itemBuilder: (context, index, animation) {
          if (index >= messages.length) return const SizedBox();

          final message = messages[messages.length - 1 - index];

          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOut)),
            ),
            child: FadeTransition(
              opacity: animation,
              child: Consumer(
                builder: (context, ref, child) {
                  final profileState = ref.watch(profileViewModelProvider);

                  if (profileState is ProfileLoaded) {
                    final profile = profileState.profiles[message.profileId];

                    if (profile == null) {
                      // プロフィールがロードされていない場合は、プロフィールを取得
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref
                            .read(profileViewModelProvider.notifier)
                            .loadProfile(message.profileId);
                      });
                      // 一時的なプロフィール情報で表示
                      return ModernMessageCard(
                        message: message,
                        profile: Profile(
                          id: message.profileId,
                          username: 'Loading...',
                          createdAt: DateTime.now(),
                          messageCount: 0,
                        ),
                      );
                    }

                    return ModernMessageCard(
                      message: message,
                      profile: profile,
                    );
                  }

                  // プロフィール情報をロード中の場合も一時的な情報で表示
                  return ModernMessageCard(
                    message: message,
                    profile: Profile(
                      id: message.profileId,
                      username: 'Loading...',
                      createdAt: DateTime.now(),
                      messageCount: 0,
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

/// いいねボタンウィジェット
class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.message, required this.alignment});

  final Message message;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        GestureDetector(
          onTap: () {
            final currentUserId = supabase.auth.currentUser?.id;
            if (currentUserId != null) {
              ref
                  .read(chatViewModelProvider.notifier)
                  .toggleLikeAction(
                    messageId: message.id,
                    userId: currentUserId,
                  );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: message.isLikedByMe ? Colors.pink : Colors.grey[600],
                ),
                if (message.likeCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    message.likeCount.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
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
    final isSending = chatState is ChatSending;

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

    // メッセージ送信時のアニメーション
    // ignore: unawaited_futures
    HapticFeedback.lightImpact();

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      await ref
          .read(chatViewModelProvider.notifier)
          .sendMessageAction(content: text, profileId: currentUserId);

      // メッセージ送信後に一番下までスクロール
      // ignore: unawaited_futures
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 親のスクロールコントローラーにアクセスするため、contextを使用
        final chatPageState = context.findAncestorStateOfType<_ChatPageState>();
        if (chatPageState != null) {
          chatPageState._shouldAutoScroll = true;
          chatPageState._scrollToBottom();
        }
      });
    }
  }
}

/// モダンなメッセージカード
class ModernMessageCard extends ConsumerStatefulWidget {
  const ModernMessageCard({
    super.key,
    required this.message,
    required this.profile,
  });

  final Message message;
  final Profile profile;

  @override
  ConsumerState<ModernMessageCard> createState() => _ModernMessageCardState();
}

class _ModernMessageCardState extends ConsumerState<ModernMessageCard>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late TextEditingController _editController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.02, 0),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _editController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _startEditing();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.pencil, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '編集',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  Clipboard.setData(
                    ClipboardData(text: widget.message.content),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('メッセージをコピーしました'),
                      backgroundColor: Colors.black87,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.doc_on_doc,
                      color: Colors.black,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'コピー',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: const Text(
                'キャンセル',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
    );
  }

  void _startEditing() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isEditing = true;
      _editController.text = widget.message.content;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.message.content;
    });
  }

  void _saveEdit() {
    if (_editController.text.trim().isNotEmpty) {
      ref
          .read(chatViewModelProvider.notifier)
          .editMessageAction(
            messageId: widget.message.id,
            newContent: _editController.text.trim(),
          );
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      widget.message.isMine
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
                                        format(
                                          widget.message.createdAt,
                                          locale: 'en_short',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black38,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.profile.username,
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
                                  GestureDetector(
                                    onLongPress:
                                        widget.message.isMine
                                            ? () {
                                              _showContextMenu(context);
                                            }
                                            : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child:
                                          _isEditing
                                              ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  TextField(
                                                    controller: _editController,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                      height: 1.4,
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                          border:
                                                              InputBorder.none,
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.zero,
                                                        ),
                                                    maxLines: null,
                                                    autofocus: true,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: _cancelEditing,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .grey[300],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: const Text(
                                                            'キャンセル',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: _saveEdit,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: const Text(
                                                            '保存',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              )
                                              : Text(
                                                widget.message.content,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                  height: 1.4,
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // いいねボタン（自分のメッセージ用）
                                  _LikeButton(
                                    message: widget.message,
                                    alignment: MainAxisAlignment.end,
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
                                  widget.profile.username
                                      .substring(
                                        0,
                                        min(2, widget.profile.username.length),
                                      )
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
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  UserProfilePage.route(widget.profile.id),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.profile.username
                                        .substring(
                                          0,
                                          min(
                                            2,
                                            widget.profile.username.length,
                                          ),
                                        )
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                        widget.profile.username,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        format(
                                          widget.message.createdAt,
                                          locale: 'en_short',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // メッセージテキスト
                                  GestureDetector(
                                    onLongPress:
                                        widget.message.isMine
                                            ? () {
                                              _showContextMenu(context);
                                            }
                                            : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child:
                                          _isEditing && widget.message.isMine
                                              ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  TextField(
                                                    controller: _editController,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.black87,
                                                      height: 1.4,
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                          border:
                                                              InputBorder.none,
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.zero,
                                                        ),
                                                    maxLines: null,
                                                    autofocus: true,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: _cancelEditing,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .grey[400],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: const Text(
                                                            'キャンセル',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: _saveEdit,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .blue[600],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: const Text(
                                                            '保存',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              )
                                              : Text(
                                                widget.message.content,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                  height: 1.4,
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // いいねボタン（他のユーザーのメッセージ用）
                                  _LikeButton(
                                    message: widget.message,
                                    alignment: MainAxisAlignment.start,
                                  ),
                                ],
                              ),
                            ),
                          ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
