--most popular bears
WITH toys AS (
 SELECT 
   website_session_id,
   MAX(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS saw_mr_fuzzy,
   MAX(CASE WHEN pageview_url = '/the-forever-love-bear' THEN 1 ELSE 0 END) AS saw_forever_love_bear,
   MAX(CASE WHEN pageview_url = '/the-birthday-sugar-panda' THEN 1 ELSE 0 END) AS saw_birthday_sugar_panda,
   MAX(CASE WHEN pageview_url = '/the-hudson-river-mini-bear' THEN 1 ELSE 0 END) AS saw_hudson_river_mini_bear,
   MAX(CASE WHEN pageview_url IN (
     '/the-original-mr-fuzzy',
     '/the-forever-love-bear',
     '/the-birthday-sugar-panda',
     '/the-hudson-river-mini-bear'
   ) THEN 1 ELSE 0 END) AS saw_a_product,
   MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS converted
 FROM `nimble-theme-498523-f3.toystore.website_pageviews` 
 GROUP BY website_session_id
)

SELECT 
 COUNT(*) AS total_sessions,
 SUM(saw_mr_fuzzy) AS viewed_mr_fuzzy,
 SUM(saw_forever_love_bear) AS viewed_forever_love_bear,
 SUM(saw_birthday_sugar_panda) AS viewed_birthday_sugar_panda,
 SUM(saw_hudson_river_mini_bear) AS viewed_hudson_river_mini_bear,
 SUM(saw_a_product) AS viewed_a_product,
 SUM(converted) AS total_conversions,

 -- product page conversion rates
 ROUND(SUM(CASE WHEN saw_mr_fuzzy = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(saw_mr_fuzzy), 0), 2) AS mr_fuzzy_cvr,
 ROUND(SUM(CASE WHEN saw_forever_love_bear = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(saw_forever_love_bear), 0), 2) AS forever_love_bear_cvr,
 ROUND(SUM(CASE WHEN saw_birthday_sugar_panda = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(saw_birthday_sugar_panda), 0), 2) AS birthday_sugar_panda_cvr,
 ROUND(SUM(CASE WHEN saw_hudson_river_mini_bear = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(saw_hudson_river_mini_bear), 0), 2) AS hudson_river_mini_bear_cvr,

 -- overall site conversion rate
 ROUND(SUM(converted) * 100.0 / COUNT(*), 2) AS overall_cvr

FROM toys
