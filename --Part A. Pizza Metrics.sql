--Part A. Pizza Metrics
--Question 1: How many pizzas were ordered?

SELECT COUNT(pizza_id) FROM pizza_runner.customer_orders;

--Question 2
--How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) FROM pizza_runner.customer_orders;

--Question 3
--How many successful orders were delivered by each runner?

--# Runner orders temporary table
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
FROM pizza_runner.customer_orders;

SELECT * FROM customer_orders_temp;

---Cleaning runners runner_orders

DROP TABLE IF EXISTS runner_orders_temp;
CREATE TEMPORARY TABLE runner_orders_temp AS
SELECT order_id, runner_id, 
CASE
    WHEN pickup_time LIKE 'null' THEN NULL 
    ELSE pickup_time
  END AS pickup_time,
CASE
    WHEN distance LIKE 'null' THEN NULL
    WHEN distance LIKE '%km' THEN TRIM ('km' FROM distance)
    ELSE distance
  END AS distance,
CASE
    WHEN duration LIKE 'null' THEN NULL
    WHEN duration LIKE '%minutes' THEN TRIM ('minutes' FROM duration)
    WHEN duration LIKE '%min' THEN TRIM ('min' FROM duration)
    WHEN duration LIKE '%mins' THEN TRIM ('mins' FROM duration)
  ELSE duration
END AS duration,
CASE
    WHEN cancellation LIKE 'null' THEN NULL 
    WHEN cancellation LIKE '' THEN NULL 
    ELSE cancellation
END AS cancellation
FROM pizza_runner.runner_orders;



--Part A. Pizza Metrics
--Question 1: How many pizzas were ordered?

SELECT COUNT(pizza_id) FROM customer_orders_temp;

--Question 2
--How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) FROM customer_orders_temp;

--Question 3
--How many successful orders were delivered by each runner?

SELECT runner_id, COUNT(order_id) AS succesful_orders FROM runner_orders_temp
WHERE cancellation IS NULL
GROUP BY runner_id;

--Question 4
--How many of each type of pizza was delivered?
SELECT pizza_name, COUNT(c.pizza_id) AS succesful_pizza FROM customer_orders_temp c
INNER JOIN  runner_orders_temp r
ON c.order_id = r.order_id
INNER JOIN pizza_runner.pizza_names p
ON p.pizza_id = c.pizza_id
WHERE cancellation IS NULL
GROUP BY pizza_name;

--Question 5
--How many Vegetarian and Meatlovers were ordered by each customer?
SELECT c.customer_id, pizza_name, COUNT(p.pizza_name) AS num_pizza
FROM customer_orders_temp c
JOIN  runner_orders_temp r
ON c.order_id = r.order_id
JOIN pizza_runner.pizza_names p
ON p.pizza_id = c.pizza_id
WHERE cancellation IS NULL
GROUP BY customer_id,pizza_name
ORDER BY customer_id ;

--Question 6
--What was the maximum number of pizzas delivered in a single order?

SELECT c.order_id, count(pizza_id) as num_pizza
FROM customer_orders_temp c
JOIN  runner_orders_temp r
ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY 1
ORDER BY num_pizza DESC;

--SHOW ONLY MAX
WITH num_cte AS(
SELECT c.order_id, count(pizza_id) as num_pizza
FROM customer_orders_temp c
JOIN  runner_orders_temp r
ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY 1)
SELECT max(num_pizza) AS max_pizzas FROM num_cte;

--Question 7
--How many pizzas were delivered that had both exclusions and extras? 
--Question 8
--What was the total volume of pizzas ordered for each hour of the day? BOTH CAN BE SEEN WITH SAME CODE

WITH split_cte AS(
select order_id, customer_id, pizza_id,  unnest(string_to_array(exclusions, ',')) as exclusions,
       unnest(string_to_array(extras, ',')) as extras
from customer_orders_temp)
SELECT customer_id, 
SUM(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS num_change,
SUM(CASE WHEN exclusions IS  NULL AND extras IS  NULL THEN 1 ELSE 0 END) AS no_change,
count(exclusions) AS exclusions, count(extras) AS extras from split_cte
GROUP BY customer_id;

--only problem is we are only showing those with changes
select order_id, customer_id, pizza_id,  regexp_split_to_table(exclusions, ',') as exclusions,
       regexp_split_to_table(extras, ',') as extras
from customer_orders_temp)


--Question 9
--What was the total volume of pizzas ordered(not delivered) for each hour of the day?

SELECT
  DATE_PART('hour', order_time) AS hour_of_day,
  COUNT(*) AS pizza_count
FROM pizza_runner.customer_orders
GROUP BY hour_of_day
ORDER BY hour_of_day;

--Question 10
--What was the volume of orders for each day of the week?

SELECT
  TO_CHAR(order_time, 'Day') AS day_of_week,
  COUNT(order_id) AS pizza_count
FROM pizza_runner.customer_orders
GROUP BY day_of_week, DATE_PART('dow', order_time)
ORDER BY DATE_PART('dow', order_time);




