-- 顧客ごとの注文サマリ（マート層）
-- ref() で他のdbtモデルを参照するデモを兼ねる
with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

order_summary as (

    select
        customer_id,
        count(order_id)   as order_count,
        sum(amount)       as total_amount
    from orders
    group by customer_id

)

select
    c.customer_id,
    c.customer_name,
    c.email,
    coalesce(o.order_count, 0)  as order_count,
    coalesce(o.total_amount, 0) as total_amount
from customers c
left join order_summary o
    on c.customer_id = o.customer_id
