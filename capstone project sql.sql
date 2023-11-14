-- 
use classicmodels;

-- Tables in the database.
show tables;

-- Total cutomers?
select count(distinct(customerNumber)) as 'Total customers' from customers;

-- Checking if we have a customer who is not assigned salesrepemployeenumber 
select customerNumber 
from customers 
where salesRepEmployeeNumber is null;

-- If there is no Sales reprsentative is assigned to the customer, it means that the customer has not ordered a single time
select * 
from orders 
where customerNumber in (
					select customerNumber 
					from customers 
					where salesRepEmployeeNumber is null);
# yes it's true 
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
join customers c    # Here table payemnts is joined on table customers to find out the name,id and sum of payments they paid and the result is limited to 5
on p.customerNumber = c.customerNumber
group by c.customerName,p.customerNumber
order by sum(p.amount) desc
limit 5;   

-- Most popular productline?
select p.productline,sum(o.quantityordered) as 'Qty_sold'
from orderdetails o
join products p          # here table orderdetails is joined with table products to find the total quantity ordered of the productline and the results are ordered by 
on o.productCode = p.productCode # total quantity sold of each product
group by p.productline
order by sum(o.quantityordered) desc;

-- Top 5 countries by Who orders the most?
select c.country,sum(od.quantityordered) as 'Quantity_ordered'  -- It shows that the total no of orders has been placed by the customers in each country
from customers c   
join orders o
on c.customerNumber = o.customerNumber
join orderdetails od
on o.orderNumber = od.orderNumber
group by c.country
order by sum(o.orderNumber) desc
limit 5;

-- Countries by cutomers?
select country, count(*) as num_of_customer
from customers
group by country
order by num_of_customer desc;

-- data comparision of the above two queries shows that 
-- despite germany being the second largest country in terms of customers it's not even in the top 10 when it comes to orders 

-- top 5 employees ?
select e.employeeNumber,e.firstname,e.lastName,count(od.orderNumber) as 'no_of_orders_recived',sum(od.quantityOrdered) as 'Total_quantity_sold'
from employees e
join customers c  on e.employeeNumber = c.salesRepemployeeNumber
join orders o on c.customerNumber = o.customerNumber
join orderdetails od on o.orderNumber = od.orderNumber
group by e.employeeNumber,e.firstname,e.lastName
order by  no_of_orders_recived desc, Total_quantity_sold desc
limit 5;
# In the above query table customers orders and orderdetails are joined with each other to find the count of orders,
# and the total quantity sold in these orders and the output is limited to 5

-- year’s that had the highest sales?
select year(o.orderdate),sum(quantityOrdered) as 'Total_quantity_sold'
from orders o 
join orderdetails od on o.orderNumber = od.orderNumber
group by year(o.orderdate)
order by Total_quantity_sold desc
limit 1 ;


-- Percent change in quantity sold
with cte1 as (
select year(o.orderdate) as 'Year',sum(quantityOrdered) as 'Total_quantity_sold'
from orders o 
join orderdetails od on o.orderNumber = od.orderNumber
group by year(o.orderdate)
order by Total_quantity_sold 
  )
select *, concat(round((Total_quantity_sold-lag(Total_quantity_sold) over(order by Year))  /  lag(Total_quantity_sold) over(order by Year) *100 ,2),'%')as percent_growth
from cte1;
 # The  percent change formula used here is ((New_value-old_value)/Old_value) * 100
 # first the Year wise total quantity is calculated in the cte1 
 # then using the lag window function the previous year total quatity sold it calculated and 
 # then the formula is used  to find out the 


-- Discovering Peak Order Months for Each Year?
with cte1 as (
SELECT Year(orderdate),
       Monthname(orderdate),
       Sum(quantityordered),
       dense_rank() over(partition by Year(orderdate) order by sum(quantityordered) desc) as rankk
from   orders o
join orderdetails od ON o.ordernumber = od.ordernumber
group by Year(orderdate), Monthname(orderdate)
          )
select * from cte1
where rankk=1; 
# In the above cte1  first the tables orders and orderdetails are joined 
# Then the total of quantityOrdered is calculated monthly for each year and  
# Rank is given to each month using the dense_rank() window funtion according to the total quantity orderd descinding 
# Then outside the cte1 those months are selected which has max totalquantity ordered ie, where rankk = 1

-- Highlighting Top Products by Country
with ranking as(
	select c.country,
		   p.productName,
           sum(od.quantityordered) as total_orders,
           dense_rank() over(partition by c.country order by sum(od.quantityordered) desc) rankk
	from products p
	join orderdetails od on p.productCode = od.productCode
    join orders o on od.orderNumber = o.orderNumber 
    join customers c on o.customerNumber = c.customerNumber
    group by c.country, p.productName
    )
select * from ranking
where rankk = 1;
# In the above ranking  first the tables products ,customers, orders and orderdetails are joined 
# Then the total of quantityOrdered is calculated according to each country
# Rank is given to each product using the dense_rank() window funtion according to the total quantity orderd descinding 
# Then from the ranking cte those months are selected which has max totalquantity ordered i.e, where rankk = 1

-- Most Ordered Product Globally?
with cte1 as (
select p.ProductName,
		count(QuantityOrdered) 'order_Count', # Because each order contains many products that's why count of quantityOrdered is used 
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









