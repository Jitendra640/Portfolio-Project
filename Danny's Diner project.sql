--Prepairing the dataset


CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  --Solution Quries

SELECT * FROM sales
SELECT * FROM menu
SELECT * FROM members

--What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) as total_spent FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
GROUP BY customer_id


--How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) as unique_days
FROM sales
GROUP BY customer_id


WITH CTE_rank as
(SELECT customer_id, order_date,s.product_id,product_name,
RANK() OVER (PARTITION BY customer_id ORDER BY order_date asc) as ranking
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id)
SELECT * FROM CTE_rank
WHERE ranking = 1




SELECT customer_id, COUNT(DISTINCT (order_date))
FROM sales
GROUP BY customer_id

--What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name,COUNT(product_name) as count FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id 
GROUP BY product_name
ORDER BY count DESC

--Which item was the most popular for each customer?

WITH CTE_max as
(SELECT customer_id,product_name,COUNT(product_name) as count FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id 
GROUP BY customer_id,product_name),
level as
(SELECT *,
RANK() OVER (PARTITION BY customer_id ORDER BY count DESC) rankings
FROM CTE_max)
SELECT * FROM level
WHERE rankings = 1

--Which item was purchased first by the customer after they became a member?
WITH final
as

(SELECT s.customer_id,order_date,product_name,join_date,
RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) as rank
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
INNER JOIN members as mem
ON s.customer_id = mem.customer_id
WHERE s.order_date >= mem.join_date)
SELECT * FROM final
WHERE rank = 1

--Which item was purchased just before the customer became a member?
WITH CTE_final 
as
(SELECT s.customer_id,order_date,product_name,join_date,
RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) as rank
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
INNER JOIN members as mem
ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date)
SELECT * FROM CTE_final
WHERE rank = 1

--What is the total items and amount spent for each member before they became a member?

WITH CTE_final as (
SELECT s.customer_id,order_date,product_name,join_date,price
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
INNER JOIN members as mem
ON s.customer_id = mem.customer_id
WHERE order_date < join_date)
SELECT customer_id,SUM(price) as total_spent,COUNT(distinct(product_name)) as product_count FROM CTE_final
GROUP BY customer_id


--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH CTE_custo as (
SELECT customer_id,product_name,
CASE
   WHEN product_name = 'sushi' THEN (price)*2
   ELSE price
   END as multiplier
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id) 
SELECT customer_id, sum(multiplier)*10 FROM CTE_custo
GROUP by customer_id 

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?


WITH finalpoints AS (
    SELECT a.customer_id, a.order_date, c.product_name, c.price,
        CASE 
            WHEN product_name = 'sushi' THEN 2 * c.price
            WHEN a.order_date BETWEEN b.join_date AND DATEADD(DAY, 6, b.join_date) THEN 2 * c.price
            ELSE c.price 
        END AS newprice
    FROM sales AS a
    JOIN menu AS c ON a.product_id = c.product_id
    JOIN members AS b ON a.customer_id = b.customer_id
    WHERE a.order_date <= '2021-01-31'
)
SELECT customer_id, SUM(newprice) * 10 AS total_points
FROM finalpoints
GROUP BY customer_id;


--Joining all tables, checking who are members or not

SELECT s.customer_id,order_date,product_name,price,
CASE
   WHEN order_date < join_date THEN 'N'
   ELSE 'Y'
   END as MEMBER
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
LEFT JOIN members as mem
ON s.customer_id = mem.customer_id

SELECT s.customer_id,order_date,product_name,price,
CASE
   WHEN order_date < join_date THEN 'N'
      WHEN join_date IS NULL THEN 'N' 

   ELSE 'Y'
   END as MEMBER
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
LEFT JOIN members as mem
ON s.customer_id = mem.customer_id

WITH finished as (
SELECT s.customer_id,order_date,product_name,price,
CASE
   WHEN order_date < join_date THEN 'N'
   WHEN join_date IS NULL THEN 'N' 
   ELSE 'Y'
   END as MEMBER
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
LEFT JOIN members as mem
ON s.customer_id = mem.customer_id)
SELECT *,
CASE 
    WHEN MEMBER = 'N' THEN NULL
	ELSE
	rank() OVER (PARTITION by customer_id,MEMBER ORDER BY order_date)
	END as ranking

FROM finished














