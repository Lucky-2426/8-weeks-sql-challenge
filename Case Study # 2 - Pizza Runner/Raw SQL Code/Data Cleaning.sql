-- Active: 1706953706370@@localhost@3306@pizza_runner
## 1. customer_orders table
/* 
- The exclusions and extras columns in customer_orders table will need to be cleaned up before using them in the queries  
- In the exclusions and extras columns, there are blank spaces and null values.
*/

DROP TABLE IF EXISTS customer_orders_temp;

CREATE TEMPORARY TABLE customer_orders_temp AS
SELECT order_id,
       customer_id,
       pizza_id,
       CASE
           WHEN exclusions = '' THEN NULL
           WHEN exclusions = 'null' THEN NULL
           ELSE exclusions
       END AS exclusions,
       CASE
           WHEN extras = '' THEN NULL
           WHEN extras = 'null' THEN NULL
           ELSE extras
       END AS extras,
       order_time
FROM customer_orders;

SELECT * FROM customer_orders_temp;

## 2. runner_orders table
/*
The pickup_time, distance, duration and cancellation columns in runner_orders table will need to be cleaned up before using them in the queries  
- In the pickup_time column, there are null values.
- In the distance column, there are null values. It contains unit - km. The 'km' must also be stripped 
- In the duration column, there are null values. The 'minutes', 'mins' 'minute' must be stripped
- In the cancellation column, there are blank spaces and null values. 
*/

DROP TABLE IF EXISTS runner_orders_temp;

CREATE TEMPORARY TABLE runner_orders_temp AS

SELECT order_id,
       runner_id,
       CASE
           WHEN pickup_time LIKE 'null' THEN NULL
           ELSE pickup_time
       END AS pickup_time,
       CASE
           WHEN distance LIKE 'null' THEN NULL
           ELSE CAST(regexp_replace(distance, '[a-z]+', '') AS FLOAT) 
           /* This uses the regexp_replace function to search for and remove any sequences of lowercase letters (a through z) in the "distance" column. 
           For each row in the column 'distance', it effectively removes any non-numeric characters from the "distance" string. 
           For example, if "distance" contains "12.34 miles," this function will transform it into "12.34" by removing " miles." */
           
       END AS distance,
       CASE
           WHEN duration LIKE 'null' THEN NULL
           ELSE CAST(regexp_replace(duration, '[a-z]+', '') AS FLOAT)
       END AS duration,
       CASE
           WHEN cancellation LIKE '' THEN NULL
           WHEN cancellation LIKE 'null' THEN NULL
           ELSE cancellation
       END AS cancellation
FROM runner_orders;

SELECT * FROM runner_orders_temp;

# 3. Expanding the comma separated string into rows

## pizza_recipes table

/*
The toppings column in the pizza_recipes table is a comma separated string.

### Method 1: Using a Procedure
- A temporary table is created by calling a procedure which stores the pizza id and the topping in a separate row by splitting the comma separated string into multiple rows.
- String functions are used to split the string
*/

DROP TABLE IF EXISTS pizza_recipes_temp;

CREATE
TEMPORARY TABLE pizza_recipes_temp(pizza_id int, topping int);

DROP PROCEDURE IF EXISTS GetToppings;

DELIMITER $$
CREATE PROCEDURE GetToppings()
BEGIN
	DECLARE i INT DEFAULT 0;
    DECLARE j INT DEFAULT 0;
	DECLARE n INT DEFAULT 0;
    DECLARE x INT DEFAULT 0;
    DECLARE id  INT;
	DECLARE topping_in TEXT;
    DECLARE topping_out TEXT;

 	SET i = 0;
    SELECT COUNT(*) FROM pizza_recipes INTO n;

	WHILE i < n DO  -- Iterate per row
		SELECT pizza_id, toppings INTO id, topping_in FROM pizza_recipes LIMIT i,1 ; -- Select each row and store values in id, topping_in variables
		SET x = (CHAR_LENGTH(topping_in) - CHAR_LENGTH( REPLACE ( topping_in, ' ', '') ))+1; -- Find the number of toppings in the row

        SET j = 1;
		WHILE j <= x DO -- Iterate over each element in topping
			SET topping_out = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(topping_in, ',', j), ',', -1));
            -- SUBSTRING_INDEX(topping_in, ',', j -> Returns a substring from a string before j occurences of comma
            -- (SUBSTRING_INDEX(SUBSTRING_INDEX(topping_in, ',', j), ',', -1)) -> Returns the last topping from the substring found above, element at -1 index
			INSERT INTO pizza_recipes_temp VALUES(id, topping_out);  -- Insert pizza_id and the topping into table pizza_info
			SET j = j + 1; -- Increment the counter to find the next pizza topping in the row
        END WHILE;
        SET i = i + 1;-- Increment the counter to fetch the next row
	END WHILE;
END$$
DELIMITER ;

CALL GetToppings();


SELECT *
FROM pizza_recipes_temp;

/*
### Method 2: Using [JSON table functions](https://dev.mysql.com/doc/refman/8.0/en/json-table-functions.html)
- JSON functions are used to split the comma separated string into multiple rows.
- json_array() converts the string to a JSON array
- We enclose array elements with double quotes, this is performed using the replace function and we trim the resultant array

*/

SELECT *,
       json_array(toppings),
       replace(json_array(toppings), ',', '","'),
       trim(replace(json_array(toppings), ',', '","'))
FROM pizza_runner.pizza_recipes;

/*
- We convert the json data into a tabular data using json_table().
-  **Syntax**: JSON_TABLE(expr, path COLUMNS (column_list) [AS] alias)
-  It extracts data from a JSON document and returns it as a relational table having the specified columns
-  Each match for the path preceding the COLUMNS keyword maps to an individual row in the result table.  

'$[*]' -- The expression "$[*]" matches each element of the array and maps it to an individual row in the result table.
columns (topping varchar(50) PATH '$') -- Within a column definition, "$" passes the entire match to the column; 
*/

SELECT t.pizza_id, (j.topping)
FROM pizza_recipes t
JOIN json_table(trim(replace(json_array(t.toppings), ',', '","')), '$[*]' columns (topping varchar(50) PATH '$')) j ;


## customer_orders_temp table
/*
- The exclusions and extras columns in the pizza_recipes table are comma separated strings.
*/

SELECT t.order_id,
       t.customer_id,
       t.pizza_id,
       trim(j1.exclusions) AS exclusions,
       trim(j2.extras) AS extras,
       t.order_time
FROM customer_orders_temp t
INNER JOIN json_table(trim(replace(json_array(t.exclusions), ',', '","')), '$[*]' columns (exclusions varchar(50) PATH '$')) j1
INNER JOIN json_table(trim(replace(json_array(t.extras), ',', '","')), '$[*]' columns (extras varchar(50) PATH '$')) j2 ;
