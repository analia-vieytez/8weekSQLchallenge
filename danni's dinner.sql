--Question 1
--What is the total amount each customer spent at the restaurant?

SELECT s.customer_id AS customer, SUM(m.price) AS total_spent
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1;

--Question 2
--How many days has each customer visited the restaurant?
SELECT customer_id AS customer, COUNT(DISTINCT order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 2 DESC;

--Question 3
--What was the first item(s) from the menu purchased by each customer?
WITH menu_cte AS
(
 SELECT customer_id, order_date, product_name,
  DENSE_RANK() OVER(
  PARTITION BY s.customer_id
  ORDER BY s.order_date, product_name) AS rank
 FROM dannys_diner.sales AS s
 INNER JOIN dannys_diner.menu AS m
  ON s.product_id = m.product_id
)

SELECT 
customer_id, product_name
FROM menu_cte
WHERE rank = 1
GROUP BY customer_id, product_name;

--Question 4
--What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name, COUNT(s.*) AS total_sales
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY total_sales DESC
LIMIT 1;

--Question 5
--Which item(s) was the most popular for each customer?
--OPTION 1
SELECT s.customer_id, m.product_name, COUNT(s.*) AS total_sales
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1,2
ORDER BY total_sales DESC;


--OPTION 2
WITH favorite_cte AS(
SELECT m.product_name, s.customer_id, count(m.product_name) AS count,
RANK() OVER(PARTITION BY customer_id 
ORDER BY count(product_name) DESC) AS ranked
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
ON  s.product_id = m.product_id
GROUP BY customer_id, product_name
)

SELECT customer_id, product_name, count
FROM favorite_cte
WHERE ranked = 1
GROUP BY customer_id, product_name;


--Question 6
--Which item was purchased first by the customer after they became a member and what date was it?
--(including the date they joined)

SELECT m.customer_id, m.join_date, s.order_date, me.product_name
FROM dannys_diner.sales s
JOIN dannys_diner.members m
ON s.customer_id = m.customer_id
JOIN dannys_diner.menu me
ON s.product_id = me.product_id;

--option 2
WITH first_item_cte AS(
SELECT m.customer_id, m.join_date, s.order_date, me.product_name,
DENSE_RANK() OVER( PARTITION BY m.customer_id
ORDER BY order_date) AS first_item
FROM dannys_diner.sales s
JOIN dannys_diner.members m
ON s.customer_id = m.customer_id
JOIN dannys_diner.menu me
ON s.product_id = me.product_id
WHERE order_date>= join_date)

SELECT customer_id, product_name, order_date
FROM first_item_cte
WHERE first_item = 1;

--7. Which item was purchased just before the customer became a member?

WITH first_item_cte AS(
SELECT m.customer_id, m.join_date, s.order_date, me.product_name,
DENSE_RANK() OVER( PARTITION BY m.customer_id
ORDER BY order_date DESC) AS first_item
FROM dannys_diner.sales s
JOIN dannys_diner.members m
ON s.customer_id = m.customer_id
JOIN dannys_diner.menu me
ON s.product_id = me.product_id
WHERE order_date< join_date)

SELECT customer_id, product_name, order_date, join_date
FROM first_item_cte
WHERE first_item = 1;

--8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(me.product_name) AS product,SUM(me.price) AS amount_spent
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu me
ON s.product_id = me.product_id
INNER JOIN dannys_diner.members m
ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
GROUP BY 1;

--Question 9
--If each $1 spent equates to 10 points and sushi has a 2x points multiplier -
--how many points would each customer have?

WITH points_cte AS
 (
 SELECT s.customer_id, m.*, 
 CASE
  WHEN m.product_id = 1 THEN m.price * 20
  ELSE m.price * 10
  END AS points
 FROM dannys_diner.menu m
 LEFT JOIN dannys_diner.sales s
 ON s.product_id = m.product_id
 )
 SELECT customer_id, SUM(points) AS points
 FROM points_cte
 GROUP BY customer_id
 ORDER BY points DESC;
 
 --Question 10
 --In the first week after a customer joins the program (including their join date) 
 --they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


WITH points_cte AS
 (
 SELECT s.*, m.*, 
 CASE
  WHEN m.product_id = 1 THEN m.price * 20
  WHEN s.order_date BETWEEN me.join_date AND (me.join_date::DATE +6) THEN m.price *20
  ELSE m.price * 10
  END AS points
 FROM dannys_diner.sales s
 LEFT JOIN dannys_diner.menu m
 ON s.product_id = m.product_id
 LEFT JOIN dannys_diner.members me
 ON s.customer_id = me.customer_id
 
 )
 SELECT customer_id, SUM(points) AS points
 FROM points_cte 
WHERE  order_date < '20210201'
 GROUP BY customer_id
 ORDER BY points DESC;

 -- BONUS Question 11: Create table to show customer_id, order_date, product_name, price and if is member or not
SELECT
    s.customer_id, s.order_date, me.product_name, me.price,
    CASE WHEN EXISTS (
        SELECT 1
        FROM dannys_diner.members m
        WHERE s.customer_id = m.customer_id AND s.order_date >= m.join_date
    ) THEN 'Y' ELSE 'N' END AS member
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu me
ON s.product_id = me.product_id; 
 

 --BONUS 12. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
WITH member_cte AS(
SELECT
    s.customer_id, s.order_date, me.product_name, me.price,
    CASE WHEN EXISTS (
        SELECT 1
        FROM dannys_diner.members m
        WHERE s.customer_id = m.customer_id AND s.order_date >= m.join_date
    ) THEN 'Y' ELSE 'N' END AS member
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu me
ON s.product_id = me.product_id)

SELECT *,
  CASE
    WHEN member =  'N' THEN NULL
    ELSE RANK() OVER (
      PARTITION BY customer_id, member
      ORDER BY order_date
    )  END AS ranking
  
FROM member_cte;
