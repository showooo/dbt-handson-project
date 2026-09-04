# ハンズオン手順書（dbt Projects on Snowflake）

開催時間: 60分
参考: [Tutorial: Get started with dbt Projects on Snowflake](https://docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-getting-started-tutorial)

本手順書は、公式チュートリアルをベースに、60分のハンズオンに収まるよう
データセットと手順を簡略化したものです（使用するdbtプロジェクトは `handson-project/` を参照）。

## タイムテーブル（目安）

| 時間 | 内容 |
|---|---|
| 18:00-18:05 | イントロ（dbtとは、当日のゴール説明） |
| 18:05-18:15 | STEP1: Snowflake環境準備（SQL実行） |
| 18:15-18:25 | STEP2: ワークスペース作成・GitHub連携 |
| 18:25-18:40 | STEP3: dbtモデルのコンパイル・DAG確認・run実行 |
| 18:40-18:50 | STEP4: 結果確認・テスト実行 |
| 18:50-18:58 | （時間があれば）STEP5: セマンティックビュー作成のデモ |
| 18:58-19:00 | クロージング・質疑応答 |

---

## STEP1: Snowflake環境準備（10分）

1. Snowsightにサインインする。
2. 左メニューから **Projects » Worksheets** を開き、新しいSQLワークシートを作成する。
3. `handson-project/setup/setup.sql` の内容をコピーし、ワークシートに貼り付けて実行する。
   - SQLはそのまま実行できます（書き換え不要）。
   - `cmd/ctrl + Shift + Enter` で、コメントアウトされていない行をすべて実行できます。
4. 実行結果として `dbt_handson_db setup is now complete` というメッセージが表示されることを確認する。

このSQLで、以下が作成されます。
- ウェアハウス: `dbt_handson_wh`
- データベース: `dbt_handson_db`（`raw` / `dev` / `integrations` スキーマ）
- サンプルテーブル: `raw.customers`, `raw.orders`
- API統合: `dbt_handson_git_api_integration`（GitHub連携用）

---

## STEP2: ワークスペース作成・GitHub連携（10分）

1. Snowsightの左メニューから **Projects » Workspaces** を開く。
2. **Create Workspace » From Git repository** を選択する。
3. 以下を入力する。
   - **Repository URL**: `https://github.com/showooo/dbt-handson-project.git`
   - **Workspace name**: 任意（例: `dbt_handson_ws`）
   - **API integration**: `DBT_HANDSON_GIT_API_INTEGRATION`
   - **Public repository** を選択
4. **Create** を選択し、ワークスペースが作成されることを確認する。
5. ワークスペース内の `profiles.yml` を開き、`database` / `schema` / `warehouse` が
   STEP1で作成したものと一致しているか確認する。

> **注意**: Publicリポジトリに接続したワークスペースからはcommit/pushはできません。
> 本ハンズオンではファイルの編集・pushは行わないため問題ありません。

---

## STEP3: dbtモデルのコンパイル・DAG確認・run実行（15分）

1. ワークスペース上部のプロジェクト/プロファイル選択で、プロジェクトと **Profile: dev** を選択する。
2. コマンド一覧から **Compile** を選択し、実行する。
3. エディタ下部の **DAG** タブを開き、以下のようなモデル間の依存関係（DAG）が可視化されていることを確認する。
   ```
   stg_customers ─┐
                   ├─→ customer_order_summary
   stg_orders ────┘
   ```
4. `models/marts/customer_order_summary.sql` を開き、右上の **View Compiled SQL** を選択して、
   `ref()` / `source()` がどのように実SQLへ変換されるかを確認する。
5. コマンド一覧から **Run** を選択し、実行する。
6. 出力（Outputタブ）で、3つのモデルがすべて成功していることを確認する。

---

## STEP4: 結果確認・テスト実行（10分）

1. ワークスペースのルート（`models/` フォルダの外）に新規SQLファイル（例: `sandbox.sql`）を作成する。
   - **注意**: `models/` フォルダ内に作成すると、dbtがモデルとして認識してしまうため避けてください。
2. 以下のSQLを実行し、`dev`スキーマにモデルが実体化されていることを確認する。

   ```sql
   show tables in schema dbt_handson_db.dev;
   show views in schema dbt_handson_db.dev;

   select * from dbt_handson_db.dev.customer_order_summary
   order by total_amount desc;
   ```

3. ワークスペースのコマンド一覧から **Test** を選択し、実行する。
   - `schema.yml` に定義した `unique` / `not_null` テストが実行され、
     すべて成功（PASS）することを確認する。

---

## STEP5（時間があれば）: セマンティックビュー作成のデモ（8分）

時間に余裕がある場合のみ、以下を**デモとして紹介**します（全員での実施は必須としません）。

dbtで作成したモデルの上にセマンティックビューを定義することで、
ビジネスユーザーやCortex Analystが自然言語でデータを問い合わせできるようになります。

1. STEP4で作成した `sandbox.sql`（または新規SQLファイル）に、以下のSQLを貼り付けて実行する。

   ```sql
   CREATE OR REPLACE SEMANTIC VIEW dbt_handson_db.dev.customer_orders_sv

     TABLES (
       customers AS dbt_handson_db.dev.stg_customers
         PRIMARY KEY (customer_id)
         COMMENT = '顧客マスタ',
       orders AS dbt_handson_db.dev.stg_orders
         PRIMARY KEY (order_id)
         COMMENT = '注文明細（完了分のみ）'
     )

     RELATIONSHIPS (
       orders_to_customers AS
         orders (customer_id) REFERENCES customers
     )

     FACTS (
       orders.order_amount AS amount
         COMMENT = '注文金額'
     )

     DIMENSIONS (
       customers.customer_name AS customers.customer_name
         WITH SYNONYMS = ('顧客名')
         COMMENT = '顧客の氏名',
       customers.email AS customers.email
         COMMENT = 'メールアドレス',
       orders.order_date AS orders.order_date
         COMMENT = '注文日',
       orders.order_year AS YEAR(orders.order_date)
         COMMENT = '注文年'
     )

     METRICS (
       orders.total_revenue AS SUM(orders.order_amount)
         COMMENT = '売上合計',
       orders.order_count AS COUNT(orders.order_id)
         COMMENT = '注文件数',
       orders.avg_order_value AS AVG(orders.order_amount)
         COMMENT = '平均注文金額'
     )

     COMMENT = 'dbtハンズオン用：顧客と注文のセマンティックビュー';
   ```

2. 作成されたセマンティックビューの内容を確認する。

   ```sql
   DESCRIBE SEMANTIC VIEW dbt_handson_db.dev.customer_orders_sv;
   ```

3. セマンティックビューを使って、以下のようにクエリできることを確認する。

   ```sql
   SELECT *
   FROM SEMANTIC_VIEW(
     dbt_handson_db.dev.customer_orders_sv
     DIMENSIONS customers.customer_name
     METRICS orders.total_revenue, orders.order_count
   )
   ORDER BY total_revenue DESC;
   ```

4. 補足として以下を説明する。
   - セマンティックビューを定義すると、**Cortex Analyst（自然言語クエリ）** や
     **Snowflake Intelligence** から「売上が一番多い顧客は？」のような質問でデータを取得できるようになる。
   - dbtでデータ変換の「パイプライン」を、セマンティックビューで「意味の定義」を担当する、
     という役割分担のイメージを紹介する。

### 上級者向け: dbt_semantic_view パッケージによるセマンティックビュー管理

上記ではSQLを直接実行してセマンティックビューを作成しましたが、
`Snowflake-Labs/dbt_semantic_view` パッケージを使えば、**dbtモデルの一部として**
セマンティックビューをバージョン管理・自動デプロイできます。
ハンズオン後に各自で試したい方向けに手順を記載します。

> **前提**: このパッケージを利用するには `dbt deps` でのパッケージインストールが必要です。
> dbt Projects on Snowflake では `dbt deps` の実行にExternal Access Integration（EAI）が必要になります。
>
> **注意: トライアルアカウントではExternal Access Integrationを作成できないため、本セクションは実施できません。**
> 有償アカウントをお持ちの方のみお試しください。

#### 1. Network Rule と External Access Integration の作成

Snowsightのワークシートで以下を実行します。

```sql
-- パッケージダウンロード先への通信を許可するNetwork Rule
CREATE OR REPLACE NETWORK RULE dbt_handson_db.integrations.dbt_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

-- External Access Integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION dbt_handson_ext_access
  ALLOWED_NETWORK_RULES = (dbt_handson_db.integrations.dbt_network_rule)
  ENABLED = TRUE;
```

#### 2. packages.yml の作成

ワークスペース内のプロジェクトルート（`dbt_project.yml` と同じ階層）に `packages.yml` を作成します。

```yaml
packages:
  - package: Snowflake-Labs/dbt_semantic_view
    version: [">=1.0.0"]
```

#### 3. dbt deps の実行

ワークスペースのコマンド一覧から **deps** を選択し、実行します。
実行時に **External Access Integration** として `DBT_HANDSON_EXT_ACCESS` を選択してください。

#### 4. セマンティックビューのモデルファイル作成

> **注意**: STEP5前半でSQL直接実行により `customer_orders_sv` を作成済みの場合、
> 名前の競合を避けるためモデル名を `customer_orders_sv_dbt` としています。

`models/marts/customer_orders_sv_dbt.sql` を新規作成し、以下を記述します。

```sql
{{ config(materialized='semantic_view') }}

TABLES (
  customers AS {{ ref('stg_customers') }}
    PRIMARY KEY (customer_id)
    COMMENT = '顧客マスタ',
  orders AS {{ ref('stg_orders') }}
    PRIMARY KEY (order_id)
    COMMENT = '注文明細（完了分のみ）'
)

RELATIONSHIPS (
  orders_to_customers AS
    orders (customer_id) REFERENCES customers
)

FACTS (
  orders.order_amount AS amount
    COMMENT = '注文金額'
)

DIMENSIONS (
  customers.customer_name AS customers.customer_name
    WITH SYNONYMS = ('顧客名')
    COMMENT = '顧客の氏名',
  customers.email AS customers.email
    COMMENT = 'メールアドレス',
  orders.order_date AS orders.order_date
    COMMENT = '注文日',
  orders.order_year AS YEAR(orders.order_date)
    COMMENT = '注文年'
)

METRICS (
  orders.total_revenue AS SUM(orders.order_amount)
    COMMENT = '売上合計',
  orders.order_count AS COUNT(orders.order_id)
    COMMENT = '注文件数',
  orders.avg_order_value AS AVG(orders.order_amount)
    COMMENT = '平均注文金額'
)

COMMENT = 'dbtハンズオン用：顧客と注文のセマンティックビュー'
```

> **ポイント**: テーブル参照に `{{ ref('stg_customers') }}` を使うことで、
> dbtが完全修飾名に解決し、DAGの依存関係も自動的に追跡されます。

#### 5. dbt run の実行

ワークスペースで **Run** を実行すると、通常のテーブル/ビューモデルと一緒に
セマンティックビューも作成・更新されます。

#### dbt連携のメリット

- セマンティックビューの定義がGit管理され、コードレビュー・CI/CDの対象になる
- `ref()` によりDAGに組み込まれ、上流モデルの変更時に自動で再構築される
- テーブル/ビュー/セマンティックビューを `dbt run` 一発で統一的に管理できる

#### 後片付け

上級者向け手順で作成した追加リソースを削除する場合は以下を実行してください。

```sql
DROP EXTERNAL ACCESS INTEGRATION IF EXISTS dbt_handson_ext_access;
DROP NETWORK RULE IF EXISTS dbt_handson_db.integrations.dbt_network_rule;
DROP SEMANTIC VIEW IF EXISTS dbt_handson_db.dev.customer_orders_sv_dbt;
```

---

## クロージング

- 本ハンズオンで体験したこと（モデル定義、DAG、ref/source、run、test、セマンティックビュー）を振り返る。
- 自チームの開発プロセスへの適用イメージについて簡単に質疑応答を行う。

---

## 後片付け（任意）

不要なリソースを残したくない場合は、以下を実行してください。

```sql
drop semantic view if exists dbt_handson_db.dev.customer_orders_sv;
drop task if exists dbt_handson_db.dev.run_dbt_handson;
drop warehouse if exists dbt_handson_wh;
drop database if exists dbt_handson_db;
drop api integration if exists dbt_handson_git_api_integration;
```

---

## トラブルシューティング

| 事象 | 原因・対処 |
|---|---|
| ワークスペース作成時に「API integrationが見つからない」 | STEP1のSQLが正しく実行されているか確認。ロールがACCOUNTADMINになっているか確認。 |
| ワークスペース作成後、GitHubから404/403エラー | リポジトリURL（`https://github.com/showooo/dbt-handson-project.git`）が正しく入力されているか確認。API Integrationの`API_ALLOWED_PREFIXES`が`https://github.com/showooo`になっているか確認。 |
| `run`実行時に権限エラー（Insufficient privileges） | `profiles.yml`の`role`がACCOUNTADMIN（または十分な権限を持つロール）になっているか確認。 |
| `run`実行時にウェアハウス関連のエラー | `profiles.yml`の`warehouse`名がSTEP1で作成した`dbt_handson_wh`と一致しているか確認。ウェアハウスがサスペンドされていないか確認。 |
| DAGタブに何も表示されない | 先に **Compile** コマンドを実行済みか確認。 |
| テストが失敗する | `raw.customers` / `raw.orders` のサンプルデータがSTEP1のSQLで正しく投入されているか、`show tables`等で確認。 |

> 主催者向けメモ: 本手順は開催前に一度、実アカウントで最初から最後まで通しで実行し、
> 所要時間とエラーの有無を確認（ドライラン）した上で最終化してください。
> 公開リポジトリ `https://github.com/showooo/dbt-handson-project` が当日までに
> 公開状態であること、API Integrationから正しく接続できることを事前に確認してください。
