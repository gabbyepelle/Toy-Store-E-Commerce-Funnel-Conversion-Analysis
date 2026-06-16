--Refunds

SELECT 
  COUNT(o.order_id) AS total_orders,
  COUNT(r.order_item_refund_id) AS total_refunds,
  ROUND(COUNT(r.order_item_refund_id) * 100.0 / COUNT(*), 2) AS refund_pct
FROM `nimble-theme-498523-f3.toystore.orders` o
LEFT JOIN `nimble-theme-498523-f3.toystore.refunds` r
  ON o.order_id = r.order_id

--Refunds By Product
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
ORDER BY refund_pct DESC