-- ============================================================
-- STAGE 3: CONVERSION
-- How many sessions make it through the checkout funnel?
-- ============================================================


-- Full Checkout Funnel
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
FROM journey;


-- Billing Page A/B Test
-- Tests whether the difference in conversion rate between /billing and
-- /billing-2 is statistically significant. Chi-square test run in Python.
-- Result: χ²=492.37, p<0.001 — billing-2 significantly outperforms billing.

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
  ROUND(billing_conversions * 100.0 / NULLIF(billing_sessions, 0), 2) AS billing_cvr,
  ROUND(billing_two_conversions * 100.0 / NULLIF(billing_two_sessions, 0), 2) AS billing_two_cvr,
  ROUND(total_conversions * 100.0 / NULLIF(total_sessions, 0), 2) AS pooled_cvr,
  ROUND(billing_sessions * total_conversions / NULLIF(total_sessions, 0), 2) AS billing_expected,
  ROUND(billing_two_sessions * total_conversions / NULLIF(total_sessions, 0), 2) AS billing_two_expected
FROM counts;


-- Lander Conversion Rate Comparison
-- Tests whether conversion rate differences across all 6 entry pages
-- are statistically significant. Chi-square test run in Python.
-- Result: χ²=3235.69, p<0.001 — significant differences across variants.
-- Post-hoc pairwise tests (Bonferroni corrected): 13/15 pairs significant.
-- /lander-4 was the only variant with no significant improvement over /home.

WITH toys AS (
  SELECT
    website_session_id,
    MAX(CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END) AS home,
    MAX(CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END) AS lander_one,
    MAX(CASE WHEN pageview_url = '/lander-2' THEN 1 ELSE 0 END) AS lander_two,
    MAX(CASE WHEN pageview_url = '/lander-3' THEN 1 ELSE 0 END) AS lander_three,
    MAX(CASE WHEN pageview_url = '/lander-4' THEN 1 ELSE 0 END) AS lander_four,
    MAX(CASE WHEN pageview_url = '/lander-5' THEN 1 ELSE 0 END) AS lander_five,
    MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS converted
  FROM `nimble-theme-498523-f3.toystore.website_pageviews`
  GROUP BY website_session_id
)

SELECT
  'home' AS variant, SUM(home) AS sessions, SUM(CASE WHEN home = 1 AND converted = 1 THEN 1 ELSE 0 END) AS conversions, SUM(home) - SUM(CASE WHEN home = 1 AND converted = 1 THEN 1 ELSE 0 END) AS non_conversions, ROUND(SUM(CASE WHEN home = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(home), 0), 2) AS cvr FROM toys
UNION ALL
SELECT 'lander_1', SUM(lander_one), SUM(CASE WHEN lander_one = 1 AND converted = 1 THEN 1 ELSE 0 END), SUM(lander_one) - SUM(CASE WHEN lander_one = 1 AND converted = 1 THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN lander_one = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(lander_one), 0), 2) FROM toys
UNION ALL
SELECT 'lander_2', SUM(lander_two), SUM(CASE WHEN lander_two = 1 AND converted = 1 THEN 1 ELSE 0 END), SUM(lander_two) - SUM(CASE WHEN lander_two = 1 AND converted = 1 THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN lander_two = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(lander_two), 0), 2) FROM toys
UNION ALL
SELECT 'lander_3', SUM(lander_three), SUM(CASE WHEN lander_three = 1 AND converted = 1 THEN 1 ELSE 0 END), SUM(lander_three) - SUM(CASE WHEN lander_three = 1 AND converted = 1 THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN lander_three = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(lander_three), 0), 2) FROM toys
UNION ALL
SELECT 'lander_4', SUM(lander_four), SUM(CASE WHEN lander_four = 1 AND converted = 1 THEN 1 ELSE 0 END), SUM(lander_four) - SUM(CASE WHEN lander_four = 1 AND converted = 1 THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN lander_four = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(lander_four), 0), 2) FROM toys
UNION ALL
SELECT 'lander_5', SUM(lander_five), SUM(CASE WHEN lander_five = 1 AND converted = 1 THEN 1 ELSE 0 END), SUM(lander_five) - SUM(CASE WHEN lander_five = 1 AND converted = 1 THEN 1 ELSE 0 END), ROUND(SUM(CASE WHEN lander_five = 1 AND converted = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(lander_five), 0), 2) FROM toys

ORDER BY cvr DESC;
