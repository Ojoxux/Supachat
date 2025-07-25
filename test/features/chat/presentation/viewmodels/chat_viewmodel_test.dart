import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_and_supabase_chat_app/core/error/failures.dart';
import 'package:flutter_and_supabase_chat_app/features/chat/domain/entities/message.dart';
import 'package:flutter_and_supabase_chat_app/features/chat/domain/usecases/send_message.dart';
import 'package:flutter_and_supabase_chat_app/features/chat/domain/usecases/get_messages.dart';
import 'package:flutter_and_supabase_chat_app/features/chat/domain/usecases/watch_messages.dart';
import 'package:flutter_and_supabase_chat_app/features/chat/domain/usecases/toggle_like.dart';
import 'package:flutter_and_supabase_chat_app/features/chat/domain/usecases/edit_message.dart';
import 'package:flutter_and_supabase_chat_app/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:flutter_and_supabase_chat_app/features/chat/presentation/viewmodels/chat_state.dart';
import 'package:flutter_and_supabase_chat_app/features/profile/domain/usecases/get_profiles.dart';
import 'package:flutter_and_supabase_chat_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';

import 'chat_viewmodel_test.mocks.dart';

// Mockitoを使用してモックを生成
@GenerateMocks([
  SendMessage,
  GetMessages,
  WatchMessages,
  ToggleLike,
  EditMessage,
  GetProfiles,
  Ref,
  ProfileViewModel,
])
void main() {
  provideDummy<ProfileViewModel>(MockProfileViewModel());
  group('ChatViewModel', () {
    late ChatViewModel chatViewModel;
    late MockSendMessage mockSendMessage;
    late MockGetMessages mockGetMessages;
    late MockWatchMessages mockWatchMessages;
    late MockToggleLike mockToggleLike;
    late MockEditMessage mockEditMessage;
    late MockGetProfiles mockGetProfiles;
    late MockRef mockRef;
    late StreamController<List<Message>> messagesStreamController;

    // テスト用のダミーデータ
    final testMessage1 = Message(
      id: 'message-1',
      profileId: 'user-1',
      content: 'Hello World',
      createdAt: DateTime.parse('2024-01-01T10:00:00Z'),
      isMine: true,
    );

    final testMessage2 = Message(
      id: 'message-2',
      profileId: 'user-2',
      content: 'Hi there!',
      createdAt: DateTime.parse('2024-01-01T10:01:00Z'),
      isMine: false,
    );

    final testMessages = [testMessage1, testMessage2];

    const testCurrentUserId = 'user-1';
    const testContent = 'Test message';
    const testProfileId = 'user-1';

    setUp(() {
      mockSendMessage = MockSendMessage();
      mockGetMessages = MockGetMessages();
      mockWatchMessages = MockWatchMessages();
      mockToggleLike = MockToggleLike();
      mockEditMessage = MockEditMessage();
      mockGetProfiles = MockGetProfiles();
      mockRef = MockRef();
      messagesStreamController = StreamController<List<Message>>();

      // MockRefのスタブを設定
      when(
        mockRef.read(profileViewModelProvider.notifier),
      ).thenReturn(MockProfileViewModel());

      chatViewModel = ChatViewModel(
        sendMessage: mockSendMessage,
        getMessages: mockGetMessages,
        watchMessages: mockWatchMessages,
        toggleLike: mockToggleLike,
        editMessage: mockEditMessage,
        getProfiles: mockGetProfiles,
        ref: mockRef,
      );
    });

    tearDown(() {
      messagesStreamController.close();
    });

    group('初期化', () {
      test('初期状態はChatInitialである', () {
        expect(chatViewModel.state, isA<ChatInitial>());
      });
    });

    group('startWatchingMessages', () {
      test('メッセージの監視を開始すると、初期状態はChatLoadingになる', () {
        // Arrange
        when(
          mockWatchMessages(currentUserId: testCurrentUserId),
        ).thenAnswer((_) => messagesStreamController.stream);

        // Act
        chatViewModel.startWatchingMessages(testCurrentUserId);

        // Assert
        expect(chatViewModel.state, isA<ChatLoading>());
      });

      test('メッセージを受信すると、ChatLoaded状態になる', () async {
        // Arrange
        when(
          mockWatchMessages(currentUserId: testCurrentUserId),
        ).thenAnswer((_) => messagesStreamController.stream);

        // Act
        chatViewModel.startWatchingMessages(testCurrentUserId);

        // メッセージをストリームに追加
        messagesStreamController.add(testMessages);

        // 少し待ってから状態を確認
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(chatViewModel.state, isA<ChatLoaded>());
        expect(
          (chatViewModel.state as ChatLoaded).messages,
          equals(testMessages),
        );
      });

      test('ストリームでエラーが発生すると、ChatError状態になる', () async {
        // Arrange
        when(
          mockWatchMessages(currentUserId: testCurrentUserId),
        ).thenAnswer((_) => messagesStreamController.stream);

        // Act
        chatViewModel.startWatchingMessages(testCurrentUserId);

        // エラーをストリームに追加
        messagesStreamController.addError('Stream error');

        // 少し待ってから状態を確認
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(chatViewModel.state, isA<ChatError>());
        expect(
          (chatViewModel.state as ChatError).message,
          contains('メッセージの取得に失敗しました'),
        );
      });

      test('複数回呼び出すと、前のサブスクリプションがキャンセルされる', () {
        // Arrange
        final firstController = StreamController<List<Message>>();
        final secondController = StreamController<List<Message>>();

        when(
          mockWatchMessages(currentUserId: testCurrentUserId),
        ).thenAnswer((_) => firstController.stream);

        // Act - 最初の監視開始
        chatViewModel.startWatchingMessages(testCurrentUserId);

        // 2回目の監視開始
        when(
          mockWatchMessages(currentUserId: testCurrentUserId),
        ).thenAnswer((_) => secondController.stream);
        chatViewModel.startWatchingMessages(testCurrentUserId);

        // Assert - 2回目の監視が有効
        expect(chatViewModel.state, isA<ChatLoading>());

        // Cleanup
        firstController.close();
        secondController.close();
      });
    });

    group('sendMessageAction', () {
      test('空のメッセージは送信されない', () async {
        // Act
        await chatViewModel.sendMessageAction(
          content: '',
          profileId: testProfileId,
        );

        // Assert
        verifyNever(
          mockSendMessage(
            content: anyNamed('content'),
            profileId: anyNamed('profileId'),
          ),
        );
        expect(chatViewModel.state, isA<ChatInitial>());
      });

      test('空白のみのメッセージは送信されない', () async {
        // Act
        await chatViewModel.sendMessageAction(
          content: '   ',
          profileId: testProfileId,
        );

        // Assert
        verifyNever(
          mockSendMessage(
            content: anyNamed('content'),
            profileId: anyNamed('profileId'),
          ),
        );
        expect(chatViewModel.state, isA<ChatInitial>());
      });

      test('メッセージ送信が成功すると、状態は変更されない（リアルタイム更新待ち）', () async {
        // Arrange
        when(
          mockSendMessage(content: testContent, profileId: testProfileId),
        ).thenAnswer((_) async => const Right(null));

        // 事前にメッセージを設定
        chatViewModel.state = ChatLoaded(testMessages);

        // Act
        await chatViewModel.sendMessageAction(
          content: testContent,
          profileId: testProfileId,
        );

        // Assert - 送信後も元の状態のまま（リアルタイム更新で新しいメッセージが追加される）
        expect(chatViewModel.state, isA<ChatLoaded>());
        expect(
          (chatViewModel.state as ChatLoaded).messages,
          equals(testMessages),
        );
      });

      test('メッセージ送信が失敗すると、ChatError状態になる', () async {
        // Arrange
        const failure = ServerFailure(message: 'Send message failed');
        when(
          mockSendMessage(content: testContent, profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        // 事前にメッセージを設定
        chatViewModel.state = ChatLoaded(testMessages);

        // Act
        await chatViewModel.sendMessageAction(
          content: testContent,
          profileId: testProfileId,
        );

        // Assert
        expect(chatViewModel.state, isA<ChatError>());
        expect(
          (chatViewModel.state as ChatError).message,
          equals('Send message failed'),
        );
        expect(
          (chatViewModel.state as ChatError).messages,
          equals(testMessages),
        );
      });
    });

    group('_getCurrentMessages', () {
      test('ChatLoaded状態の場合、メッセージリストを返す', () {
        // Arrange
        chatViewModel.state = ChatLoaded(testMessages);

        // Act & Assert - privateメソッドなので、他のメソッドを通じて確認
        chatViewModel.sendMessageAction(content: '', profileId: testProfileId);
        // 空のメッセージなので送信されず、状態は変わらない
        expect(chatViewModel.state, isA<ChatLoaded>());
      });

      test('ChatLoaded状態でメッセージ送信後も状態が保持される', () async {
        // Arrange
        when(
          mockSendMessage(content: testContent, profileId: testProfileId),
        ).thenAnswer((_) async => const Right(null));

        chatViewModel.state = ChatLoaded(testMessages);

        // Act
        await chatViewModel.sendMessageAction(
          content: testContent,
          profileId: testProfileId,
        );

        // Assert - 送信後も状態が保持される
        expect(chatViewModel.state, isA<ChatLoaded>());
        expect(
          (chatViewModel.state as ChatLoaded).messages,
          equals(testMessages),
        );
      });

      test('ChatError状態の場合、メッセージリストを返す', () async {
        // Arrange
        const failure = ServerFailure(message: 'Error');
        when(
          mockSendMessage(content: testContent, profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        chatViewModel.state = ChatLoaded(testMessages);

        // Act
        await chatViewModel.sendMessageAction(
          content: testContent,
          profileId: testProfileId,
        );

        // Assert
        expect(chatViewModel.state, isA<ChatError>());
        expect(
          (chatViewModel.state as ChatError).messages,
          equals(testMessages),
        );
      });

      test('その他の状態の場合、空のリストを返す', () async {
        // Arrange
        const failure = ServerFailure(message: 'Error');
        when(
          mockSendMessage(content: testContent, profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        // ChatInitial状態のまま

        // Act
        await chatViewModel.sendMessageAction(
          content: testContent,
          profileId: testProfileId,
        );

        // Assert
        expect(chatViewModel.state, isA<ChatError>());
        expect((chatViewModel.state as ChatError).messages, isEmpty);
      });
    });

    group('clearError', () {
      test('ChatError状態の場合、ChatLoaded状態になる', () async {
        // Arrange - エラー状態にする
        const failure = ServerFailure(message: 'Test error');
        when(
          mockSendMessage(content: testContent, profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        chatViewModel.state = ChatLoaded(testMessages);
        await chatViewModel.sendMessageAction(
          content: testContent,
          profileId: testProfileId,
        );

        expect(chatViewModel.state, isA<ChatError>());

        // Act
        chatViewModel.clearError();

        // Assert
        expect(chatViewModel.state, isA<ChatLoaded>());
        expect(
          (chatViewModel.state as ChatLoaded).messages,
          equals(testMessages),
        );
      });

      test('ChatError状態でない場合、状態は変更されない', () {
        // Arrange - ChatLoaded状態にする
        chatViewModel.state = ChatLoaded(testMessages);

        // Act
        chatViewModel.clearError();

        // Assert - 状態は変更されない
        expect(chatViewModel.state, isA<ChatLoaded>());
        expect(
          (chatViewModel.state as ChatLoaded).messages,
          equals(testMessages),
        );
      });
    });

    group('dispose', () {
      test('disposeが呼ばれると、サブスクリプションがキャンセルされる', () {
        // Arrange
        when(
          mockWatchMessages(currentUserId: testCurrentUserId),
        ).thenAnswer((_) => messagesStreamController.stream);

        chatViewModel.startWatchingMessages(testCurrentUserId);

        // Act & Assert - エラーが発生しないことを確認
        expect(() => chatViewModel.dispose(), returnsNormally);
      });
    });

    group('エラーハンドリング', () {
      test('ServerFailureの場合、適切なエラーメッセージが表示される', () async {
        // Arrange
        const failure = ServerFailure(message: 'Server error occurred');
        when(
          mockSendMessage(content: testContent, profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await chatViewModel.sendMessageAction(
          content: testContent,
          profileId: testProfileId,
        );

        // Assert
        expect(chatViewModel.state, isA<ChatError>());
        expect(
          (chatViewModel.state as ChatError).message,
          equals('Server error occurred'),
        );
      });

      test('NetworkFailureの場合、適切なエラーメッセージが表示される', () async {
        // Arrange
        const failure = NetworkFailure(message: 'Network connection failed');
        when(
          mockSendMessage(content: testContent, profileId: testProfileId),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await chatViewModel.sendMessageAction(
          content: testContent,
          profileId: testProfileId,
        );

        // Assert
        expect(chatViewModel.state, isA<ChatError>());
        expect(
          (chatViewModel.state as ChatError).message,
          equals('Network connection failed'),
        );
      });
    });
  });
}
