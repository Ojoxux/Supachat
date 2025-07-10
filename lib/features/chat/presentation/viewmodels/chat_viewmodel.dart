import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/error_utils.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/watch_messages.dart';
import 'chat_state.dart';

/// チャットViewModelのProvider
final chatViewModelProvider = StateNotifierProvider<ChatViewModel, ChatState>(
  (ref) => ChatViewModel(
    sendMessage: getIt<SendMessage>(),
    getMessages: getIt<GetMessages>(),
    watchMessages: getIt<WatchMessages>(),
  ),
);

/// チャットViewModel
class ChatViewModel extends StateNotifier<ChatState> {
  ChatViewModel({
    required this.sendMessage,
    required this.getMessages,
    required this.watchMessages,
  }) : super(const ChatInitial());

  final SendMessage sendMessage;
  final GetMessages getMessages;
  final WatchMessages watchMessages;

  StreamSubscription<List<Message>>? _messagesSubscription;

  /// メッセージの監視を開始
  void startWatchingMessages(String currentUserId) {
    state = const ChatLoading();

    _messagesSubscription?.cancel();
    _messagesSubscription = watchMessages(currentUserId: currentUserId).listen(
      (messages) {
        state = ChatLoaded(messages);
      },
      onError: (Object error) {
        state = ChatError(
          'メッセージの取得に失敗しました: $error',
          messages: _getCurrentMessages(),
        );
      },
    );
  }

  /// メッセージを送信
  Future<void> sendMessageAction({
    required String content,
    required String profileId,
  }) async {
    if (content.trim().isEmpty) return;

    // 送信中状態に変更
    state = ChatSending(_getCurrentMessages());

    final result = await sendMessage(content: content, profileId: profileId);

    result.fold(
      (failure) {
        state = ChatError(
          getErrorMessage(failure),
          messages: _getCurrentMessages(),
        );
      },
      (_) {
        // メッセージ送信成功時は何もしない
        // リアルタイム更新で新しいメッセージが自動的に追加される
      },
    );
  }

  /// 現在のメッセージリストを取得
  List<Message> _getCurrentMessages() {
    final currentState = state;
    if (currentState is ChatLoaded) {
      return currentState.messages;
    } else if (currentState is ChatSending) {
      return currentState.messages;
    } else if (currentState is ChatError) {
      return currentState.messages;
    }
    return [];
  }

  /// エラーをクリア
  void clearError() {
    if (state is ChatError) {
      final errorState = state as ChatError;
      state = ChatLoaded(errorState.messages);
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
