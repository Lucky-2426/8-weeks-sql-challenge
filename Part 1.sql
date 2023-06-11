-- Creating the database on my personal laptop using MySQL Workbench
CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
-- 1. What is the total amount each customer spent at the restaurant? 
WITH price_per_product_bought AS
	(Select customer_id, s.product_id, count(s.product_id) as number_of_commands, m.price
	FROM sales as s
	INNER JOIN menu as m
	ON s.product_id = m.product_id
	GROUP BY customer_id, product_id)
	
SELECT 
    customer_id,
    SUM(price * number_of_commands) AS total_per_client
FROM
    price_per_product_bought
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT 
    customer_id, COUNT(DISTINCT order_date) AS Number_of_visits
FROM
    sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH ranked_purchase 
AS 
	(SELECT s.*,m.product_name, RANK() OVER(
						PARTITION BY customer_id
						ORDER BY order_date
						) rank_purchase					
	FROM sales as s
    INNER JOIN menu as m
    ON s.product_id = m.product_id)
SELECT customer_id, product_name FROM ranked_purchase WHERE rank_purchase = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    s.product_id,
    m.product_name,
    COUNT(s.product_id) AS number_of_purchase
FROM
    sales as s
INNER JOIN 
	menu as m
ON m.product_id = s.product_id
GROUP BY product_id
ORDER BY COUNT(s.product_id) DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH max_per_customer
AS
	(SELECT 
		s.customer_id,
		s.product_id,
		m.product_name,
		COUNT(s.product_id) AS number_of_purchase
	FROM
		sales AS s
			INNER JOIN
		menu AS m ON m.product_id = s.product_id
	GROUP BY s.customer_id , s.product_id
	ORDER BY s.customer_id , COUNT(s.product_id) DESC)
, ranking AS
	(SELECT *, RANK() OVER(
							PARTITION BY customer_id
							ORDER BY number_of_purchase DESC
							) rank_max_purchase
	FROM max_per_customer)
SELECT customer_id, product_name, number_of_purchase FROM ranking WHERE rank_max_purchase =  1;

-- 6. Which item was purchased first by the customer after they became a member?
with purchases_after_membership as (
		SELECT s.*, m.join_date
		FROM sales as s
		JOIN members as m
		ON m.customer_id = s.customer_id
		WHERE s.order_date > m.join_date)
SELECT p.customer_id, MIN(order_date),  p.product_id, m.product_name
FROM purchases_after_membership as p
INNER JOIN menu as m 
ON p.product_id = m.product_id
GROUP BY p.customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
with purchases_after_membership as (
		SELECT s.*, m.join_date
		FROM sales as s
		JOIN members as m
		ON m.customer_id = s.customer_id
		WHERE s.order_date < m.join_date)
SELECT p.customer_id,  COUNT(p.product_id) as Total_items , ((m.price) * COUNT(p.product_id)) as Amount_spent
FROM purchases_after_membership as p
INNER JOIN menu as m 
ON p.product_id = m.product_id
GROUP BY p.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with orders AS
(SELECT m.customer_id, s.product_id, COUNT(s.product_id) as Number_of_order
FROM members as m
INNER JOIN sales as s
ON m.customer_id = s.customer_id
GROUP BY m.customer_id, s.product_id)

SELECT o.customer_id, 10 * SUM((o.Number_of_order) * 
CASE o.product_id
	WHEN 1 THEN (me.price * 2)
    ELSE me.price
END) as Total_points
FROM orders as o
INNER JOIN menu as me
ON o.product_id = me.product_id
GROUP BY o.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- Join all the things
Select s.customer_id, s.order_date, me.product_name, me.price, IF(m.join_date < s.order_date, "Y", "N") as membership
FROM sales as s
LEFT JOIN members as m
ON s.customer_id = m.customer_id
JOIN menu as me
ON s.product_id = me.product_id
GROUP BY m.customer_id, s.order_date, me.product_name, me.price
ORDER BY s.customer_id;

-- Ranking all the things


-- Testing queries
SELECT * from members;
SELECT * from sales;
SELECT * from menu;