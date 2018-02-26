select * from actor;

-- text mangling
select * from actor where last_name like 'Faw%' order by first_name DESC;
select * from actor where last_name like '%awc%' and lower(first_name) = 'julia';
select * from actor where last_name like '%awc%' and upper(first_name) = 'BOB';
select char_length('Saluton');
select length('Saluton');
select reverse('Saluton');
select left('Saluton', 2); -- no right, just reverse and left. Behaves like scala "text".take(n)
select ('Saluton' || ' ' || 'Mondo');
select concat('Saluton', ' ', 'Mondo');
select replace('Saluton', 'u', '@');

-- range -- INCLUSIVE
select * from actor where actor_id BETWEEN 100 and 110;
select * from actor where actor_id >= 100 and actor_id <= 110;


-- aggregate
select a.first_name, count(a.first_name)
from actor a 
GROUP BY a.first_name
HAVING count(a.first_name) > 1;

-- total rentals ever
select count(*) from rental;

-- first and last rental ever
select 	MIN(rental_date) first_rental,
		MAX(rental_date) last_rental
from rental 
;

-- total payment
select 
sum(amount) total_rental_amount
from payment;



-- time functions
select now(); -- === current_timestamp?
select current_date;
select current_time;
select current_timestamp;
select localtime;
select localtimestamp;

select date'2001-09-28' + integer'7'; -- new date
select date'2001-09-28' + time'03:00'; -- ts
select date'2001-09-28' - date'2001-09-25'; -- 3 days
select make_date(2018, 03, 31);
select timeofday();

-- rental duration
select return_date, rental_date,
		return_date - rental_date -- days and hours
from rental;

-- rental duration > 3 days
select return_date, rental_date,
		return_date - rental_date rented_days -- days and hours
from rental
where EXTRACT(days FROM return_date - rental_date) > 3;

-- rental duration > 100 hours
select return_date, rental_date,
		return_date - rental_date rented_days -- days and hours
		,EXTRACT(epoch FROM return_date - rental_date) duration_in_seconds
		,EXTRACT(epoch FROM return_date - rental_date)/3600 duration_in_hours
from rental
where EXTRACT(epoch FROM return_date - rental_date)/3600 > 100;

-- return_date as 7 days from rental
select rental_date,
		rental_date + interval'7 day' as new_return_date
from rental;		




-------------- Joins
select * from students;
select * from classes;
select * from studentclass;

-- inner join
-- which student takes which classes
select st.studentname, cl.classname
from studentclass sc
INNER JOIN students st ON sc.studentid = st.studentid
INNER JOIN classes cl ON sc.classid = cl.classid;

-- LEFT OUTER JOIN
-- which student takes NO classes
select st.studentname
from students st
LEFT JOIN studentclass sc ON sc.studentid = st.studentid
LEFT JOIN classes cl ON sc.classid = cl.classid
where classname is null
;
select st.studentname
from students st
LEFT JOIN studentclass sc ON sc.studentid = st.studentid
where sc.classid is null
;

-- RIGHT OUTER JOIN
-- classes not signed up for
select cl.classname
from studentclass sc
RIGHT JOIN classes cl ON sc.classid = cl.classid
where studentid is null
;
select cl.classname
from students st
RIGHT JOIN studentclass sc ON sc.studentid = st.studentid
RIGHT JOIN classes cl ON sc.classid = cl.classid
where studentname is null
;

-- CROSS/CARTESIAN JOIN
-- how big classes would get if all students signed up for all classes
select  cl.classname, st.studentname
from students st
CROSS JOIN classes cl
--group by cl.classname, st.studentname
group by 1,2
;

-- FULL OUTER JOIN
-- students and the classes they joined, students with NO classes, AND classes with no students
select st.studentname, cl.classname
from students st
FULL JOIN studentclass sc ON sc.studentid = st.studentid
FULL JOIN classes cl ON sc.classid = cl.classid
;

-- MATH ops
-- rounding
select film_id, title, length,
		(length/60.0) length_in_hour, -- division with float
		round( (length/60.0), 2) length_in_hour_rounded --round
from film;

-- ceiling - round up
select film_id, title, rental_rate,
		ceiling(rental_rate) rental_rate_new
from film;		

-- Math and alias from dual
select pi() * (10^2) as area_of_circle;

select left('Hi', 3);


-- type conversions

select * from rental
where inventory_id = 2346;
-- implicit
select * from rental
where inventory_id = '2346'; -- '2346' gets converted to INT so query can run. This has performance implications
-- explicit - always better. Code is more: readable, performant, portable
select * from rental
where inventory_id = integer '2346';

select 30 ! ;
select CAST(30 as bigint) !; --same as above

select ROUND(4, 5);
select ROUND(CAST(4 as numeric), 5); --same as above
select ROUND(4.0, 5); -- same as first

select SUBSTR('4321', 2);
select SUBSTR(CAST ('4321' AS TEXT), 2); --same as above


-- triggers
CREATE TABLE Employee(empname TEXT, salary INT);
select * from employee;

CREATE FUNCTION emp_stamp() RETURNS trigger AS $emp_stamp$
	BEGIN
		IF NEW.empname is NULL THEN --'NEW' is a postgres internal variable representing the new record being inserted
			RAISE EXCEPTION 'Employee Name column cannot be null';
		END IF;	
		IF NEW.salary is NULL THEN
			RAISE EXCEPTION '% cannot have null salary', NEW.empname; --string format for exception
		END IF;	
		IF NEW.salary < 0 THEN
			RAISE EXCEPTION '% cannot have negative salary', NEW.empname;
		END IF;	
			
		RETURN NEW; --let row pass through as-is	
	END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER emp_stamp BEFORE INSERT OR UPDATE ON Employee
	FOR EACH ROW EXECUTE PROCEDURE emp_stamp();
	
	
insert into employee (empname) values('Jon'); -- fails cuz of trigger
insert into employee (salary) values(100); -- fails cuz of trigger
insert into employee (empname, salary) values('Steve', -100); -- fails cuz of trigger
insert into employee (empname, salary) values('Jon', 100);


-- views
CREATE VIEW current_customer_payment_total AS
select concat(first_name, ' ', last_name) as customer_name, sum(amount) as total_paid
from payment p
inner join customer c on c.customer_id = p.customer_id
group by customer_name;

select * from current_customer_payment_total;