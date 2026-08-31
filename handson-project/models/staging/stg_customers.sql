-- 顧客のステージングモデル：raw.customers を軽く整形するだけ
select
    customer_id,
    customer_name,
    email,
    signup_date
from {{ source('raw', 'customers') }}
