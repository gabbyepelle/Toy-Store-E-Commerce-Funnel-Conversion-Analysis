# Toy Store E-Commerce: Funnel & Conversion Analysis

## Overview

This project analyzes the customer purchase funnel for a toy store e-commerce platform, identifying where visitors drop off between landing on the site and completing a purchase. It combines SQL-based funnel modeling, statistical A/B testing, and a Tableau dashboard to discover and visualize actionable insights for marketing and product teams.

**Core question:** Where do customers drop off in the purchase funnel, and which design/landing page changes measurably improved conversion?

## Dataset

Source: [Maven Analytics Data Playground — Toy Store E-Commerce Database](https://mavenanalytics.io/data-playground)

Tables used:
- `website_sessions` — one row per visit, including traffic source (UTM parameters), device, and new vs. repeat session flags
- `website_pageviews` — one row per page load within a session
- `orders` — one row per completed order
- `order_items` — line items per order, including primary vs. add-on items
- `products` — product catalog
- `refunds` — refund records by order item

## Tools & Methods

- **BigQuery (SQL)** — all funnel modeling, aggregation, and cohort logic
- **Python (scipy)** — chi-square tests of independence for A/B test analysis
- **Tableau** — interactive dashboard and visualizations

## Project Structure

SQL queries are organized by funnel stage, following an Awareness → Consideration → Conversion → Post-Purchase framework:

| File | Contents |
|------|----------|
| `01_Awareness.sql` | Session volume, new vs. repeat split, traffic source breakdown, lander launch timeline, bounce rates |
| `02_Consideration.sql` | Product page views, product-level conversion rates, primary product mix, single vs. multi-item orders |
| `03_Conversion.sql` | Full checkout funnel (cart → shipping → billing → order), billing page A/B test, lander A/B test |
| `04_Post_Checkout.sql` | Average order value, profit margin, refund rates by product, new vs. repeat session conversion |

## Key Findings

### Awareness
- Paid search (`gsearch nonbrand`) drives the majority of traffic, accounting for roughly 60% of all sessions
- Roughly 18% of sessions arrive with no UTM tags (direct/organic traffic)
- The site launched with a single `/home` landing page in March 2012, followed by five additional lander variants introduced sequentially through August 2014

### Engagement
- Site-wide bounce rate is approximately 44%
- Bounce rates vary meaningfully by entry page, with `/lander-5` showing the lowest bounce rate of all variants

### Consideration
- Product page conversion rates range from roughly 15% to 22% depending on the product
- The Hudson River Mini Bear, launched late in the dataset (December 2014), shows purchase volume exceeding its product page views — investigation confirmed it was primarily sold as a cross-sell add-on item rather than through direct product page traffic. Its conversion rate was recalculated using only primary item purchases to correct for this.
- Roughly 24% of orders contain more than one item

### Conversion
- The checkout funnel shows the largest single drop-off between cart and billing, with just over half of cart sessions proceeding to billing
- Overall cart-to-order conversion rate is in the single digits, consistent with typical e-commerce benchmarks

### Post-Purchase
- Average order value and profit margin are calculated at the order level to avoid double-counting from multi-item orders
- Refund rates vary by product, with no single product showing an outsized refund rate
- Repeat sessions convert at a meaningfully higher rate than new sessions

## A/B Testing & Statistical Analysis

### Billing Page Redesign (`/billing` vs. `/billing-2`)

A chi-square test of independence was conducted to compare conversion rates between the original billing page and its redesign.

- **Billing CVR:** 44.79% (n=3,617)
- **Billing-2 CVR:** 63.36% (n=48,441)
- **Result:** χ² = 492.37, p < 0.001 — statistically significant
- **Lift:** +18.57 percentage points

**Limitation:** The two variants were not run concurrently — `/billing` was used early in the dataset and `/billing-2` later, with substantially unbalanced sample sizes. This is an observational comparison rather than a randomized controlled experiment, so the result should be interpreted as strong association rather than proven causation.

### Landing Page Iterations (`/home` through `/lander-5`)

A chi-square test of independence was conducted across all six entry page variants, followed by pairwise post-hoc tests with a Bonferroni correction (α = 0.05/15 = 0.0033).

- **Overall result:** χ² = 3235.69, p < 0.001 — significant differences exist across variants
- **Pairwise results:** 13 of 15 pairwise comparisons were statistically significant
- **Lander-5** achieved the highest CVR (10.17%), a 44% relative improvement over the original `/home` page (7.06%)
- **Lander-4** showed no statistically significant difference from `/home` (p = 0.0798) or from `/lander-2` (p = 0.5471) — this iteration did not improve on prior performance
- Lander iteration was non-linear: lander-1 and lander-3 underperformed the original homepage before lander-5 delivered the strongest result

## Data Quality Notes

- **Hudson River Mini Bear:** Purchase counts exceeded page view counts due to its use as a secondary/cross-sell item. Conversion rate calculations were restricted to primary item purchases (`is_primary_item = 1`) to correct this.
- **March 2015 (final month of data):** The dataset ends on 2015-03-19, so March 2015 contains only 19 days of activity. This partial month was excluded from the month-over-month revenue trend to avoid a misleading apparent decline.
- **UTM nulls:** Null values in `utm_source` and `utm_campaign` represent direct/organic traffic (no tracking parameters present), not missing or corrupted data, and were relabeled accordingly.

## Dashboard

A Tableau dashboard visualizing the visitor funnel, revenue by traffic source, and month-over-month revenue trends.

https://public.tableau.com/app/profile/gabrielle.epelle/viz/Toystore-Sales-Analysis/Dashboard1
## Recommendations

1. **Invest further in lander-5's design approach.** It is the only iteration to deliver a statistically significant improvement over the original homepage, suggesting its design elements (messaging, layout, or CTA placement) should inform future landing page work.
2. **Prioritize the cart-to-billing transition.** This is the single largest drop-off point in the checkout funnel and represents the highest-leverage opportunity for conversion rate optimization.
3. **Roll out the `/billing-2` design as the default**, given its strong association with higher checkout completion, while running a properly randomized follow-up test to confirm causation before further investment.
