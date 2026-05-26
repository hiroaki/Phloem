# 開発

## 現在の状態

最初のマイルストーンは完了です。

Phloem は、GraphHopper を backend に持つ独立した Rails API-only application として動作しており、`POST /route` の MVP が通っています。ローカル開発用 GraphHopper は `tools/routing/graphhopper` に分離され、request spec / adapter spec は通過し、ローカル GraphHopper に対する手動スモークテストも成功しています。

## ミッション

Phloem を、まずは GraphHopper を backend に持つ provider 非依存の薄い routing facade として構築しつつ、将来 OSRM 互換や Valhalla 系 adapter を追加できる内部構造を維持する。

## 現在のプロダクト形状

- 公開 endpoint: `POST /route`
- 現在使用中の backend provider: GraphHopper
- health check: Rails 標準の `GET /up`
- 任意の request 認証: `PHLOEM_API_KEY` による `POST /route` の保護
- response contract: 正規化された geometry、distance、duration、provider、warnings、および安定した error envelope

## 完了済み

### API と契約
- `profile`、`points`、`options` の request validation
- 正規化された route response serialization
- validation error、upstream timeout、upstream error、authentication error の安定した envelope

### Provider 統合
- provider abstraction の背後にある GraphHopper adapter
- `RoutingService` による routing orchestration
- environment variable による provider 設定

### 運用ベースライン
- `tools/routing/graphhopper` に分離されたローカル GraphHopper runtime
- Docker Compose による GraphHopper 起動
- ローカル GraphHopper の設定、cache、SRTM cache、logs の文書化
- `POST /route` に対する任意の API キー保護
- baseline の health check としての Rails `GET /up`

### 検証
- public API 振る舞いに対する request specs
- GraphHopper の写像と timeout handling に対する adapter specs
- ローカル GraphHopper 経由で Rails endpoint を叩く manual smoke test の成功

## 現在のスコープ

### v1 に含めるもの
- Rails API-only application
- `POST /route`
- route 計算用の GraphHopper adapter
- provider 非依存の request validation
- provider 非依存の normalized response serialization
- timeout と upstream error handling
- optional な API キー認証
- request / adapter 振る舞いの test coverage
- environment variable による設定

### v1 で明示的に対象外とするもの
- `POST /match`
- `GET /capabilities`
- turn-by-turn instructions
- matrix / isochrone endpoints
- provider 固有の advanced costing の露出
- DB による request history
- admin UI

## アーキテクチャメモ

- public API は内部抽象より小さく保つ。
- provider 固有の request / response 形式は隠蔽する。
- stateless な request handling を優先する。
- persistence は運用上の必要が明確になるまで入れない。
- backend の全機能公開ではなく、provider の交換容易性を優先する。

## 次のマイルストーン

次のマイルストーンでは、公開 surface を広げるよりも MVP を締めることを優先する。

### 推奨優先事項
1. `POST /route` の異常系や境界条件に対する test coverage を厚くする。
2. 将来の `route`、`match`、`capabilities` 拡張に耐える provider interface を維持する。ただし endpoint はまだ増やさない。
3. 任意の API キー認証フローを軽量で運用しやすい状態に保つ。
4. caching を次の運用 slice に含めるか決める。
5. Rails 標準の `GET /up` を超える `GET /capabilities` が必要か判断する。

### 要件が変わらない限り次の slice でやらないもの
- turn-by-turn instructions
- matrix / isochrone 対応
- request persistence、quota、analytics、admin UI
- public API における provider 固有 costing 制御

## 注意すべきリスク

- public contract に GraphHopper 前提が漏れること
- 明確な必要がない段階で public API を広げること
- provider 非依存 options を早すぎる段階で増やしすぎること
- authentication concern と routing 振る舞いを密結合にすること
- ローカル GraphHopper ツールの実運用が文書から乖離すること

## 作業上の合意

- 常に 1 本のローカル end-to-end request を維持する。
- provider や内部実装を変えても normalized response contract は守る。
- `tools/routing/graphhopper` は Rails 本体とは分離された外部ツール境界として扱う。
- ローカル PBF dataset を切り替えるときは GraphHopper cache を再利用しようとせず、再構築する。

## 主な実装場所

- `app/controllers/routes_controller.rb`
- `app/services/routing_service.rb`
- `app/adapters/routing_provider.rb`
- `app/adapters/graph_hopper_adapter.rb`
- `app/serializers/route_response_serializer.rb`
- `config/routes.rb`
- `spec/requests/route_spec.rb`
- `spec/adapters/graph_hopper_adapter_spec.rb`