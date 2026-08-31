-- 注文のステージングモデル：ステータスが cancelled のものを除外
select
    order_id,
    customer_id,
    order_date,
    amount,
    status
from {{ source('raw', 'orders') }}
where status = 'completed'
