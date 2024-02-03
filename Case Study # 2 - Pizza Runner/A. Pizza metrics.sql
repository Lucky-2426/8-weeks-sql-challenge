-- Active: 1706953706370@@localhost@3306@pizza_runner
SELECT * FROM customer_orders;
SELECT * FROM runner_orders;
SELECT * FROM pizza_recipes;
SELECT * FROM customer_orders_temp;
SELECT * FROM runner_orders_temp;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_names;
SELECT * FROM runner_toppings;
SELECT * FROM runners;

/*

1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?

*/

###  1. How many pizzas were ordered?

SELECT count(pizza_id) AS "# of Pizzas Ordered"
FROM customer_orders;

###  2. How many unique customer orders were made?

SELECT 
  COUNT(DISTINCT order_id) AS '# of Unique Orders'
FROM customer_orders_temp; # because this temp table contains clean data

###  3. How many successful orders were delivered by each runner?

SELECT runner_id,
       count(order_id) AS '# of Successful Orders'
FROM runner_orders_temp # because this temp table contains clean data
WHERE cancellation IS NULL
GROUP BY runner_id;

###  4. How many of each type of pizza was delivered?

SELECT pizza_id,
       pizza_name,
       count(pizza_id) AS '# of Pizzas Delivered'
FROM runner_orders_temp # AS Ru
INNER JOIN customer_orders_temp USING (order_id) # or INNER JOIN customer_orders_temp as C ON C.order_id = Ru.order_id
INNER JOIN pizza_names USING (pizza_id)
WHERE cancellation IS NULL # means pizza has been delivered
GROUP BY pizza_id;

###  5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id,
       pizza_name,
       count(pizza_id) AS '# of Pizzas Ordered'
FROM customer_orders_temp
INNER JOIN pizza_names USING (pizza_id)
GROUP BY customer_id, pizza_id
ORDER BY customer_id;

# The counts of the Meat lover and Vegetarian pizzas ordered by the customers is not discernible.

SELECT customer_id,
       SUM(CASE
               WHEN pizza_id = 1 THEN 1
               ELSE 0
           END) AS 'Meat lover Pizza Count',
       SUM(CASE
               WHEN pizza_id = 2 THEN 1
               ELSE 0
           END) AS 'Vegetarian Pizza Count'
FROM customer_orders_temp
GROUP BY customer_id
ORDER BY customer_id;

###  6. What was the maximum number of pizzas delivered in a single order?

SELECT customer_id,
       order_id,
       count(order_id) AS pizza_count
FROM customer_orders_temp
GROUP BY order_id
ORDER BY pizza_count DESC
LIMIT 1;

/*  7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
- at least 1 change means either exclusion or extras 
- no changes means exclusion and extras are NULL */

SELECT customer_id,
       SUM(CASE
               WHEN (exclusions IS NOT NULL
                     OR extras IS NOT NULL) THEN 1
               ELSE 0
           END) AS change_in_pizza,
       SUM(CASE
               WHEN (exclusions IS NULL
                     AND extras IS NULL) THEN 1
               ELSE 0
           END) AS no_change_in_pizza
FROM customer_orders_temp
INNER JOIN runner_orders_temp USING (order_id)
WHERE cancellation IS NULL # orders with cancellation are excluded here
GROUP BY customer_id
ORDER BY customer_id;

###  8. How many pizzas were delivered that had both exclusions and extras?

SELECT customer_id,
       SUM(CASE
               WHEN (exclusions IS NOT NULL
                     AND extras IS NOT NULL) THEN 1
               ELSE 0
           END) AS both_change_in_pizza
FROM customer_orders_temp
INNER JOIN runner_orders_temp USING (order_id)
WHERE cancellation IS NULL # orders with cancellation are excluded here
GROUP BY customer_id
ORDER BY customer_id;

###  9. What was the total volume of pizzas ordered for each hour of the day?
# NB : Volume means percentage compared to the total orders

SELECT hour(order_time) AS 'Hour',
       count(order_id) AS '# of pizzas ordered',
       round(100*count(order_id) /sum(count(order_id)) over(), 2) AS 'Volume of pizzas ordered'
FROM customer_orders_temp
GROUP BY 1
ORDER BY 1;

/*  10. What was the volume of orders for each day of the week?
- NB : Volume means percentage compared to the total orders
- The DAYOFWEEK() function returns the weekday index for a given date ( 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday )
- DAYNAME() returns the name of the week day */

SELECT dayname(order_time) AS 'Day Of Week',
       count(order_id) AS '# of pizzas ordered',
       round(100*count(order_id) /sum(count(order_id)) over(), 2) AS 'Volume of pizzas ordered'
FROM pizza_runner.customer_orders_temp
GROUP BY 1
ORDER BY 2 DESC;