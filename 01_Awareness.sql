-- ============================================================
-- STAGE 1: AWARENESS
-- How many people are finding the site and where are they coming from?
-- ============================================================


-- New vs Repeat Sessions
SELECT
  COUNT(DISTINCT website_session_id) AS total_sessions,
  SUM(CASE WHEN is_repeat_session = 0 THEN 1 ELSE 0 END) AS new_sessions,
  SUM(CASE WHEN is_repeat_session = 1 THEN 1 ELSE 0 END) AS repeat_sessions,
  ROUND(SUM(CASE WHEN is_repeat_session = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS new_pct,
  ROUND(SUM(CASE WHEN is_repeat_session = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_pct
FROM `nimble-theme-498523-f3.toystore.website_sessions`;


-- Traffic Sources Breakdown
SELECT
  COALESCE(utm_source, 'direct/organic') AS utm_source,
  COALESCE(utm_campaign, 'none') AS utm_campaign,
  COUNT(*) AS sessions,
  SUM(CASE WHEN is_repeat_session = 0 THEN 1 ELSE 0 END) AS new_sessions,
  SUM(CASE WHEN is_repeat_session = 1 THEN 1 ELSE 0 END) AS repeat_sessions,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `nimble-theme-498523-f3.toystore.website_sessions`
GROUP BY 1, 2
ORDER BY sessions DESC;


-- Lander Launch Timeline
SELECT
  pageview_url,
  MIN(created_at) AS first_seen
FROM `nimble-theme-498523-f3.toystore.website_pageviews`
WHERE pageview_url LIKE '/lander%'
  OR pageview_url = '/home'
GROUP BY pageview_url
ORDER BY first_seen;


-- Overall Bounce Rate
WITH bounces AS (
  SELECT
    website_session_id,
    COUNT(pageview_url) AS pages_viewed
  FROM `nimble-theme-498523-f3.toystore.website_pageviews`
  GROUP BY website_session_id
)

SELECT
  COUNT(*) AS total_sessions,
  SUM(CASE WHEN pages_viewed = 1 THEN 1 ELSE 0 END) AS bounced_sessions,
  ROUND(SUM(CASE WHEN pages_viewed = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS bounce_rate
FROM bounces;


-- Bounce Rate by Entry Page
WITH ranked AS (
  SELECT
    website_session_id,
    pageview_url,
    COUNT(pageview_url) OVER(PARTITION BY website_session_id) AS pages_viewed,
    RANK() OVER(PARTITION BY website_session_id ORDER BY created_at) AS page_rank
  FROM `nimble-theme-498523-f3.toystore.website_pageviews`
)

SELECT
  pageview_url,
  COUNT(DISTINCT website_session_id) AS sessions,
  SUM(CASE WHEN pages_viewed = 1 THEN 1 ELSE 0 END) AS bounced_sessions,
  ROUND(SUM(CASE WHEN pages_viewed = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT website_session_id), 2) AS bounce_rate
FROM ranked
WHERE page_rank = 1
GROUP BY pageview_url
ORDER BY sessions DESC;


-- New vs Repeat Session Conversion Rate
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
