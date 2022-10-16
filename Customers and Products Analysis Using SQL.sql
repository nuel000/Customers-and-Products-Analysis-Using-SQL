-- Now that we know our database a little better, lets go ahead to answer some questions

/*  	QUESTION 1:  Which products should we order more of or less of?
 
This question refers to inventory reports, including low stock and product performance. 
This will optimize the supply and the user experience by preventing the best-selling products from going out-of-stock.

To answer this, we need to break down the solution in steps

** STEP 1: Find the low stock products i.e the quantity of each product sold divided by the quantity of product in stock.
 We can consider the ten lowest rates. These will be the top ten products that are (almost) out-of-stock.
 
** STEP 2: Find the product performance which is represented the sum of sales per product.

** STEP 3: Priority products for restocking are those with high product performance that are on the brink of being out of stock.

Lets Query!!!!
*/
--STEP 1: Low stock Products

SELECT productCode,ROUND(SUM(quantityOrdered) * 1.0 / (SELECT quantityInStock
														FROM products p
														WHERE o.productCode = p.productCode), 2) AS low_stock
FROM orderdetails AS o
GROUP BY productCode
ORDER BY low_stock
LIMIT 10;

--Product performance

SELECT productCode, 
       SUM(quantityOrdered * priceEach) AS product_performance
  FROM orderdetails 
 GROUP BY productCode 
 ORDER BY product_performance DESC
 LIMIT 10;
 
 --To get the products we need to restock
 
WITH low_stock AS(
SELECT productCode,ROUND(SUM(quantityOrdered) * 1.0 / (SELECT quantityInStock
														FROM products p
														WHERE o.productCode = p.productCode), 2) AS low_stock
FROM orderdetails AS o
GROUP BY productCode
ORDER BY low_stock
LIMIT 10)

SELECT 	p.productName,p.productLine,o.productCode, SUM(o.quantityOrdered  * o.priceEach) AS Product_Performance
FROM orderdetails o
JOIN products AS p
ON p.productCode = o.productCode
WHERE o.productCode IN (SELECT productCode
						FROM low_stock)
GROUP BY o.productCode
ORDER BY Product_Performance DESC;


/*QUESTION 2: How should we match marketing and communication strategies to customer behaviors?

This involves categorizing customers: finding the VIP (very important person) customers and those who are less engaged.

VIP customers bring in the most profit for the store.

Less-engaged customers bring in less profit.

For example, we could organize some events to drive loyalty for the VIPs and launch a campaign for the less engaged.
 */
 --Lets computer how much profit each customer generates
 
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
 ORDER BY profit DESC;
 
 --Now lets Know who are VIPs are and what country they come from
 
 WITH customer_orders AS(
 SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
 ORDER BY profit DESC
 LIMIT 5)
 
 SELECT customerName, customerNumber,contactFirstName,contactLastName, country
 FROM customers
 WHERE customerNumber IN(
						SELECT customerNumber
						FROM customer_orders)
						
						
--Least Engaging customers

WITH leastcustomers AS(

SELECT o.customerNumber as customerNumber ,SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS revenue
FROM products as p
JOIN orderdetails as od
ON p.productCode = od.productCode
JOIN orders as o
ON o.orderNumber = od.orderNumber
GROUP BY customerNumber
ORDER BY revenue ASC
LIMIT 5)

SELECT c.customerName,c.contactFirstName,c.contactLastName,c.country,l.revenue as new_rev
FROM customers AS c
JOIN leastcustomers  AS l
ON  l.customerNumber = c.customerNumber
WHERE c.customerNumber IN(SELECT customerNumber
						FROM leastcustomers)
GROUP BY c.contactFirstName
ORDER BY new_rev

--Finally Lets calculate the customers Life time Value

-- Customer LTV
WITH 

money_in_by_customer AS (
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)

SELECT AVG(mc.revenue) AS ltv
  FROM money_in_by_customer mc;

 --tells us how much profit an average customer generates during their lifetime with our store. We can use it to predict our future profit
 
-- QUESTION 4: Which was the best performing year in terms of profit generated and which product topped the chart?


SELECT substr(o.orderDate,1,4) as order_year,SUM(quantityOrdered * (priceEach - buyPrice)) AS profit,p.productName
FROM orders as o
JOIN orderdetails as od
ON o.orderNumber = od.orderNumber
JOIN products as p
ON p.productCode = od.productCode
GROUP BY order_year
ORDER BY profit DESC
