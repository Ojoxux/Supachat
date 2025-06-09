import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_and_supabase_chat_app/model/message.dart';
import 'package:flutter_and_supabase_chat_app/constants.dart';
import 'package:flutter_and_supabase_chat_app/pages/register_page.dart';

/// 他のユーザーとチャットができるページ
///
/// `ListView`内にチャットが表示され、下の`TextField`から他のユーザーへチャットを送信できる。
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

  @override
  void initState() {
    final myUserId = supabase.auth.currentUser!.id;
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at') // 送信日時が新しいものが先に来るようにソート
        .map(
          (maps) =>
              maps
                  .map((map) => Message.fromMap(map: map, myUserId: myUserId))
                  .toList(),
        );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット'),
        actions: [
          TextButton(
            onPressed: () {
              supabase.auth.signOut();
              Navigator.of(
                context,
              ).pushAndRemoveUntil(RegisterPage.route(), (route) => false);
            },
            child: Text(
              'ログアウト',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child:
                      messages.isEmpty
                          ? const Center(child: Text('早速メッセージを送ってみよう！'))
                          : ListView.builder(
                            reverse: true, // 新しいメッセージが下に来るように表示順を上下逆にする
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              return Text(message.content);
                            },
                          ),
                ),
                // ここに後でメッセージ送信ウィジェットを追加
              ],
            );
          } else {
            // ローディング中はローダーを表示
            return preloader;
          }
        },
      ),
    );
  }
}
