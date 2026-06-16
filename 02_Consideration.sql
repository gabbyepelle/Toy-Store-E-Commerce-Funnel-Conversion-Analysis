-- ============================================================
-- STAGE 2: CONSIDERATION
-- Which products are users engaging with and how likely are they to buy?
-- ============================================================


-- Product Page Views
SELECT
  pageview_url,
  COUNT(DISTINCT website_session_id) AS sessions,
  ROUND(COUNT(DISTINCT website_session_id) * 100.0 / SUM(COUNT(DISTINCT website_session_id)) OVER(), 2) AS pct
FROM `nimble-theme-498523-f3.toystore.website_pageviews`
WHERE pageview_url IN (
  '/the-original-mr-fuzzy',
  '/the-forever-love-bear',
  '/the-birthday-sugar-panda',
  '/the-hudson-river-mini-bear'
)
GROUP BY pageview_url
ORDER BY sessions DESC;


-- Product Page Conversion Rates
-- Note: Views and purchases separated into distinct CTEs to avoid
-- excluding non-converting sessions from the denominator.
-- Hudson River Mini Bear CVR filtered to is_primary_item = 1 only,
-- as purchase volume exceeded page views due to its use as a cross-sell
-- add-on item following its launch in December 2014.

WITH views AS (
  SELECT
    website_session_id,
    MAX(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS saw_mr_fuzzy,
    MAX(CASE WHEN pageview_url = '/the-forever-love-bear' THEN 1 ELSE 0 END) AS saw_forever_love_bear,
    MAX(CASE WHEN pageview_url = '/the-birthday-sugar-panda' THEN 1 ELSE 0 END) AS saw_birthday_sugar_panda,
    MAX(CASE WHEN pageview_url = '/the-hudson-river-mini-bear' THEN 1 ELSE 0 END) AS saw_hudson_river_mini_bear
  FROM `nimble-theme-498523-f3.toystore.website_pageviews`
  GROUP BY website_session_id
),

purchases AS (
  SELECT
    o.website_session_id,
    MAX(CASE WHEN p.product_name = 'The Original Mr. Fuzzy' THEN 1 ELSE 0 END) AS bought_mr_fuzzy,
    MAX(CASE WHEN p.product_name = 'The Forever Love Bear' THEN 1 ELSE 0 END) AS bought_forever_love_bear,
    MAX(CASE WHEN p.product_name = 'The Birthday Sugar Panda' THEN 1 ELSE 0 END) AS bought_birthday_sugar_panda,
    MAX(CASE WHEN p.product_name = 'The Hudson River Mini bear' THEN 1 ELSE 0 END) AS bought_hudson_river_mini_bear
  FROM `nimble-theme-498523-f3.toystore.orders` o
  JOIN `nimble-theme-498523-f3.toystore.order_items` i ON i.order_id = o.order_id
  JOIN `nimble-theme-498523-f3.toystore.products` p ON p.product_id = i.product_id
  WHERE i.is_primary_item = 1
  GROUP BY o.website_session_id
),

combined AS (
  SELECT
    v.website_session_id,
    saw_mr_fuzzy,
    saw_forever_love_bear,
    saw_birthday_sugar_panda,
    saw_hudson_river_mini_bear,
    COALESCE(bought_mr_fuzzy, 0) AS bought_mr_fuzzy,
    COALESCE(bought_forever_love_bear, 0) AS bought_forever_love_bear,
    COALESCE(bought_birthday_sugar_panda, 0) AS bought_birthday_sugar_panda,
    COALESCE(bought_hudson_river_mini_bear, 0) AS bought_hudson_river_mini_bear
  FROM views v
  LEFT JOIN purchases p ON v.website_session_id = p.website_session_id
)

SELECT
  ROUND(SUM(bought_mr_fuzzy) * 100.0 / NULLIF(SUM(saw_mr_fuzzy), 0), 2) AS mr_fuzzy_cvr,
  ROUND(SUM(bought_forever_love_bear) * 100.0 / NULLIF(SUM(saw_forever_love_bear), 0), 2) AS forever_love_bear_cvr,
  ROUND(SUM(bought_birthday_sugar_panda) * 100.0 / NULLIF(SUM(saw_birthday_sugar_panda), 0), 2) AS birthday_sugar_panda_cvr,
  ROUND(SUM(bought_hudson_river_mini_bear) * 100.0 / NULLIF(SUM(saw_hudson_river_mini_bear), 0), 2) AS hudson_river_mini_bear_cvr
FROM combined;


-- Primary Product Breakdown
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
ORDER BY total_primary_item_adds DESC;


-- Cross-Sell: Single vs Multi-Item Orders
SELECT
  COUNT(*) AS total_orders,
  SUM(CASE WHEN items_purchased = 1 THEN 1 ELSE 0 END) AS single_item_orders,
  SUM(CASE WHEN items_purchased > 1 THEN 1 ELSE 0 END) AS multi_item_orders,
  ROUND(SUM(CASE WHEN items_purchased = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS single_item_pct,
  ROUND(SUM(CASE WHEN items_purchased > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS multi_item_pct,
  ROUND(AVG(items_purchased), 2) AS avg_items_per_order
FROM `nimble-theme-498523-f3.toystore.orders`;
