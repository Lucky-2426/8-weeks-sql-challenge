-- Active: 1706953706370@@localhost@3306@dannys_diner

-- Creating the database on my personal laptop using MySQL Workbench
CREATE SCHEMA dannys_diner;

-- Creating tables in the database
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);


CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);


CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

-- Inserting data into the tables
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


INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  

--- Solving different questions

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

-- 7. Which item was purchased just before the customer became a member?
-- Asssumption: Since timestamp of purchase is not available, purchase made when order_date is before the join date is used to find the last item purchased just before the customer became a member

WITH diner_info AS
  (SELECT product_name,
          s.customer_id,
          order_date,
          join_date,
          m.product_id,
          DENSE_RANK() OVER(PARTITION BY s.customer_id
                            ORDER BY s.order_date DESC) AS item_rank
   FROM dannys_diner.menu AS m
   INNER JOIN dannys_diner.sales AS s ON m.product_id = s.product_id
   INNER JOIN dannys_diner.members AS mem ON mem.customer_id = s.customer_id
   WHERE order_date < join_date )
SELECT customer_id,
       product_name,
       order_date,
       join_date
FROM diner_info
WHERE item_rank=1;

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
-- Assumption: Points is rewarded only after the customer joins in the membership program

-- Steps
-- 1. Find the program_last_date which is 7 days after a customer joins the program (including their join date)
-- 2. Determine the customer points for each transaction and for members with a membership
-- 		a. During the first week of the membership -> points = price*20 irrespective of the purchase item
-- 		b. Product = Sushi -> and order_date is not within a week of membership -> points = price*20
-- 		c. Product = Not Sushi -> and order_date is not within a week of membership -> points = price*10
-- 3. Conditions in WHERE clause
-- 		a. order_date <= '2021-01-31' -> Order must be placed before 31st January 2021
-- 		b. order_date >= join_date -> Points awarded to only customers with a membership

WITH program_last_day_cte AS
  (SELECT join_date,
          DATE_ADD(join_date, INTERVAL 7 DAY) AS program_last_date,
          customer_id
   FROM dannys_diner.members)
SELECT s.customer_id,
       SUM(CASE
               WHEN order_date BETWEEN join_date AND program_last_date THEN price*10*2
               WHEN order_date NOT BETWEEN join_date AND program_last_date
                    AND product_name = 'sushi' THEN price*10*2
               WHEN order_date NOT BETWEEN join_date AND program_last_date
                    AND product_name != 'sushi' THEN price*10
           END) AS customer_points
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s ON m.product_id = s.product_id
INNER JOIN program_last_day_cte AS mem ON mem.customer_id = s.customer_id
AND order_date <='2021-01-31'
AND order_date >=join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- Join all the things
Select s.customer_id, s.order_date, me.product_name, me.price, IF(m.join_date < s.order_date, "Y", "N") as membership
FROM sales as s
LEFT JOIN members as m
ON s.customer_id = m.customer_id
JOIN menu as me
ON s.product_id = me.product_id
GROUP BY m.customer_id, s.order_date, me.product_name, me.price
ORDER BY s.customer_id;

-- Testing queries
SELECT * from members;
SELECT * from sales;
SELECT * from menu;
