--Conversion

--cart to billing rate

WITH journey AS (
  SELECT
    website_session_id,
    MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS saw_cart,
    MAX(CASE WHEN pageview_url IN ('/billing', '/billing-2') THEN 1 ELSE 0 END) AS saw_billing  
    FROM `nimble-theme-498523-f3.toystore.website_pageviews`
  GROUP BY website_session_id
)

SELECT
  SUM(saw_cart) AS cart_views,
  SUM(saw_billing) AS billing_views,
  SUM(CASE WHEN saw_cart = 1 AND saw_billing = 1 THEN 1 ELSE 0 END) AS cart_to_billing,
  ROUND(SUM(CASE WHEN saw_billing = 1 AND saw_cart = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(saw_cart), 0), 2) AS billing_initiation_rate
FROM journey


--Order Statistics

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
FROM order_summary



--Top Purchases

WITH purchases AS (
  SELECT 
    o.website_session_id,
    MAX(CASE WHEN p.product_name = 'The Original Mr. Fuzzy' THEN 1 ELSE 0 END) AS bought_mr_fuzzy,
    MAX(CASE WHEN p.product_name = 'The Forever Love Bear' THEN 1 ELSE 0 END) AS bought_forever_love_bear,
    MAX(CASE WHEN p.product_name = 'The Birthday Sugar Panda' THEN 1 ELSE 0 END) AS bought_birthday_sugar_panda,
    MAX(CASE WHEN p.product_name = 'The Hudson River Mini bear' THEN 1 ELSE 0 END) AS bought_hudson_river_bear
  FROM `nimble-theme-498523-f3.toystore.orders` o
  JOIN `nimble-theme-498523-f3.toystore.order_items` i ON o.order_id = i.order_id
  JOIN `nimble-theme-498523-f3.toystore.products` p ON p.product_id = i.product_id
  GROUP BY o.website_session_id
),

totals AS (
  SELECT
    SUM(bought_mr_fuzzy) AS mr_fuzzy,
    SUM(bought_forever_love_bear) AS forever_love_bear,
    SUM(bought_birthday_sugar_panda) AS birthday_sugar_panda,
    SUM(bought_hudson_river_bear) AS hudson_river_bear,
    SUM(bought_mr_fuzzy + bought_forever_love_bear + bought_birthday_sugar_panda + bought_hudson_river_bear) AS total_items
  FROM purchases
)

SELECT
  total_items,
  mr_fuzzy,
  forever_love_bear,
  birthday_sugar_panda,
  hudson_river_bear,
  ROUND(mr_fuzzy * 100.0 / total_items, 2) AS mr_fuzzy_pct,
  ROUND(forever_love_bear * 100.0 / total_items, 2) AS forever_love_bear_pct,
  ROUND(birthday_sugar_panda * 100.0 / total_items, 2) AS birthday_sugar_panda_pct,
  ROUND(hudson_river_bear * 100.0 / total_items, 2) AS hudson_river_bear_pct
FROM totals


--Single Vs Multi Item Purchases
SELECT 
  COUNT(*) AS total_orders,
  SUM(CASE WHEN items_purchased = 1 THEN 1 ELSE 0 END) AS single_purchases,
  SUM(CASE WHEN items_purchased > 1 THEN 1 ELSE 0 END) AS multiple_purchases,
  ROUND(SUM(CASE WHEN items_purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS single_purchase_pct,
  ROUND(SUM(CASE WHEN items_purchased > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS multi_purchase_pct,
  ROUND(AVG(items_purchased), 2) AS avg_items_per_order
FROM `nimble-theme-498523-f3.toystore.orders`


--Primary Order Breakdown
WITH primary_orders AS (
  SELECT 
    primary_product_id,
    COUNT(*) AS total_primary_item_adds
  FROM `nimble-theme-498523-f3.toystore.orders` 
  GROUP BY primary_product_id
)

SELECT 
  p.product_name,
  o.total_primary_item_adds,
  ROUND(o.total_primary_item_adds * 100.0 / SUM(o.total_primary_item_adds) OVER(), 2) AS pct_of_orders
FROM primary_orders o
JOIN `nimble-theme-498523-f3.toystore.products` p
  ON o.primary_product_id = p.product_id
ORDER BY total_primary_item_adds DESC

--Billing Page Comparison
WITH toys AS (
  SELECT 
    website_session_id,
    MAX(CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END) AS billing,
    MAX(CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END) AS billing_two,
    MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS converted
  FROM `nimble-theme-498523-f3.toystore.website_pageviews` 
  GROUP BY website_session_id
),

counts AS (
  SELECT
    SUM(billing) AS billing_sessions,
    SUM(billing_two) AS billing_two_sessions,
    SUM(billing + billing_two) AS total_sessions,
    SUM(CASE WHEN billing = 1 AND converted = 1 THEN 1 ELSE 0 END) AS billing_conversions,
    SUM(CASE WHEN billing_two = 1 AND converted = 1 THEN 1 ELSE 0 END) AS billing_two_conversions,
    SUM(CASE WHEN (billing = 1 OR billing_two = 1) AND converted = 1 THEN 1 ELSE 0 END) AS total_conversions
  FROM toys
)

SELECT
  billing_sessions,
  billing_two_sessions,
  billing_conversions,
  billing_two_conversions,

  -- conversion rates per variant
  ROUND(billing_conversions * 100.0 / NULLIF(billing_sessions, 0), 2) AS billing_cvr,
  ROUND(billing_two_conversions * 100.0 / NULLIF(billing_two_sessions, 0), 2) AS billing_two_cvr,

  -- pooled conversion rate
  ROUND(total_conversions * 100.0 / NULLIF(total_sessions, 0), 2) AS pooled_cvr,

  -- expected conversions for chi-square
  ROUND(billing_sessions * total_conversions / NULLIF(total_sessions, 0), 2) AS billing_expected,
  ROUND(billing_two_sessions * total_conversions / NULLIF(total_sessions, 0), 2) AS billing_two_expected

FROM counts

--Checkout Funnel

WITH journey AS (
  SELECT
    website_session_id,
    MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS saw_cart,
    MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS saw_shipping,
    MAX(CASE WHEN pageview_url IN ('/billing', '/billing-2') THEN 1 ELSE 0 END) AS saw_billing,
    MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS converted
  FROM `nimble-theme-498523-f3.toystore.website_pageviews`
  GROUP BY website_session_id
)

SELECT
  SUM(saw_cart) AS cart,
  SUM(saw_shipping) AS shipping,
  SUM(saw_billing) AS billing,
  SUM(converted) AS orders,

  ROUND(SUM(saw_shipping) * 100.0 / NULLIF(SUM(saw_cart), 0), 2) AS cart_to_shipping_rate,
  ROUND(SUM(saw_billing) * 100.0 / NULLIF(SUM(saw_shipping), 0), 2) AS shipping_to_billing_rate,
  ROUND(SUM(converted) * 100.0 / NULLIF(SUM(saw_billing), 0), 2) AS billing_to_order_rate,
  ROUND(SUM(converted) * 100.0 / NULLIF(SUM(saw_cart), 0), 2) AS overall_checkout_cvr

FROM journey
