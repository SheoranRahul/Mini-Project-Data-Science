####################################---MINI PROJECT 2-----######################################
create database mini_project_2;
use mini_project_2;         
select * from  cust_dimen;
select * from  market_fact;
select * from orders_dimen;
select * from prod_dimen;
select * from shipping_dimen;

# Q.1.1.	Join all the tables and create a new table called combined_table.
#		    (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
create table combined_table as
select mf.*,ct.customer_name,ct.province,ct.region,ct.customer_segment,
od.order_id,od.order_date,od.order_priority,
pd.product_category,pd.product_sub_category,
sd.ship_mode,sd.ship_date from shipping_dimen as sd
join
market_fact as mf
on
sd.ship_id=mf.ship_id
join
cust_dimen as ct
on
mf.cust_id=ct.cust_id
join
orders_dimen as od
on
mf.ord_id=od.ord_id
join
prod_dimen as pd
on
mf.prod_id=pd.prod_id;

# Q.2. Find the top 3 customers who have the maximum number of orders

select customer_name,order_quantity
from
cust_dimen as ct
join 
market_fact as mf
on
ct.cust_id=mf.cust_id
order by order_quantity
desc limit 3;

# Q.3.	Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
update orders_dimen set order_date=str_to_date(order_date,'%d-%m-%Y');
alter table orders_dimen modify order_date date;
update shipping_dimen set ship_date=str_to_date(ship_date,'%d-%m-%Y');
alter table shipping_dimen modify ship_date date;

select *,datediff(ship_date,order_date) as DaysTakenForDelivery
from
orders_dimen as od
join 
shipping_dimen as sd
on
od.order_id=sd.order_id;
# Q.4 .	Find the customer whose order took the maximum time to get delivered.

select customer_name,datediff(ship_date,order_date) as DaysTakenForDelivery
from
orders_dimen as od
join 
shipping_dimen as sd
on
od.order_id=sd.order_id
join
market_fact as mf
on
sd.ship_id=mf.ship_id
join
cust_dimen as ct
on
mf.cust_id=ct.cust_id
order by 
DaysTakenForDelivery
desc
limit 1 ;
# Q.5 	Retrieve total sales made by each product from the data (use Windows function)

select distinct product_category,product_sub_category,round(sum(sales)over(partition by mf.prod_id),2) as total_sales
from
prod_dimen as pd
join
market_fact as mf
on
pd.prod_id=mf.prod_id;

#Q.6.	Retrieve total profit made from each product from the data (use windows function)

select distinct
product_category,product_sub_category,pd.prod_id,
sum(mf.profit)
over(partition by mf.prod_id)total_profit
from market_fact as mf
join
prod_dimen as pd
on
mf.prod_id=pd.prod_id
order by pd.prod_id asc;

# Q.7.Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
create view ucw as
select distinct
mf.cust_id from market_fact as mf
join orders_dimen as od
on
mf.ord_id=od.ord_id
where date_format(od.order_date,'%Y-%m')='2011-01';
select 
count( mf.cust_id) as customer_came_back
from market_fact as mf
join
orders_dimen as od
on 
mf.ord_id=od.ord_id
right join
ucw as u
on
u.cust_id=mf.cust_id
where date_format(od.order_date,'%Y')='2011';

# Q.8 	Retrieve month-by-month customer retention rate since the start of the business.(using views)
create view visit as
(select customer_name,order_date,month(order_date) month
from combined_table
order by customer_name,order_date);

create view following as
(select *,lead(order_date) over() nextvisit from visit);

create view retention as
(select *,datediff(nextvisit,order_date) retention_value from following);

create view retentionfinal as
(select *,
(case
when retention_value<0 then null
when retention_value between 0 and 30 then 'retained'
when retention_value between 31 and 90 then 'irregular'
else 'churned'
end) retention_status
from retention);

select month,retention_status,
(count(retention_status)/(select count(retention_status) from retentionfinal where month=rf.month))*100  as retention_rate_percentage
from retentionfinal rf
where retention_status='retained'
group by month,retention_status
order by month;
	   