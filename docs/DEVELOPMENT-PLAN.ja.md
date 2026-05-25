# 開発計画

## ミッション

Phloem を、まずは GraphHopper の前段に置く薄い正規化 routing facade として、独立した Rails API-only application として構築する。同時に、将来 OSRM 互換や Valhalla 系 adapter を追加できる内部構造を維持する。

## スコープ

### v1 に含めるもの
- Rails API-only application
- `POST /route`
- route 計算用の GraphHopper adapter
- provider 非依存の request validation
- provider 非依存の normalized response serialization
- timeout と upstream error handling
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

## 設計原則

1. public API は内部抽象より小さく保つ。
2. provider 固有の request / response 形式は隠蔽する。
3. stateless な request handling を優先する。
4. 明確な運用上の必要が出るまで persistence を入れない。
5. backend の全機能公開ではなく、provider の交換容易性を優先する。

## 提案マイルストーン

### マイルストーン 1: API 契約
- `POST /route` の request JSON schema を定義する
- response JSON schema と安定した error envelope を定義する
- `profile` と `points` の validation rule を定義する

### マイルストーン 2: Rails skeleton
- Rails API-only app を生成する
- routes、base controller 振る舞い、environment configuration を整える
- upstream provider 呼び出し用の HTTP client 方針を決める

### マイルストーン 3: Provider abstraction
- abstract routing provider interface を作る
- GraphHopper adapter を作る
- 将来の `match` と `capabilities` の method slot を残す

### マイルストーン 4: Orchestration と serialization
- routing service を実装する
- response serializer / normalizer を実装する
- GraphHopper response を public JSON に写像する

### マイルストーン 5: 運用上の補強
- timeout handling を追加する
- upstream error mapping を追加する
- optional な固定 API-key auth seam を追加する
- caching をすぐ入れるか次の milestone に回すか決める

### マイルストーン 6: 検証
- API 振る舞いの request specs
- fixture payload を使う adapter specs
- ローカル GraphHopper に対する curl による手動確認

## 初期 API 形状の提案

### Request

```json
{
  "profile": "car",
  "points": [
    { "lat": 35.68, "lon": 139.76 },
    { "lat": 35.69, "lon": 139.77 }
  ],
  "options": {}
}
```

### Response

```json
{
  "route": {
    "geometry": {
      "type": "LineString",
      "coordinates": [
        [139.76, 35.68],
        [139.77, 35.69]
      ]
    },
    "distance_meters": 1234.5,
    "duration_seconds": 456.7,
    "provider": "graphhopper",
    "warnings": []
  }
}
```

### Error envelope

```json
{
  "error": {
    "code": "upstream_timeout",
    "message": "Routing provider timed out",
    "details": {}
  }
}
```

## Rails 実装の主な想定場所

- `app/controllers/routes_controller.rb`
- `app/services/routing_service.rb`
- `app/adapters/routing_provider.rb`
- `app/adapters/graph_hopper_adapter.rb`
- `app/serializers/route_response_serializer.rb`
- `config/routes.rb`
- `spec/requests/route_spec.rb`
- `spec/adapters/graph_hopper_adapter_spec.rb`

## 注意すべきリスク

- public contract に GraphHopper 前提が漏れること
- 最初の happy path が通る前に public API を広げすぎること
- provider 非依存 options を早すぎる段階で増やしすぎること
- authentication と routing concern を密結合にすること

## 最初の動作スライスの完了条件

次を満たしたら最初の milestone は完了:
- ローカル GraphHopper を `POST /route` 経由で問い合わせできる
- 不正 payload に対して安定した validation error を返す
- upstream failure に対して安定した error envelope を返す
- request spec 1 本と adapter spec 1 本が通る
- 返却 geometry が provider 固有 decode なしでブラウザ client からそのまま利用できる
