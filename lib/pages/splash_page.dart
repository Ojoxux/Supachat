// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'chat_page.dart';
import 'register_page.dart';

/// ログイン状態に応じてユーザーをリダイレクトするページ
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_redirect());
  }

  Future<void> _redirect() async {
    // widgetがmountするのを待つ
    await Future<void>.delayed(Duration.zero);

    /// ログイン状態に応じて適切なページにリダイレクト
    final session = supabase.auth.currentSession;
    if (session == null) {
      await Navigator.of(
        context,
      ).pushAndRemoveUntil(RegisterPage.route(), (route) => false);
    } else {
      await Navigator.of(
        context,
      ).pushAndRemoveUntil(ChatPage.route(), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: preloader);
  }
}
