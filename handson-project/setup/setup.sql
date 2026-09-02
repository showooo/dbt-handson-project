-- =========================================================
-- dbt Projects on Snowflake ハンズオン用 環境セットアップSQL
-- 60分のハンズオンに収めるため、Tasty Bytes等の大規模サンプルではなく
-- ごく小さな「簡易ECサイト」データセットを使用する。
-- 参加者は Snowsight のワークシートでこのファイルの内容を実行する。
-- =========================================================

-- 1. ウェアハウス作成（既に利用可能なウェアハウスがあればスキップ可）
CREATE WAREHOUSE IF NOT EXISTS dbt_handson_wh
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- 2. データベース・スキーマ作成
CREATE DATABASE IF NOT EXISTS dbt_handson_db;
CREATE SCHEMA IF NOT EXISTS dbt_handson_db.raw;         -- ソースデータ格納用
CREATE SCHEMA IF NOT EXISTS dbt_handson_db.dev;         -- dbtモデルのdevターゲット出力先
CREATE SCHEMA IF NOT EXISTS dbt_handson_db.integrations; -- API統合の管理用（説明用スキーマ）

USE DATABASE dbt_handson_db;
USE SCHEMA raw;

-- 3. ソーステーブル作成（顧客・注文の最小データセット）
CREATE OR REPLACE TABLE raw.customers (
  customer_id   INT,
  customer_name STRING,
  email         STRING,
  signup_date   DATE
);

INSERT INTO raw.customers (customer_id, customer_name, email, signup_date) VALUES
  (1, 'Alice Tanaka',  'alice@example.com',  '2025-01-10'),
  (2, 'Bob Sato',      'bob@example.com',    '2025-02-03'),
  (3, 'Carol Suzuki',  'carol@example.com',  '2025-02-20'),
  (4, 'Dai Yamada',    'dai@example.com',    '2025-03-05'),
  (5, 'Emi Kobayashi', 'emi@example.com',    '2025-03-18');

CREATE OR REPLACE TABLE raw.orders (
  order_id     INT,
  customer_id  INT,
  order_date   DATE,
  amount       NUMBER(10,2),
  status       STRING
);

INSERT INTO raw.orders (order_id, customer_id, order_date, amount, status) VALUES
  (101, 1, '2025-04-01', 1200.00, 'completed'),
  (102, 1, '2025-04-15', 3400.00, 'completed'),
  (103, 2, '2025-04-03', 800.00,  'completed'),
  (104, 3, '2025-04-10', 500.00,  'cancelled'),
  (105, 3, '2025-04-20', 2200.00, 'completed'),
  (106, 4, '2025-04-22', 1500.00, 'completed'),
  (107, 5, '2025-04-25', 900.00,  'completed'),
  (108, 5, '2025-04-28', 300.00,  'cancelled');

-- 4. ログ・トレース設定（任意。監視機能を紹介する場合のみ）
ALTER SCHEMA dbt_handson_db.dev SET LOG_LEVEL = 'INFO';
ALTER SCHEMA dbt_handson_db.dev SET TRACE_LEVEL = 'ALWAYS';

-- =========================================================
-- 5. API統合（GitHub連携用）作成
--    主催者(showooo)の公開リポジトリを全参加者が共通で参照するため、
--    URLは固定。secret（個人アクセストークン）の作成は不要。
-- =========================================================
CREATE OR REPLACE API INTEGRATION dbt_handson_git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/showooo')
  ENABLED = TRUE;

SELECT 'dbt_handson_db setup is now complete' AS message;

-- =========================================================
-- 後片付け（ハンズオン終了後、不要であれば実行）
-- =========================================================
-- DROP SEMANTIC VIEW IF EXISTS dbt_handson_db.dev.customer_orders_sv;
-- DROP TASK IF EXISTS dbt_handson_db.dev.run_dbt_handson;
-- DROP WAREHOUSE IF EXISTS dbt_handson_wh;
-- DROP DATABASE IF EXISTS dbt_handson_db;
-- DROP API INTEGRATION IF EXISTS dbt_handson_git_api_integration;
