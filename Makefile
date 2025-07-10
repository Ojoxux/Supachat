# Flutter CI/CD Helper Commands

.PHONY: help install clean format lint test build-android build-ios build-web ci-check

help: ## ヘルプを表示
	@echo "利用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## 依存関係をインストール
	flutter pub get

clean: ## ビルドファイルをクリーンアップ
	flutter clean
	flutter pub get

format: ## コードフォーマットを実行
	dart format .

format-check: ## コードフォーマットをチェック（変更なし）
	dart format --output=none --set-exit-if-changed .

lint: ## 静的解析を実行
	flutter analyze --fatal-infos --fatal-warnings

test: ## テストを実行
	flutter test

import-sort: ## インポートを整理
	flutter packages pub run import_sorter:main

build-android: ## Android APKをビルド
	flutter build apk --debug

build-ios: ## iOS（署名なし）をビルド
	flutter build ios --no-codesign

build-web: ## Webアプリをビルド
	flutter build web

ci-check: ## CI環境で実行される全チェックを実行
	@echo "🚀 CI チェックを開始..."
	@echo "📦 依存関係をインストール中..."
	@make install
	@echo "🎨 コードフォーマットをチェック中..."
	@make format-check
	@echo "🔍 静的解析を実行中..."
	@make lint
	@echo "🧪 テストを実行中..."
	@make test
	@echo "✅ 全てのチェックが完了しました！"

pre-commit: ## コミット前のチェック
	@echo "🔄 コミット前チェックを実行..."
	@make format
	@make import-sort
	@make lint
	@make test
	@echo "✅ コミット準備完了！" 