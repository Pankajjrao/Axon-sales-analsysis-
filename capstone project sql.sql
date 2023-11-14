-- 
use classicmodels;

-- Tables in the database.
show tables;

-- Total cutomers?
select count(distinct(customerNumber)) as 'Total customers' from customers;

-- Checking if we have a customer who is not assigned salesrepemployeenumber 
SELECT (customerNumber) 
FROM customers
WHERE salesRepEmployeeNumber IS NULL;

-- If there is no Sales reprsentative is assigned to the customer, it means that the customer has not ordered a single time
-- checking 
SELECT *
FROM orders
WHERE customerNumber IN (SELECT
  customerNumber
FROM customers
WHERE salesRepEmployeeNumber IS NULL);

-- -----------------------------------------------------------------------------------------------

describe employees;

-- Checking the total no of employees
select distinct count(*) AS "No of employees" 
from employees;

-- who is the president?
select firstName,lastName 
from employees 
where JobTitle = 'President';

-- -----------------------------------------------------------------------------------------------------------------------------------------

describe offices;

-- country wise offices
select country,count(*) as No_of_offices
from offices
group by country;

-- -----------------------------------------------------------------------------------------------------------------------------------------------
 
 describe orderdetails;
 
 select * from orderdetails;
 -- This table contains two primary keys and the combination of both uniquely identifies the column
 -- there are no null values in this table
 
 -- -----------------------------------------------------------------------------------------------------------------------------------
describe productlines;

select * from productlines;

-- dropping htmldescripition and impage column because they are null
alter table productlines
	drop column htmlDescription,
	drop column image;
    
-- --------------------------------------------------------------------------------------------------------------------

-- Data analysis using sql

-- Who are the top 5 spenders?
select c.customerName,p.customerNumber,sum(p.amount) as 'total_amount_per_customer'
from payments p
join customers c
on p.customerNumber = c.customerNumber
group by c.customerName,p.customerNumber
order by sum(p.amount) desc
limit 5;

-- Most popular productline?
select p.productline,sum(o.quantityordered) as 'Qty_sold'
from orderdetails o
join products p
on o.productCode = p.productCode
group by p.productline
order by count(orderNumber) desc;

-- Top 5 countries by Who orders the most?
select c.country,sum(od.quantityordered) as 'Quantity_ordered'  -- It shows that the total no of orders has been placed by the customers in each country
from customers c   
join orders o
on c.customerNumber = o.customerNumber
join orderdetails od
on o.orderNumber = od.orderNumber
group by c.country
order by count(o.orderNumber) desc;

-- data comparision shows that despite germany being the second largest country in terms of customers it's not even in the top 10 when it comes to orders 
-- Top 5 countries by cutomers?
select country, count(*) as num_of_customer
from customers
group by country
order by num_of_customer desc;

-- top 5 employees ?
select e.employeeNumber,e.firstname,e.lastName,count(od.orderNumber) as 'no_of_orders_recived',sum(od.quantityOrdered) as 'Total_quantity_sold'
from employees e
join customers c  on e.employeeNumber = c.salesRepemployeeNumber
join orders o on c.customerNumber = o.customerNumber
join orderdetails od on o.orderNumber = od.orderNumber
group by e.employeeNumber,e.firstname,e.lastName
order by  no_of_orders_recived desc, Total_quantity_sold desc
limit 5;

-- Top 3 year’s that had the highest sales?
select year(o.orderdate),sum(quantityOrdered) as 'Total_quantity_sold'
from orders o 
join orderdetails od on o.orderNumber = od.orderNumber
group by year(o.orderdate)
order by Total_quantity_sold desc ;


-- Percent change in quantity sold
with cte1 as (
select year(o.orderdate) as 'Year',sum(quantityOrdered) as 'Total_quantity_sold'
from orders o 
join orderdetails od on o.orderNumber = od.orderNumber
group by year(o.orderdate)
order by Total_quantity_sold 
  )
select *, concat(round((Total_quantity_sold-lag(Total_quantity_sold) over(order by Year))/lag(Total_quantity_sold) over(order by Year) *100 ,2),'%')as percent_growth
from cte1;


-- total sales per year
select year(paymentDate) as year, sum(amount) 'total_sales'
from payments
-- group by year
order by total_sales desc;

-- Discovering Peak Order Months for Each Year?
with cte1 as (
SELECT Year(orderdate),
       Monthname(orderdate),
       Sum(quantityordered),
       rank() over(partition by Year(orderdate) order by sum(quantityordered) desc) as rankk
FROM   orders o
JOIN orderdetails od ON o.ordernumber = od.ordernumber
GROUP  BY Year(orderdate), Monthname(orderdate)
          )
select * from cte1
where rankk=1; 


-- Highlighting Top Products by Country
with ranking as(
	select c.country,
		   p.productName,
           count(od.orderNumber) as total_orders,
           dense_rank() over(partition by c.country order by count(od.orderNumber) desc) rankk
	from products p
	join orderdetails od on p.productCode = od.productCode
    join orders o on od.orderNumber = o.orderNumber 
    join customers c on o.customerNumber = c.customerNumber
    group by c.country, p.productName
    )
select * from ranking
where rankk <= 3;


-- Most Ordered Product Globally?
with cte1 as (
select p.ProductName,count(QuantityOrdered) 'order_Count',
rank() over(order by  count(QuantityOrdered) desc) as rankk
from orderdetails od
join products p on od.productCode = p.productCode
group by p.ProductName
	)
select * from cte1 
where rankk = 1
;

-- Which employee brought in most revenue?
select e.firstName,
		e.lastName,
        sum(p.amount) as 'Total_amount'
from employees e
join  customers c on e.employeeNumber = c.salesrepEmployeeNumber
join payments p on c.customerNumber = p.customerNumber
group by e.firstName, e.lastName
order by Total_amount desc;


-- yearly profit
select year(orderDate) as 'Year',sum((od.priceEach - p.buyprice)*od.quantityOrdered) as profit
from products p
join orderdetails od
on p.productCode = od.productCode
join orders o 
on od.orderNumber = o.orderNumber
group by year(orderDate)
order by profit desc;   																	# this shows that 2004 is the most profitable Year









