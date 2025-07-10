import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';

/// チャット状態の基底クラス
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// ローディング状態
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// メッセージ読み込み済み状態
class ChatLoaded extends ChatState {
  const ChatLoaded(this.messages);

  final List<Message> messages;

  @override
  List<Object?> get props => [messages];
}

/// メッセージ送信中状態
class ChatSending extends ChatState {
  const ChatSending(this.messages);

  final List<Message> messages;

  @override
  List<Object?> get props => [messages];
}

/// エラー状態
class ChatError extends ChatState {
  const ChatError(this.message, {this.messages = const []});

  final String message;
  final List<Message> messages;

  @override
  List<Object?> get props => [message, messages];
}
