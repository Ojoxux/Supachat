/// ネットワーク接続状態を管理するインターフェース
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// ネットワーク接続状態の実装
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // 実際のプロジェクトではconnectivity_plusなどを使用
    // 今回はシンプルにtrueを返す
    return true;
  }
}
