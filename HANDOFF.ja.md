# Phloem 引き継ぎ

## 現在の状態

これは独立した Rails API-only プロジェクトです。初期アプリケーション骨格と、動作する `POST /route` の MVP まで入っています。

## プロダクト定義

Phloem は、route 系の地理 API を provider 非依存の単一 HTTP インターフェースの背後で正規化する、薄い routing facade です。

## 確定事項

- プロダクト名: `Phloem`
- 実装スタック: Rails API-only
- デプロイ前提: Docker image、主に Kamal を想定
- v1 の公開機能範囲: `route` のみ
- v1 の backend provider: GraphHopper のみ
- 将来の設計目標: OSRM 互換および Valhalla 系 provider を adapter で追加可能にする
- 内部設計では将来の `match` と `capabilities` エンドポイントを考慮する
- 最初のローカル立ち上げでは認証を必須にしないが、`PHLOEM_API_KEY` による API キー認証を `POST /route` に任意で適用できる
- request history、quota、analytics、admin UI が必要になるまで DB は導入しない

## アーキテクチャ方針

Phloem は正規化された HTTP API を公開し、provider 固有の request / response 形式は内部に閉じ込めるべきです。

v1 の公開 API の方向性:
- `POST /route`
- 入力: `profile`、順序付き `points`、および provider 非依存の optional options block
- 出力: 正規化された geometry、distance、duration、provider 識別子、warnings、安定した error envelope

推奨される内部構成:
- request validation と response rendering を行う controller layer
- provider selection と policy を扱う orchestration service layer
- provider 固有の変換を担当する adapter layer
- 安定した public JSON を作る serializer / normalizer layer
- provider URL、credentials、timeouts、将来の auth toggle を扱う environment-driven configuration

## 近い将来の実装順

1. `POST /route` の public JSON schema を異常系 spec まで含めて固める。
2. 将来の `route`、`match`、`capabilities` 拡張に耐える provider interface を維持する。
3. optional な固定 API-key auth を軽量な運用設定として維持する。
4. health check は当面 Rails 標準の `GET /up` を使い、より豊かな endpoint が必要かは運用で判断する。
5. caching を最初の運用強化に含めるか、その直後にするか決める。

## 重要な制約

- GraphHopper 固有のフィールドを public API に漏らさない。
- request format を特定 provider の癖に引きずられた設計にしない。
- 最初の API は小さく保ち、instructions、matrix、isochrone、provider 固有 costing の詳細は v1 に入れない。
- persistence が明確に必要になるまで stateless service として保つ。

## 実装時に確定してよい未決定事項

- `POST /route` の正確な request JSON schema
- 正規化 response の正確な形式
- `provider` を response body に含めるか、metadata のみにするか
- Rails 標準の `GET /up` を超える `/capabilities` が必要か
- caching を最初の milestone に含めるか、その直後にするか

## 想定される初期ディレクトリ構成

```text
phloem/
  README.md
  HANDOFF.md
  HANDOFF.ja.md
  docs/
    DEVELOPMENT-PLAN.md
    DEVELOPMENT-PLAN.ja.md
```

Rails app 生成後に想定する主な実装場所:

```text
app/
  controllers/
  services/
  adapters/
  serializers/
config/
  routes.rb
spec/
  requests/
  adapters/
```

## 最初の具体目標

まず 1 本の end-to-end request をローカルで維持しつつ契約を固めること:
- Rails API が `POST /route` を受ける
- adapter 経由で GraphHopper を呼ぶ
- response を provider 非依存 JSON に正規化する
- request spec と adapter spec が happy path と主要な異常系をカバーする

## 次の AI セッションへのメモ

MVP を厳密に保つこと。最大のリスクは API の過剰設計です。公開 surface は小さく明示的にし、将来拡張は大きな request schema ではなく adapter boundary の内側で吸収する方針を守ってください。
