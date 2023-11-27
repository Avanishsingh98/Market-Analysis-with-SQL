use us_regional_sales
GO

Declare @today_date AS DATE = '2021-01-01';
WITH base AS (

SELECT
  CustomerID AS customer_id
  --,MAX(OrderDate) as most_recently_purchased_date
  ,DATEDIFF(day, MAX(OrderDate), @today_date) as recency_score
  ,COUNT(OrderNumber) as frequency_score
  ,CAST(SUM([Unit_Price] - ([Unit_Price] * [Discount_Applied]) - [Unit_Cost]) as DECIMAL(16, 0)) as monetary_score
FROM sales_order
GROUP BY CustomerID
),

rfm_scores AS 
(SELECT
customer_id
,recency_score
,frequency_score
,monetary_score
,NTILE(5) OVER (ORDER BY recency_score DESC) as R
,NTILE(5) OVER (ORDER BY frequency_score ASC) as F
,NTILE(5) OVER (ORDER BY monetary_score  ASC) as M
FROM base
)

Select
(R + F + M) / 3 as rfm_group
,count(rfm.customer_id) as customer_count
,sum(base.monetary_score) as total_revenue
,CAST(sum(base.monetary_score) / count(rfm.customer_id) AS DECIMAL(12, 2)) as avg_revenue_per_customer
FROM rfm_scores as rfm
INNER JOIN base ON base.customer_id = rfm.customer_id
GROUP BY (R+F+M) / 3
ORDER BY rfm_group DESC


--SELECT customer_id
--,CONCAT_WS('-', R, F, M) as rfm_cell
--,CAST((CAST(R as FLOAT) + F + M) / 3 AS decimal(16,2)) as avg_rfm_scores
--FROM rfm_scores
