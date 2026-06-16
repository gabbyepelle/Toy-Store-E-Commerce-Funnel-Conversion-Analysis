-- AWARENESS: Session Overview

--How many new vs repeat customers?
SELECT
  COUNT(DISTINCT website_session_id) AS total_sessions,
  SUM(CASE WHEN is_repeat_session = 0 THEN 1 ELSE 0 END) AS new_sessions,
  SUM(CASE WHEN is_repeat_session = 1 THEN 1 ELSE 0 END) AS repeat_sessions,
  ROUND(SUM(CASE WHEN is_repeat_session = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS new_pct,
  ROUND(SUM(CASE WHEN is_repeat_session = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_pct
FROM `nimble-theme-498523-f3.toystore.website_sessions`



--what are the sources of traffic?

SELECT
  COALESCE(utm_source, 'direct/organic') AS utm_source,
  COALESCE(utm_campaign, 'none') AS utm_campaign,
  COUNT(*) AS sessions,
  SUM(CASE WHEN is_repeat_session = 0 THEN 1 ELSE 0 END) AS new_sessions,
  SUM(CASE WHEN is_repeat_session = 1 THEN 1 ELSE 0 END) AS repeat_sessions,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `nimble-theme-498523-f3.toystore.website_sessions`
GROUP BY 1, 2
ORDER BY sessions DESC


--Overall Bounce Rate
WITH bounces AS (
SELECT 
website_session_id,
COUNT(pageview_url) AS pages_viewed
FROM `nimble-theme-498523-f3.toystore.website_pageviews` 
GROUP BY website_session_id 
)

SELECT COUNT(*) AS total_sessions,
SUM(CASE WHEN pages_viewed = 1 THEN 1 ELSE 0 END ) AS bounced_sessions,
ROUND(SUM(CASE WHEN pages_viewed = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS bounce_rate
FROM bounces


WITH ranked AS (
  SELECT
    website_session_id,
    pageview_url,
    COUNT(pageview_url) OVER(PARTITION BY website_session_id) AS pages_viewed,
    RANK() OVER(PARTITION BY website_session_id ORDER BY created_at) AS page_rank
  FROM `nimble-theme-498523-f3.toystore.website_pageviews`
)

--Bounce Rate By Lander
SELECT
  pageview_url,
  COUNT(DISTINCT website_session_id) AS sessions,
  SUM(CASE WHEN pages_viewed = 1 THEN 1 ELSE 0 END) AS bounced_sessions,
  ROUND(SUM(CASE WHEN pages_viewed = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT website_session_id), 2) AS bounce_rate
FROM ranked
WHERE page_rank = 1
GROUP BY pageview_url
ORDER BY sessions DESC

