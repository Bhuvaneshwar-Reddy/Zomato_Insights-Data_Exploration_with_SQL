-- **********************************************************
-- Zomato Customer Behavior Analysis with SQL
-- **********************************************************

-- Welcome to the Zomato Customer Behavior Analysis SQL script repository. In this SQL script, we delve into a comprehensive exploration of customer behavior and interactions within a Zomato-like dining platform. By querying a hypothetical database, we aim to extract valuable insights that can drive strategic decisions for enhancing customer experiences and optimizing business strategies.

-- This SQL script focuses on dissecting customer preferences, spending patterns, and interactions with the platform's offerings. Through structured queries, we intend to uncover essential aspects of customer engagement, such as their purchase habits, most favored items, and membership influences.

-- Queries are meticulously crafted to address specific questions related to customer visits, expenditure, first product preferences, and more. These queries are designed not only to provide valuable answers but also to serve as learning opportunities for SQL enthusiasts and data analysts looking to gain insights from relational databases.

-- As you explore this script, keep in mind that SQL is a powerful tool that empowers data professionals to navigate complex datasets and unveil meaningful trends. We encourage you to run these queries against a compatible database setup to experience firsthand the insights that can be drawn from structured data analysis.

-- Whether you are a SQL novice or an experienced data analyst, this repository aims to offer both practical solutions and educational content, fostering a deeper understanding of customer behavior analysis in the realm of modern dining platforms.

-- So, let's dive in and unravel the story that customer data has to tell within the context of Zomato-like experiences. Happy querying!

-- **********************************************************

-- First let us create a table name users to enter basic information and add some data into it. 

Drop TABLE IF exists users;

CREATE TABLE Users(
userid INTEGER,
signup_date DATE
);

INSERT INTO Users VALUES(1,'2014-02-09');
INSERT INTO Users VALUES(2,'2015-01-15');
INSERT INTO Users VALUES(3,'2014-04-11');

ALTER TABLE Users RENAME COLUMN userid TO id;

SELECT * from Users;

-- Now let us create a table for the customers who have purchased the gold premium named goldUsers and add their data.

DROP TABLE IF EXISTS goldUsers;

Create TABLE goldUsers(
userid INTEGER,
gold_signup_date date
);

INSERT INTO goldUsers VALUES(1,'2017-09-22');
INSERT INTO goldUsers VALUES(3,'2017-04-21');

SELECT * from goldUsers;

DROP TABLE IF EXISTS product;

-- Let us create a table product which includes different products available.

CREATE TABLE product(
product_id INTEGER,
product_name VARCHAR(100),
price INTEGER
);

INSERT INTO product VALUES(1,'p1',590);
INSERT INTO product VALUES(2,'p2',640);
INSERT INTO product VALUES(3,'p3',780);

SELECT * FROM product;

-- Let us create a new table to enter the sales data that includes which user has purchased what particular product.

DROP TABLE IF EXISTS Sales;

CREATE TABLE Sales(
userid INTEGER,
created_date DATE, 
product_id INTEGER
);

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);

SELECT * FROM Sales;

-- From here on, let us write some queries to the given problems. These problems start with simple queries followed by some hard questions.

-- 1. What is the total amount each customer spent on Zomato?

select s.userid, SUM(price) AS Total_amount
FROM Sales s
JOIN product p
ON s.product_id = p.product_id
GROUP BY s.userid
ORDER BY Total_amount DESC;

-- From the query, it is observed User 1 has spent more amount(9320) than the rest.

-- 2. How Many Days has each customer visited Zomato?

SELECT userid, COUNT(distinct created_date) AS NO_of_visits
FROM Sales
GROUP BY userid;

-- From this query, it is observed that User 1 has visited the website a lot compared(7 times) to others.

-- 3. What was the first product purchased by each customer?

-- We can create a new column to rank columns based on their first visit

SELECT * FROM (select *,rank() over(partition by userid order by created_date) `Rank` from sales) AS First_product_purchased
WHERE `Rank` = 1;

/* From this observation, it is observed that all 3 users first purchased product 1 i.e p1, therefore Zomato must increase the sales on
that product and put more investment into it. */

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

-- This query is to find out the most purchased item
SELECT product_id,count(product_id) FROM Sales GROUP BY product_id ORDER BY count(product_id) DESC LIMIT 1;

-- This query is to check how many times was the product purchased by all customers
SELECT userid, count(product_id) AS `COUNT` FROM sales 
WHERE product_id = (SELECT product_id FROM Sales GROUP BY product_id ORDER BY count(product_id) DESC LIMIT 1)
GROUP BY userid;

-- From this query, we observe that product_id 2 was the most purchased item and User 1 and 3 has purchased this item a lot(3 times) compared to others.

-- 5. Which items was the most popular for each customer

SELECT userid,product_id FROM
(SELECT *,RANK() OVER(partition by userid order by `Count` DESC) `Rank` FROM
(SELECT userid, product_id, count(product_id) AS `Count` FROM Sales group by userid,product_id)a) b
WHERE `Rank`=1;

-- From this query, we observed that product p2 is the most popular one among user 1 and 3 whereas the most popular product of user 2 is p3.

-- 6. Which item was purchased first by the customer after they became a gold member?

-- This is used to determine which product was attracted to the customer which made them purchase the membership
SELECT * FROM
(SELECT n.*, RANK() OVER(partition by userid order by created_date) `Rank` FROM
(select s.userid, s.created_date, s.product_id,g.gold_signup_date
FROM sales s
INNER JOIN goldusers g
ON s.userid = g.userid 
WHERE created_date >= gold_signup_date) n) a
WHERE `Rank`=1;

-- From the query, we observe that user 1 has first purchased product p3 after becoming a gold member and user 3 purchased product p2 after becoming a gold member.

-- 7. Which item was purchased just before the customer became a member?

Select * FROM
(select c.*, RANK() OVER(partition by s.userid order by s.created_date DESC) `Rank` FROM
(SELECT s.userid, s.created_date,s.product_id,g.gold_signup_date
FROM sales s INNER JOIN goldusers g ON s.userid = g.userid and s.created_date < g.gold_signup_date) c) n
WHERE `Rank`=1;

-- From this query, we observe that users 1 and 3 both purchased product p2 before becoming the gold member.

-- 8. What is the total orders and amount spent for each member before they became a gold member?

SELECT userid, COUNT(userid) `Count`, SUM(price) Total_amt_spent_before_member FROM
(SELECT c.*, p.price FROM
(SELECT s.userid, s.created_date,s.product_id,g.gold_signup_date
FROM sales s INNER JOIN goldusers g ON s.userid = g.userid and s.created_date < g.gold_signup_date) c 
INNER JOIN product p ON c.product_id = p.product_id)d
GROUP BY userid
order by Total_amt_spent_before_member DESC;

/* 9. Calculate points collected by each customer and for which product most points have been given till now. If 2 zomato points = 5Rs, then how much money has each customer earned.
		If we buy each product, it generates zomato points.
		For eg: for p1, for every 5Rs, we get 1 zomato points,
				for p2, for every 10Rs, we get 5 zomato points,
				for p3, for every 5Rs, we get 1 zomato points.
 */

select userid,sum(zomato_points) AS Total_zomato_points,sum(zomato_points)*2.5 AS Total_money_earned FROM
(select e.*,amount DIV points as zomato_points FROM 
(select d.*, case when product_id = 1 then 5 when product_id =2 then 2 when product_id = 3 then 5 else 0 end points FROM
(select n.userid, n.product_id, sum(price) amount FROM
(select s.*, p.price 
FROM sales s INNER JOIN product p ON s.product_id = p.product_id)n
GROUP BY userid, product_id
order by userid, product_id)d)e)f
GROUP by userid;

-- This case is for checking which product has earned most points.

SELECT * FROM
(select *, rank() OVER(order by Total_points_earned DESC) `Rank` FROM
(select product_id,sum(zomato_points) AS Total_points_earned FROM
(select e.*,amount DIV points as zomato_points FROM 
(select d.*, case when product_id = 1 then 5 when product_id =2 then 2 when product_id = 3 then 5 else 0 end points FROM
(select n.userid, n.product_id, sum(price) amount FROM
(select s.*, p.price 
FROM sales s INNER JOIN product p ON s.product_id = p.product_id)n
GROUP BY userid, product_id
order by userid, product_id)d)e)f
group by product_id)g)h
WHERE `Rank`=1;

/* 10. In the first year after the customer joins the gold program(include their join date) irrespective of what customer has purchased, they 
earn 5 zomato points for every 10Rs spent and what was their points earnings for each product in their first year? */

SELECT c.*, p.price, p.price*0.5 AS Zomato_points_within_1yr FROM
(SELECT s.userid, s.created_date, s .product_id, g.gold_signup_date
FROM sales s INNER JOIN goldusers g on s.userid = g.userid and 
s.created_date >= g.gold_signup_date and s.created_date< date_add(g.gold_signup_date, INTERVAL 365 day))c
INNER JOIN product p on c.product_id = p.product_id;

-- This query shows the amount of Zomato points they earned for each product within one year after they became a gold user.

-- 11. rank all the transcations of the customers

select *,RANK() over(partition by userid order by created_date) `Rank` FROM sales;

-- 12. Rank all the transcations for each member whenever they are a zomato member for every non gold member transcation mark as na

select c.*, case when gold_signup_date is NULl then 'na' else RANK() over(partition by userid order by created_date desc) END as `Rank` from
(select s.userid, s.created_date, s.product_id,g.gold_signup_date
FROM sales s Left JOIN goldusers g ON s.userid = g.userid and created_date >= gold_signup_date)c;

/*
**********************************************************
Conclusion: Insights from Zomato Customer Behavior Analysis
**********************************************************

And there we have it, a journey through Zomato's customer behavior revealed through SQL analysis! 🚀 By querying our data, we've uncovered intriguing insights that shed light on how customers engage with the platform, what they love, and how membership impacts their choices.

Here's a quick recap of what we've discovered:

* Total Spending: We've identified the big spenders, understanding who's contributing the most to Zomato's growth.

* Frequency of Visits: Customer engagement varies, with some visiting more often than others. It's fascinating to see the diversity in habits.

* First Orders: The "first date" with Zomato matters! We've learned about initial product preferences.

* Most Popular Items: Through data-driven analysis, we pinpointed the most beloved items on the menu.

* Membership Impact: Membership matters. We've explored how becoming a gold member influences purchasing behavior.

* Points and Earnings: Customers not only buy but also earn points. We've quantified their earnings and their equivalence in money.

I hope you've enjoyed this exploration into the world of SQL and data insights. Whether you're a data enthusiast, a curious learner, or a business strategist, I hope this journey has been both insightful and inspiring. Keep asking questions, exploring data, and unlocking new discoveries!

Thank you for joining me on this analytical adventure. Until next time, happy querying! 📊🍽️

**********************************************************
*/
