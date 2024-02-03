SELECT * FROM customer_orders_temp;
SELECT * FROM runner_orders_temp;
SELECT * FROM pizza_toppings;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_names;
SELECT * FROM runner_toppings;
SELECT * FROM runners;

/* Case Study Questions

1. What are the standard ingredients for each pizza?
2. What was the most commonly added extra?
3. What was the most common exclusion?
4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

*/

## Temporary tables created to solve the below queries
# 

DROP TABLE row_split_customer_orders_temp;

CREATE
TEMPORARY TABLE row_split_customer_orders_temp AS
SELECT t.row_num,
       t.order_id,
       t.customer_id,
       t.pizza_id,
       trim(j1.exclusions) AS exclusions,
       trim(j2.extras) AS extras,
       t.order_time
FROM
  (SELECT *,
          row_number() over() AS row_num
   FROM customer_orders_temp) t
INNER JOIN json_table(trim(replace(json_array(t.exclusions), ',', '","')),
                      '$[*]' columns (exclusions varchar(50) PATH '$')) j1 /* This part processes the exclusions column. It first converts the JSON array in t.exclusions into a comma-separated string, then replaces the commas with '","'. 
																			 This is a way of ensuring that the JSON data is correctly formatted for the json_table function. It's then split and transformed using json_table, and the result is aliased as j1.*/
INNER JOIN json_table(trim(replace(json_array(t.extras), ',', '","')),
                      '$[*]' columns (extras varchar(50) PATH '$')) j2 ;


SELECT *
FROM row_split_customer_orders_temp;

# Pizza recip temporary table

DROP TABLE row_split_pizza_recipes_temp;

CREATE
TEMPORARY TABLE row_split_pizza_recipes_temp AS
SELECT t.pizza_id,
       trim(j.topping) AS topping_id
FROM pizza_recipes t
JOIN json_table(trim(replace(json_array(t.toppings), ',', '","')),
                '$[*]' columns (topping varchar(50) PATH '$')) j ;


SELECT *
FROM row_split_pizza_recipes_temp;

# Ingredients temporary table

DROP TABLE IF EXISTS standard_ingredients;

CREATE
TEMPORARY TABLE standard_ingredients AS
SELECT pizza_id,
       pizza_name,
       group_concat(DISTINCT topping_name) 'standard_ingredients'
FROM row_split_pizza_recipes_temp
INNER JOIN pizza_names USING (pizza_id)
INNER JOIN pizza_toppings USING (topping_id)
GROUP BY pizza_name
ORDER BY pizza_id;

SELECT *
FROM standard_ingredients;


###  1. What are the standard ingredients for each pizza?

SELECT *
FROM standard_ingredients;

###  2. What was the most commonly added extra?

WITH extra_count_cte AS
  (SELECT trim(extras) AS extra_topping,
          count(*) AS purchase_counts
   FROM row_split_customer_orders_temp
   WHERE extras IS NOT NULL
   GROUP BY extras)
SELECT topping_name,
       purchase_counts
FROM extra_count_cte AS E
INNER JOIN pizza_toppings AS P ON E.extra_topping = P.topping_id
LIMIT 1;

###  3. What was the most common exclusion?

WITH extra_count_cte AS
  (SELECT trim(exclusions) AS extra_topping,
          count(*) AS purchase_counts
   FROM row_split_customer_orders_temp
   WHERE exclusions IS NOT NULL
   GROUP BY exclusions)
SELECT topping_name,
       purchase_counts
FROM extra_count_cte E
INNER JOIN pizza_toppings P ON E.extra_topping = P.topping_id
LIMIT 1;


###  4. Generate an order item for each record in the customers_orders table in the format of one of the following:
/*
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

WITH order_summary_cte AS
  (SELECT pizza_name,
          row_num,
          order_id,
          customer_id,
          excluded_topping,
          t2.topping_name AS extras_topping
   FROM
     (SELECT *,
             topping_name AS excluded_topping
      FROM row_split_customer_orders_temp
      LEFT JOIN standard_ingredients USING (pizza_id)
      LEFT JOIN pizza_toppings ON topping_id = exclusions) t1
   LEFT JOIN pizza_toppings t2 ON t2.topping_id = extras)
SELECT order_id,
       customer_id,
       CASE
           WHEN excluded_topping IS NULL
                AND extras_topping IS NULL THEN pizza_name
           WHEN extras_topping IS NULL
                AND excluded_topping IS NOT NULL THEN concat(pizza_name, ' - Exclude ', GROUP_CONCAT(DISTINCT excluded_topping))
           WHEN excluded_topping IS NULL
                AND extras_topping IS NOT NULL THEN concat(pizza_name, ' - Include ', GROUP_CONCAT(DISTINCT extras_topping))
           ELSE concat(pizza_name, ' - Include ', GROUP_CONCAT(DISTINCT extras_topping), ' - Exclude ', GROUP_CONCAT(DISTINCT excluded_topping))
       END AS order_item
FROM order_summary_cte
GROUP BY row_num;

###  5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
# For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"



###  6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

