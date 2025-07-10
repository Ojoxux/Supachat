# Supachat 📱💬

Flutter × Supabase を使用したリアルタイムチャットアプリケーション

## アプリケーション概要

**Supachat** は、Clean Architecture + MVVMパターンを採用したチャットアプリケーションです。  
Supabaseをバックエンドとして使用し、リアルタイムメッセージング、ユーザー認証、プロフィール管理機能が実装されています。

### 主な機能
- 🔐 **ユーザー認証**（サインアップ・ログイン・ログアウト）
- 💬 **リアルタイムチャット**（WebSocket接続）
- 👤 **プロフィール管理**
- 🎨 **モダンなUI/UX**

## 使用技術

### フロントエンド
- **Flutter** - クロスプラットフォーム開発
- **Dart** - プログラミング言語
- **Riverpod** - 状態管理
- **flutter_riverpod** - Riverpod Flutter統合

### バックエンド
- **Supabase** - BaaS（Backend as a Service）
- **PostgreSQL** - データベース
- **Supabase Auth** - 認証システム
- **Supabase Realtime** - リアルタイム通信

### アーキテクチャ・パターン
- **Clean Architecture** - 依存関係の逆転
- **MVVM** - Model-View-ViewModel
- **Repository Pattern** - データアクセス抽象化
- **Dependency Injection** - 依存性注入

### 開発・テスト
- **Mockito** - モックテスト
- **flutter_test** - ユニットテスト
- **build_runner** - コード生成

## セットアップ

### 前提条件
- Flutter SDK (3.0.0以上)
- Dart SDK (2.17.0以上)
- Supabaseアカウント

### インストール

1. リポジトリをクローン
```bash
git clone https://github.com/Ojoxux/Supachat.git
cd Supachat
```

2. 依存関係をインストール
```bash
flutter pub get
```

3. 環境変数を設定
```bash
cp lib/env.example.dart lib/env.dart
# env.dartにSupabaseの設定を記入
```

4. アプリケーションを実行
```bash
flutter run
```

## テスト実行

```bash
# ユニットテスト実行
flutter test

# テストカバレッジ生成
flutter test --coverage
```

## ディレクトリ構成（MVVM + Clean Architecture）

```
lib/
├── core/                          # 共通機能
│   ├── di/                       # 依存性注入
│   │   └── injection_container.dart
│   ├── error/                    # エラーハンドリング
│   │   └── failures.dart
│   ├── network/                  # ネットワーク関連
│   │   └── network_info.dart
│   └── utils/                    # 共通ユーティリティ
│       ├── error_utils.dart
│       └── typedef.dart
├── features/                      # 機能別ディレクトリ
│   ├── auth/                     # 認証機能
│   │   ├── data/                 # データ層
│   │   │   ├── datasources/      # データソース
│   │   │   ├── models/           # データモデル
│   │   │   └── repositories/     # リポジトリ実装
│   │   ├── domain/               # ドメイン層
│   │   │   ├── entities/         # エンティティ
│   │   │   ├── repositories/     # リポジトリ抽象化
│   │   │   └── usecases/         # ユースケース
│   │   └── presentation/         # プレゼンテーション層
│   │       ├── pages/            # ページ
│   │       ├── viewmodels/       # ビューモデル
│   │       └── widgets/          # ウィジェット
│   ├── chat/                     # チャット機能
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── profile/                  # プロフィール機能
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/                       # 共有コンポーネント
│   ├── utils/
│   └── widgets/
└── main.dart                     # エントリーポイント
```

## 開発で苦労した点・感想

### 😵 **アーキテクチャの概念理解が大変だった**
最初は「Clean Architectureって何？」状態でした...
- **Before**: とりあえず動けばOK的な作り方
- **After**: 「この処理はどの層に書くべき？」を毎回考える癖がついた
- **学び**: 設計パターンを理解するのに時間がかかったけど、後から変更しやすいコードが書けるようになった！

### 🤯 **Riverpodの状態管理が複雑すぎた**
StatefulWidgetから一気にRiverpodに移行したのが辛かった...
- **困ったこと**: 
  - `StateNotifier`と`AsyncValue`の使い分けが分からない
  - 複数のViewModelの状態を同期させるのが難しい
  - エラーハンドリングをどこでやるべきか迷う
- **解決策**: 公式ドキュメントを読み込んで、サンプルコードを真似しながら覚えた

### 💀 **既存コードを全部書き直すことになった**
途中で「これ、最初から作り直した方が早いのでは？」と思った瞬間があった...

```
# 最初の構造（シンプルだけど拡張性なし）
lib/
├── pages/
├── model/
└── utils/

# 現在の構造（複雑だけど保守性◎）
lib/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── chat/
│   └── profile/
├── core/
└── shared/
```

### 🎯 **データフローを理解するのに時間がかかった**
```
# 以前：直接的でシンプル
Widget → Supabase API

# 現在：遠回りだけど責任分離ができてる
Widget → ViewModel → UseCase → Repository → DataSource → Supabase API
```

### 😤 **非同期処理とエラーハンドリングが鬼門**
- `AsyncValue`でのローディング状態管理
- ストリーム（リアルタイムチャット）の扱い方
- 各層でのエラーハンドリングの役割分担

**正直な感想**: 最初は「なんでこんなに複雑にするの？」と思ったけど、実際に機能追加や修正をするときに「あ、これがClean Architectureの恩恵か！」と実感できました。コードの見通しが良くなって、テストも書きやすくなりました 🎉

## 参考資料

### アーキテクチャ周り
- https://zenn.dev/sakaki_web/articles/8f65b267929ed3
- https://zenn.dev/humanhacker/articles/bbfb97a0d146bc
- https://flutter.salon/%E7%BF%BB%E8%A8%B3/flutter-architecture-case-study/

### Riverpod入門
- https://www.flutter-study.dev/firebase-app/