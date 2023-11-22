CREATE DATABASE Celebel_Task;

CREATE TABLE Sales (
    customer_id VARCHAR(25),
    order_date DATE,
    product_id INT
);

CREATE TABLE Menu (
    product_id INT,
    product_name VARCHAR(255),
    price DECIMAL(10, 2)
);

CREATE TABLE Members (
    customer_id VARCHAR(25),
    join_date DATE
);

INSERT INTO Members (customer_id, join_date)
VALUES
('A', '2021-01-07'),
('B', '2021-01-09');

INSERT INTO Menu (product_id, product_name, price)
VALUES
(1, 'sushi', 10.00),
(2, 'curry', 15.00),
(3, 'ramen', 12.00);

INSERT INTO Sales (customer_id, order_date, product_id)
VALUES
('A', '2021-01-01', 1),
('A', '2021-01-01', 2),
('A', '2021-01-07', 2),
('A', '2021-01-10', 3),
('A', '2021-01-11', 3),
('A', '2021-01-11', 3),
('B', '2021-01-01', 2),
('B', '2021-01-02', 2),
('B', '2021-01-04', 1),
('B', '2021-01-11', 1),
('B', '2021-01-16', 3),
('B', '2021-02-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-07', 3);
-- 1. What is the total amount each customer spent at the restaurant?
SELECT m.product_name, s.customer_id, SUM(m.price) AS total_spent
FROM Menu m
JOIN Sales s ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM Sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH RankedSales AS (
    SELECT 
        s.customer_id,
        m.product_name,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
    FROM Sales s
    JOIN Menu m ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM RankedSales
WHERE rn = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 m.product_name, COUNT(*) AS frequency
FROM Sales s
JOIN Menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY frequency DESC;

-- 5. Which item was the most popular for each customer?
WITH CustomerPopularItems AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(*) AS frequency,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rn
    FROM Sales s
    JOIN Menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, frequency
FROM CustomerPopularItems
WHERE rn = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH FirstPurchaseAfterJoin AS (
    SELECT 
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
    FROM Sales s
    JOIN Menu m ON s.product_id = m.product_id
    JOIN Members mem ON s.customer_id = mem.customer_id
    WHERE s.order_date > mem.join_date
)
SELECT customer_id, product_name, order_date
FROM FirstPurchaseAfterJoin
WHERE rn = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH LastPurchaseBeforeJoin AS (
    SELECT 
        s.customer_id,
        m.product_name,
        s.order_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
    FROM Sales s
    JOIN Menu m ON s.product_id = m.product_id
    JOIN Members mem ON s.customer_id = mem.customer_id
    WHERE s.order_date < mem.join_date
)
SELECT customer_id, product_name, order_date
FROM LastPurchaseBeforeJoin
WHERE rn = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH MemberSpendingBeforeJoin AS (
    SELECT 
        mem.customer_id,
        COUNT(*) AS total_items,
        SUM(m.price) AS total_spent
    FROM Sales s
    JOIN Menu m ON s.product_id = m.product_id
    JOIN Members mem ON s.customer_id = mem.customer_id
    WHERE s.order_date < mem.join_date
    GROUP BY mem.customer_id
)
SELECT customer_id, total_items, total_spent
FROM MemberSpendingBeforeJoin;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, SUM(CASE WHEN m.product_name = 'sushi' THEN 2 * m.price * 10 ELSE m.price * 10 END) AS points
FROM Sales s
JOIN Menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH PointsInFirstWeek AS (
    SELECT 
        mem.customer_id,
        SUM(CASE
            WHEN s.order_date BETWEEN mem.join_date AND DATEADD(DAY, 7, mem.join_date) THEN 2 * m.price * 10
            ELSE m.price * 10 
        END) AS points_in_january
    FROM Sales s
    JOIN Menu m ON s.product_id = m.product_id
    JOIN Members mem ON s.customer_id = mem.customer_id
    WHERE MONTH(mem.join_date) = 1
    GROUP BY mem.customer_id
)
SELECT customer_id, points_in_january
FROM PointsInFirstWeek;
