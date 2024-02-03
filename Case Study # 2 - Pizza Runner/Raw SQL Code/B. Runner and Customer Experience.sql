SELECT * FROM customer_orders_temp;
SELECT * FROM runner_orders_temp;
SELECT * FROM runners;

/* Case Study Questions

1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
4. What was the average distance travelled for each customer?
5. What was the difference between the longest and shortest delivery times for all orders?
6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
7. What is the successful delivery percentage for each runner?

*/

/*  1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
- Returned week number is between 0 and 52 or 0 and 53.
- Default mode of the week = 0 -> First day of the week is Sunday
- Extract week -> WEEK(registration_date) or EXTRACT(week from registration_date) */

SELECT week(registration_date) as 'Week of registration',
       count(runner_id) as 'Number of runners'
FROM runners
GROUP BY 1;

###  2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT runner_id,
       round(avg(TIMESTAMPDIFF(MINUTE, order_time, pickup_time)), 0) avg_runner_pickup_time # rounded to 0 decimal place
FROM runner_orders_temp
INNER JOIN customer_orders_temp USING (order_id)
WHERE cancellation IS NULL # only for command without cancellation
GROUP BY runner_id;

###  3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH order_count_cte AS
  (SELECT order_id,
          COUNT(order_id) AS pizzas_order_count, order_time, pickup_time,
          TIMESTAMPDIFF(MINUTE, order_time, pickup_time) AS prep_time # prep_time = pickup_time - order_time
   FROM runner_orders_temp
   INNER JOIN customer_orders_temp USING (order_id)
   WHERE cancellation IS NULL
   GROUP BY order_id) # create a CTE to calculate the preparation time per order.
SELECT pizzas_order_count,
       round(avg(prep_time), 2) as 'Avg_prep_time' # then calculate the average per number of pizza ordered (1, 2 or 3)
FROM order_count_cte
GROUP BY pizzas_order_count;

###  4. What was the average distance travelled for each customer?

SELECT customer_id,
       round(avg(distance), 2) AS 'average_distance_travelled'
FROM runner_orders_temp
INNER JOIN customer_orders_temp USING (order_id)
WHERE cancellation IS NULL
GROUP BY customer_id;

###  5. What was the difference between the longest and shortest delivery times for all orders?

SELECT MIN(duration) AS minimum_duration,
       MAX(duration) AS maximum_duration,
       MAX(duration) - MIN(duration) AS maximum_difference
FROM runner_orders_temp;

###  6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT runner_id,
       distance AS distance_km,
       round(duration/60, 2) AS duration_hr,
       round(distance*60/duration, 2) AS average_speed # s = distance / duration
FROM runner_orders_temp
WHERE cancellation IS NULL
ORDER BY runner_id;

###  7. What is the successfull delivery percentage for each runner?

SELECT runner_id,
		COUNT(*) AS total_orders,
		COUNT(pickup_time) AS delivered_orders,
        COUNT(cancellation) AS cancelled_orders,
		ROUND(100 * COUNT(pickup_time) / COUNT(*)) AS delivery_success_percentage
FROM runner_orders_temp
GROUP BY runner_id
ORDER BY runner_id;
