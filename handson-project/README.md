# dbt_handson プロジェクト

このディレクトリは、2026/9/4 開催の「dbt Projects on Snowflake ハンズオン」で参加者が使用する
最小構成のdbtプロジェクトです。Snowflake公式チュートリアルのTasty Bytesサンプルは
データ量・セットアップ時間の都合上、60分のハンズオンには収まらないため、
本ハンズオン用に「簡易ECサイト（顧客・注文）」を題材にした縮小版データセットを用意しています。

## 構成

```
handson-project/
├── dbt_project.yml       # dbtプロジェクト設定
├── profiles.yml          # 接続プロファイル（参考用。Workspace内で内容確認に使用）
├── setup/
│   └── setup.sql         # Snowflake側の環境構築（DB/スキーマ/ウェアハウス/API統合/サンプルデータ）
└── models/
    ├── staging/
    │   ├── stg_customers.sql
    │   ├── stg_orders.sql
    │   └── schema.yml    # source定義・テスト定義
    └── marts/
        ├── customer_order_summary.sql
        └── schema.yml
```

## 事前準備（主催者向け）

当日までに以下を実施してください。

1. 本ディレクトリの内容を、GitHub上の**公開（Public）リポジトリ**として別途公開する
   （例: `github.com/showooo/dbt-handson-project`）。
   - Publicにすることで、参加者はGitHubアカウント不要・フォーク不要で利用できる。
   - 参加者全員が同じリポジトリURLを使ってワークスペースを作成する。
2. 参加者向けドキュメント（`docs/prerequisites.md` / `docs/handson-guide.md`）内のリポジトリURLが
   実際に公開したURLと一致していることを確認する。
3. 一度、実際に本手順で最初から最後まで通しでSnowflake上に構築し、動作を確認する（ドライラン）。

## 注意（簡略化のポイント）

- `dbt deps` が必要なパッケージ（dbt_utils等）は使用しない構成にしており、
  External Access Integrationの作成手順は省略している（時間短縮のため）。
- モデルは staging 2つ・marts 1つの計3モデルのみ。DAG可視化・`ref()`/`source()`・テスト・
  compileしたSQLの確認など、dbtの主要な体験ポイントは一通り含めている。
- デプロイ（dbtプロジェクトオブジェクト化）・スケジュールタスク作成は、時間に余裕がある場合のみ
  デモとして紹介する想定（`docs/handson-guide.md` 参照）。
