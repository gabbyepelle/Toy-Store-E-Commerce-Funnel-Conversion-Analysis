-- ============================================================
-- STAGE 4: POST-CHECKOUT
-- What happens after the purchase? Revenue, refunds, and retention.
-- ============================================================


-- Order Value & Profitability
WITH order_summary AS (
  SELECT
    o.order_id,
    SUM(i.price_usd) AS order_revenue,
    SUM(i.price_usd - i.cogs_usd) AS order_profit,
    o.items_purchased
  FROM `nimble-theme-498523-f3.toystore.orders` o
  JOIN `nimble-theme-498523-f3.toystore.order_items` i ON i.order_id = o.order_id
  GROUP BY o.order_id, o.items_purchased
)

SELECT
  ROUND(AVG(order_revenue), 2) AS avg_revenue_per_order,
  ROUND(AVG(order_profit), 2) AS avg_profit_per_order,
  ROUND(AVG(items_purchased), 2) AS avg_items_per_order,
  ROUND(AVG(order_profit) / AVG(order_revenue) * 100, 2) AS avg_profit_margin_pct
FROM order_summary;


-- Overall Refund Rate
SELECT
  COUNT(o.order_id) AS total_orders,
  COUNT(r.order_item_refund_id) AS total_refunds,
  ROUND(COUNT(r.order_item_refund_id) * 100.0 / COUNT(*), 2) AS refund_pct
FROM `nimble-theme-498523-f3.toystore.orders` o
LEFT JOIN `nimble-theme-498523-f3.toystore.refunds` r
  ON o.order_id = r.order_id;


-- Refund Rate by Product
SELECT
  p.product_name,
  COUNT(o.order_id) AS total_orders,
  COUNT(r.order_item_refund_id) AS total_refunds,
  ROUND(COUNT(r.order_item_refund_id) * 100.0 / COUNT(o.order_id), 2) AS refund_pct
FROM `nimble-theme-498523-f3.toystore.orders` o
LEFT JOIN `nimble-theme-498523-f3.toystore.order_items` i ON o.order_id = i.order_id
LEFT JOIN `nimble-theme-498523-f3.toystore.products` p ON i.product_id = p.product_id
LEFT JOIN `nimble-theme-498523-f3.toystore.refunds` r ON o.order_id = r.order_id
WHERE i.is_primary_item = 1
GROUP BY p.product_name
ORDER BY refund_pct DESC;


-- New vs Repeat Session Conversion Rate
-- Measures whether returning visitors convert at a higher rate than new ones
WITH orders AS (
  SELECT
    SUM(CASE WHEN s.is_repeat_session = 0 THEN 1 ELSE 0 END) AS new_sessions,
    SUM(CASE WHEN s.is_repeat_session = 1 THEN 1 ELSE 0 END) AS repeat_sessions,
    COUNT(s.website_session_id) AS total_sessions,
    SUM(CASE WHEN o.order_id IS NOT NULL AND s.is_repeat_session = 0 THEN 1 ELSE 0 END) AS new_session_orders,
    SUM(CASE WHEN o.order_id IS NOT NULL AND s.is_repeat_session = 1 THEN 1 ELSE 0 END) AS repeat_session_orders
  FROM `nimble-theme-498523-f3.toystore.website_sessions` s
  LEFT JOIN `nimble-theme-498523-f3.toystore.orders` o
    ON s.website_session_id = o.website_session_id
)

SELECT
  new_sessions,
  repeat_sessions,
  ROUND(new_sessions * 100.0 / total_sessions, 2) AS new_session_pct,
  ROUND(repeat_sessions * 100.0 / total_sessions, 2) AS repeat_session_pct,
  ROUND(new_session_orders * 100.0 / NULLIF(new_sessions, 0), 2) AS new_session_cvr,
  ROUND(repeat_session_orders * 100.0 / NULLIF(repeat_sessions, 0), 2) AS repeat_session_cvr
FROM orders;
