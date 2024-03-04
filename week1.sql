# Danny-s-Dinner-SQL
A SQL challenge questtions

# Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.
## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.
## Data Sources
This repository contains three key datasets provided by Danny for the case study. The datasets are:

## 1. Sales Dataset

- **Description**: The sales table captures all customer_id level purchases with an corresponding order_date and product_id information for when and what menu items were ordered.

## 2. Menu Dataset

- **Description**: The menu table maps the product_id to the actual product_name and price of each menu item.
## 3. Members Dataset

- **Description**: The final members table captures the join_date when a customer_id joined the beta version of the Danny’s Diner loyalty program.

## Entity Relationship Diagram
![Sales Dataset](https://github.com/AbdulTheAnalyst/Danny-s-Dinner-SQL/blob/main/ER.png)

## Exploratory Data Analyis
Each of the following case study questions can be answered using a single SQL statement:

1. **What is the total amount each customer spent at the restaurant?**

2. **How many days has each customer visited the restaurant?**

3. **What was the first item from the menu purchased by each customer?**

4. **What is the most purchased item on the menu, and how many times was it purchased by all customers?**

5. **Which item was the most popular for each customer?**

6. **Which item was purchased first by the customer after they became a member?**

7. **Which item was purchased just before the customer became a member?**

8. **What is the total number of items and the amount spent for each member before they became a member?**

9. **If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**

10. **In the first week after a customer joins the program (including their join date), they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**

## Data Analysis Result
1. **What is the total amount each customer spent at the restaurant?**
```sql
SELECT
  sales.customer_id,
  SUM(menu.price) AS total_sales
FROM
  dannys_diner.menu
RIGHT JOIN
  dannys_diner.sales ON menu.product_id = sales.product_id 
GROUP BY
  sales.customer_id;
```
2. **How many days has each customer visited the restaurant?**
```sql
SELECT
  customer_id,
  COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY 1;
```
3. **What was the first item from the menu purchased by each customer?**
```sql
WITH ordered_sales AS (
    SELECT
        sales.customer_id,
        menu.product_name,
        sales.order_date,
        RANK() OVER (
            PARTITION BY sales.customer_id
            ORDER BY sales.order_date
        ) AS order_rank
    FROM dannys_diner.sales
    INNER JOIN dannys_diner.menu ON sales.product_id = menu.product_id
)
SELECT DISTINCT
    customer_id,
    product_name
FROM ordered_sales
WHERE order_rank = 1;
```
4. **What is the most purchased item on the menu, and how many times was it purchased by all customers?**
```sql
SELECT 
  menu.product_name, 
  COUNT(sales.*) AS total_purchases 
FROM 
  dannys_diner.sales 
  INNER JOIN dannys_diner.menu ON menu.product_id = sales.product_id 
GROUP BY 
  menu.product_name 
ORDER BY 
  total_purchases DESC 
LIMIT 
  1;
```
5. **Which item was the most popular for each customer?**
```sql
WITH customer_cte AS (
  SELECT
    sales.customer_id,
    menu.product_name,
    COUNT(sales.customer_id) AS item_quantity,
    RANK() OVER (
      PARTITION BY sales.customer_id
      ORDER BY COUNT(sales.customer_id) DESC
    ) AS item_rank
  FROM
    dannys_diner.sales
    INNER JOIN dannys_diner.menu ON menu.product_id = sales.product_id
  GROUP BY
    sales.customer_id, menu.product_name
)
SELECT
  customer_id,
  product_name,
  item_quantity
FROM
  customer_cte
WHERE
  item_rank = 1;
```

6. **Which item was purchased first by the customer after they became a member?**
```sql
WITH member_first_purchase AS (
  SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date
    ) AS purchase_rank
  FROM dannys_diner.sales AS s
  INNER JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
  INNER JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
  WHERE
    s.order_date >= mem.join_date::DATE
)
SELECT DISTINCT
  customer_id,
  order_date,
  product_name AS first_purchased_item
FROM member_first_purchase
WHERE purchase_rank = 1;
```
7.*Which item was purchased just before the customer became a member?*
 ```sql
   WITH member_first_purchase AS (
  SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date DESC
    ) AS purchase_rank
  FROM dannys_diner.sales AS s
  INNER JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
  LEFT JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
  WHERE
    s.order_date < mem.join_date::DATE
)
SELECT DISTINCT
  customer_id,
  order_date,
  product_name AS first_purchased_item
FROM member_first_purchase
WHERE purchase_rank = 1;
```
9. **If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
```sql
SELECT
  sales.customer_id,
  SUM (
    CASE
      WHEN menu.product_name = 'sushi' THEN 2 * 10 * menu.price
      ELSE 10 * menu.price
    END
  ) AS points
FROM
  dannys_diner.sales
LEFT JOIN dannys_diner.menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY points DESC;
```

10. **In the first week after a customer joins the program (including their join date), they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**
```sql
SELECT
  sales.customer_id,
  SUM(
    CASE
      WHEN menu.product_name != 'sushi' THEN 2 * 10 * menu.price
      WHEN sales.order_date BETWEEN  (members.join_date :: DATE + 6)
      AND members.join_date :: DATE THEN 10 * menu.price
      ELSE NULL
    END
  ) AS points
FROM
  dannys_diner.sales
  INNER JOIN dannys_diner.menu ON sales.product_id = menu.product_id
  INNER JOIN dannys_diner.members ON sales.customer_id = members.customer_id
WHERE
  sales.order_date <= '2021-01-31' :: DATE
GROUP BY
  sales.customer_id
ORDER BY
  points;
```
