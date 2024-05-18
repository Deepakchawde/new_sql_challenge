/* --------------------
   Case Study Questions
   --------------------*/

use 8dayssqlchallenge
-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Example Query:
-- 1. What is the total amount each customer spent at the restaurant?

select s.customer_id,sum(price) as total_sales
from sales as s
inner join menu as m 
on s.product_id = m.product_id
group by s.customer_id

-- 2. How many days has each customer visited the restaurant?

select customer_id, count(order_date) as no_of_visits
from sales
group by customer_id


-- 3. What was the first item from the menu purchased by each customer?

with detail as (
		select s.customer_id, s.order_date, s.product_id,m.product_name,m.price , row_number() over(partition by s.customer_id ) as ranks
		from sales as s
		inner join menu as m
		on s.product_id = m.product_id
)


select customer_id, product_name as first_order_product
from detail
where ranks = 1


-----------------------------------------------------------------------------------------------------------------------------------------------
select  customer_id,product_name as fistrt_order_product
from(
		select  s.customer_id, s.order_date, s.product_id,m.product_name,m.price , row_number() over(partition by s.customer_id ) as ranks
		from sales as s
		inner join menu as m
		on s.product_id = m.product_id
) as a
where ranks=1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 
select count(m.product_name) as No_of_time_product_order ,  m.product_name
from sales as s
inner join menu as m 
on s.product_id = m.product_id
group by m.product_name
order by  No_of_time_product_order desc
limit 1

-- 5. Which item was the most popular for each customer?       ##
with product_no_of_time as (
		select s.customer_id ,  m.product_name , count(*) as No_of_time_order, dense_rank() over(Partition by  s.customer_id order by count(*)) as rn
		from sales as s
		inner join menu as m 
		on s.product_id = m.product_id 
		group by s.customer_id,   m.product_name

)

select customer_id, product_name
from product_no_of_time
where rn=1



-- 6. Which item was purchased first by the customer after they became a member?    ##

with ranks1 as (
		select s.customer_id, s.order_date, s.product_id, m.product_name, mm.join_date , dense_rank()  over( partition by s.customer_id order by s.order_date) as ranks
		from sales as s
		inner join menu as m 
		on s.product_id = m.product_id
		inner join members as mm 
		on mm.customer_id = s.customer_id
		where s.order_date >=  mm.join_date
)

select customer_id, product_id, product_name 
from ranks1 
where ranks=1

-- 7. Which item was purchased just before the customer became a member?


with ranks1 as (
		select s.customer_id,s.order_date,s.product_id,m.product_name,mm.join_date , dense_rank()  over( partition by s.customer_id order by s.order_date desc) as ranks
		from sales as s
		inner join menu as m 
		on s.product_id = m.product_id
		inner join members as mm 
		on mm.customer_id = s.customer_id
		where s.order_date < mm.join_date

)
select customer_id, Product_id, product_name
from ranks1
where ranks =1group by customer_id




-- 8. What is the total items and amount spent for each member before they became a member?
with total_sales as (
			select customer_id, sum(price) as amount_spend
from (
		select s.customer_id,s.order_date,s.product_id,m.product_name,mm.join_date, m.price
		from sales as s
		inner join menu as m 
		on s.product_id = m.product_id
		inner join members as mm 
		on mm.customer_id = s.customer_id
		where s.order_date <  mm.join_date
		order by order_date desc
) as a 
group by customer_id, price

)

select customer_id , sum(amount_spend) as amount_spend
from total_sales
group by  customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with pointss as(
		select  s.customer_id,s.order_date,s.product_id,m.product_name, m.price,
			case when m.product_name = "sushi" then m.price*20
			else m.price*10
			end as points
		from sales as s
		inner join menu as m 
		on s.product_id = m.product_id
)

select customer_id, sum(points) as total_points
from pointss
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?


with ponitses as (
			select s.customer_id,s.order_date,s.product_id,m.product_name,mm.join_date, m.price,
				case
				when s.order_date between mm.join_date and date_add( mm.join_date, interval 7 day) then m.price*10*2
				else m.price*10
				end as points        
			from sales as s
			inner join menu as m 
			on s.product_id = m.product_id
			inner join members as mm 
			on mm.customer_id = s.customer_id
			where s.order_date between "2021-01-01" and "2021-01-30"
)

select customer_id, sum(points) as total_points
from ponitses
group by customer_id


-- bonus questions fetch the date and add the column that the time of order the customer is member or not 
select s.customer_id,s.order_date,s.product_id,m.product_name, m.price , mm.join_date,
	case when  	mm.join_date <= s.order_date then "Y"
    else "N"
    end as yes_or_no
from sales as s
left join menu as m 
on s.product_id = m.product_id
left join members as mm 
on mm.customer_id = s.customer_id


-- rank the previous out put base on the order date for each customerdisplay null when customer was not menber WHEN DISH WAS ORDER
with demo as(
		select s.customer_id,s.order_date,s.product_id,m.product_name, m.price , mm.join_date,
			case when  	mm.join_date <= s.order_date then "Y"
			else "N"
			end as yes_or_no
		from sales as s
		left join menu as m 
		on s.product_id = m.product_id
		left join members as mm 
		on mm.customer_id = s.customer_id
)

select * , 
	case when join_date is null then "-"
    else dense_rank() over(partition by customer_id order by order_date) 
    end as rnk
from demo 