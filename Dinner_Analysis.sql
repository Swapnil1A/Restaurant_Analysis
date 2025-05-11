select * from menu
select * from members
select * from sales

--Total Amount each customer spent at the restaurant
select customer_id,sum(menu.price) as total_price from sales
join menu on sales.product_id=menu.product_id
GROUP by customer_id
ORDER by total_price desc

--how many days has each customer visited the restaurant
select customer_id,count(distinct order_date) as Number_of_days from sales
GROUP by customer_id
order by Number_of_days desc

--what was the first item purchased by the customer from the menu

with s as(
SELECT sales.customer_id,menu.product_name,row_number() over(PARTITION by customer_id order by order_date asc) as rank_1 from sales
join menu on sales.product_id=menu.product_id
)
SELECT * from s
where rank_1=1

--what is the most purchased item on the menu and how many times was it purchased by all customers

select menu.product_name,sales.product_id ,count(*) as total_count_product from sales
join menu on sales.product_id=menu.product_id
GROUP by 1,2
order by total_count_product desc
limit 1

--Which item is most popular for which customer
with cte as(
select sales.customer_id,sales.product_id,menu.product_name,count(*) as total_count_product,row_number() over(PARTITION by customer_id order by count(*) desc) as rank_1 from sales
join menu on sales.product_id=menu.product_id
GROUP by 1,2,3
)
SELECT * from cte
where rank_1=1

--which item was first puchased by the customer after they become the member
with cte as(
select sales.customer_id,menu.product_name,join_date,order_date,row_number()over(PARTITION by sales.customer_id order by order_date asc) as rank_1 from menu
join sales on sales.product_id=menu.product_id
join members on sales.customer_id=members.customer_id
where order_date>=join_date
)
select * from cte
where rank_1=1

--which item was purchased by the customer just before becoming the member
with cte as(
select sales.customer_id,menu.product_name,join_date,order_date,row_number() over(PARTITION by sales.customer_id order by order_date desc) as rank_1 from menu
join sales on sales.product_id=menu.product_id
join members on sales.customer_id=members.customer_id
where order_date<join_date
)
select customer_id,product_name from cte
where rank_1=1;

--what is the items and amount spent by each customer before they became the members

    SELECT sales.customer_id,sum(menu.price) as total_price,count(order_date) as c from sales
    join menu on sales.product_id=menu.product_id
    join members on sales.customer_id=members.customer_id
    where order_date<join_date
    GROUP by 1
    order by c desc

--if each $1 spent equates to 10 points & sushi has a 2x points multiplier - how many points would each customer have.

select sales.customer_id,
sum(
    CASE
    when product_name='sushi' then price*10*2
    else price*10
    end) as points
 from sales
 join menu on sales.product_id=menu.product_id
 group by 1

 --Join all the things
 select s.customer_id,s.order_date,m.product_name,m.price,
 CASE
 when order_date>=join_date then 'Y'
 else 'N'
 end as Members
from sales s
join menu m on s.product_id=m.product_id
left join members p on s.customer_id=p.customer_id
order by s.customer_id,s.order_date,m.product_name

--Rank all Things
with cte as(
select s.customer_id,s.order_date,m.product_name,m.price,
 CASE
 when order_date>=join_date then 'Y'
 else 'N'
 end as Member
from sales s
join menu m on s.product_id=m.product_id
left join members p on s.customer_id=p.customer_id
order by s.customer_id,s.order_date,m.product_name
)
select *,
CASE 
when Member='N' then NULL
ELSE
rank() over(PARTITION by customer_id,Member order by order_date asc) 
end as rnk
from cte;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items,not just sushi - how many points do customer A and B have at the end of january.
with cte as(
select s.customer_id,s.order_date,m.product_name,m.price,
 CASE
 when product_name='sushi' then 2*m.price
 when order_date BETWEEN p.join_date AND date_add(p.join_date,INTERVAL 6 DAY) THEN 2*m.price
 else m.price
 end as points
from 
sales s
join menu m on s.product_id=m.product_id
join members p on s.customer_id=p.customer_id
where 
date_format(order_date,'%Y-%m-01')='2021-01-01'
)
select customer_id,
sum(points)*10 as total_points
from cte
group by customer_id
order by customer_id








