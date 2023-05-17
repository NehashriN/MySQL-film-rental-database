use film_rental;
-- Questions:
-- 1.What is the total revenue generated from all rentals in the database? (2 Marks)
with t1 as (select rental_id,sum(amount) as revenue from payment group by rental_id)
select sum(revenue) as total_revenue from t1;

-- 2.How many rentals were made in each month_name? (2 Marks)
select monthname(rental_date) as 'Month',count(*) as number_of_rentals from rental 
group by monthname(rental_date);

-- 3.What is the rental rate of the film with the longest title in the database? (2 Marks)
select title,rental_rate from film where length(title)=(select max(length(title)) from film);

-- 4.What is the average rental rate for films that were taken from the last 30 days from the 
-- date("2005-05-05 22:04:30")? (2 Marks)
select avg(rental_rate) from film f
inner join inventory i
on i.film_id=f.film_id
inner join rental r
on i.inventory_id = r.inventory_id
where datediff(rental_date,"2005-05-05 22:04:30") <= 30;

-- 5.What is the most popular category of films in terms of the number of rentals? (3 Marks)
select name,count(*) as number_of_rentals from film f
inner join inventory i on i.film_id=f.film_id
inner join rental r on i.inventory_id = r.inventory_id
inner join film_category fc on f.film_id = fc.film_id
inner join category c on fc.category_id = c.category_id 
group by name
order by number_of_rentals desc
limit 1;
-- There are 16 categories of films, and sports is the category which is rented the most by the 
-- customers.

-- 6.Find the longest movie duration from the list of films that have not been rented by any 
-- customer. (3 Marks)
select title,length from film 
where film_id in (select distinct film_id from film where film_id not in (select distinct film_id from inventory))
order by length desc
limit 1;
-- There are 42 movies which have been not rented by any customer and film which is having longest
-- duration among those is CRYSTAL BREAKING with duartion of 184.

-- 7.What is the average rental rate for films, broken down by category? (3 Marks)
select name,round(avg(rental_rate),2) as avg_rental_rate from film f
inner join inventory i on i.film_id=f.film_id
inner join rental r on i.inventory_id = r.inventory_id
inner join film_category fc on f.film_id = fc.film_id
inner join category c on fc.category_id = c.category_id 
group by name
order by avg_rental_rate desc;

-- 8.What is the total revenue generated from rentals for each actor in the database? (3 Marks)
select a.actor_id,a.first_name,a.last_name,sum(amount) as total_revenue from rental r
inner join inventory i on i.inventory_id = r.inventory_id
inner join film f on i.film_id=f.film_id
inner join payment p on r.customer_id = p.customer_id
inner join film_actor fa on f.film_id = fa.film_id
inner join actor a on fa.actor_id = a.actor_id
group by a.actor_id
order by total_revenue desc;

-- 9.Show all the actresses who worked in a film having a "Wrestler" in the description. (3 Marks)
select distinct a.* from film f
inner join film_actor fa on f.film_id = fa.film_id
inner join actor a on fa.actor_id = a.actor_id
where description like "%Wrestler%" ;

-- 10.Which customers have rented the same film more than once? (3 Marks)
select r.customer_id,concat(first_name," ",last_name),f.title,count(r.rental_id) as count_rented from inventory i 
inner join rental r on i.inventory_id = r.inventory_id 
inner join film f on i.film_id = f.film_id
inner join customer c on r.customer_id = c.customer_id
group by 1,2,3
having count(r.rental_id) > 1;

-- 11.How many films in the comedy category have a rental rate higher than the average rental rate?
-- (3 Marks)
select count(title) from film f
inner join film_category fc on f.film_id = fc.film_id
inner join category c on fc.category_id = c.category_id 
where name='Comedy' and rental_rate > (select avg(rental_rate) from film);

-- 12.Which films have been rented the most by customers living in each city? (3 Marks)
with t1 as (select a.city_id,city,title,i.film_id,count(r.rental_id) as rental_num from rental r
inner join inventory i on i.inventory_id = r.inventory_id
inner join film f on f.film_id = i.film_id
inner join customer c on i.store_id = c.store_id
inner join address a on c.address_id = a.address_id
inner join city on city.city_Id = a.city_id
group by a.city_id,i.film_id
order by count(r.rental_id) desc)
select * from 
(select city,title,rental_num,rank() over(partition by city order by rental_num desc) as ranking
from t1) as t2 where ranking =1 order by rental_num desc;

-- 13.What is the total amount spent by customers whose rental payments exceed $200? (3 Marks)
with t1 as (select customer_id,sum(amount) as rental_payment from payment 
group by customer_id
having rental_payment > 200)
select sum(rental_payment) as total_amount from t1;

-- 14.Display the fields which are having foreign key constraints related to the "rental" table. 
-- [Hint: using Information_schema] (2 Marks)
use information_schema;
select table_name,column_name,constraint_name,referenced_table_name,referenced_column_name
from key_column_usage
where table_schema = 'film_rental' and table_name = 'rental'and referenced_column_name is not null;
  
-- 15.Create a View for the total revenue generated by each staff member, broken down by store 
-- city with the country name. (4 Marks)
create view Total_revenue_by_staff as 
select s.staff_id,s.store_id,city,country, sum(amount) as total_revenue from payment p
inner join rental r on p.rental_id = r.rental_id
inner join staff s on s.staff_id = r.staff_id
inner join address a on a.address_id = s.address_id
inner join city c on c.city_id = a.city_id
inner join country co on co.country_id = c.country_id
group by s.staff_id;
select * from Total_revenue_by_staff;

-- 16.Create a view based on rental information consisting of visiting_day, customer_name, the 
-- title of the film,  no_of_rental_days, the amount paid by the customer along with the 
-- percentage of customer spending. (4 Marks)
create view Rental_information as
select rental_date as visiting_date,concat(c.first_name," ",c.last_name) as customer_name,f.title,datediff(return_date,rental_date) as no_of_rental_days,
amount ,(amount/(select sum(amount) from payment where payment.customer_id = r.customer_id) * 100) as percent_spent from payment p
inner join rental r on r.rental_id = p.rental_id
inner join inventory i on i.inventory_id = r.inventory_id
inner join film f on f.film_id = i.film_id
inner join customer c on c.store_id = i.store_id;

select * from Rental_information;

-- 17.Display the customers who paid 50% of their total rental costs within one day. (5 Marks)
select r.customer_id,concat(c.first_name," ",c.last_name) as customer_name,date(payment_date),
sum(amount)/(select sum(amount) from payment where payment.customer_id = r.customer_id ) * 100 as percent_spent_in_single_day from payment p
inner join rental r on r.rental_id = p.rental_id
inner join customer c on c.customer_id = p.customer_id
group by 1,2,3
having percent_spent_in_single_day > 50
order by percent_spent_in_single_day desc;

-- It is observed that there are no customers who have paid 50% of their rental costs within one day 
-- as maximum percent of amount spent in a single day is 28.81 % by a customer.