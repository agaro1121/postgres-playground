select * from film;

-- explain - only estimate
EXPLAIN select * from film;

-- Seq Scan on film  (cost=0.00..64.00 rows=1000 width=384)
-- cost = (disk pages read * seq_page_cost) + (rows scanned * cpu_tuple_cost
  -- seq_page_cost && cpu_tuple_cost are constants
    -- seq_page_cost = estimated cost of disk page fetch. Default = 1
    -- cpu_tuple_cost = estimated cost of processing a row. Default = 0.01
  -- disk pages read && rows scanned are determined by table attributes -> use below query to find these values
select
	relpages as "disk pages read",
	reltuples as "rows scanned"
from pg_class
where relname = 'film'
;


EXPLAIN select * from film where film_id > 40; -- sequential scan + filter
EXPLAIN select * from film where film_id < 40; -- index scan + index condition (indexed column film_id)

EXPLAIN select * from film where film_id > 40 and rating = 'PG-13'; --sequential scan + filter after
EXPLAIN select * from film where film_id < 40 and rating = 'PG-13'; --index scan + index cond + filter after(because we do not have an index on rating column so we have to filter)

-- explain + analyze - actually runs query and generates metrics
EXPLAIN ANALYZE select * from film;
-- Seq Scan on film  (cost=0.00..64.00 rows=1000 width=384) (actual time=0.008..0.239 rows=1000 loops=1)
  -- actual time=starting time..total time taken
  -- loops=1 means it only did a full table scan once
  
EXPLAIN ANALYZE select * from film where film_id > 40;
EXPLAIN ANALYZE select * from film where film_id < 40;

-- poorly written query. Does a full table scan to get 1000 rows then removes 784 of them with filter afterwards
EXPLAIN ANALYZE select * from film where film_id > 40 and rating = 'PG-13';
-- poorly written query. Does an index scan to get 40 rows then removes 32 of them with filter afterwards
EXPLAIN ANALYZE select * from film where film_id < 40 and rating = 'PG-13';


---------------------------------- indexes - Max: 32 columns
  -- most effective when there are constraints on left-most (leading) column
select 
*
from film
where length = 60;

EXPLAIN ANALYZE select 
*
from film
where length = 60;

CREATE INDEX idx_film_length ON film (length);

DROP INDEX idx_film_length;
----------------------- multi-column index -----------------------------------
select title, length, rating, replacement_cost, rental_rate
from film
where length between 60 and 70 and rating = 'G'
;

explain analyze select title, length, rating, replacement_cost, rental_rate
from film
where length between 60 and 70 and rating = 'G'
;

CREATE INDEX idx_film_length ON film (length);
CREATE INDEX idx_film_length_rating ON film (length, rating); -- these 2 indexes can co-exist. Postgres picks which one is better. Speed isnt' much better
CREATE INDEX idx_film_rating_length ON film (rating, length); -- Postgres uses this one. It is much better since it is easier to query on rating since it is not in a range.
/*
	Instructions:
	1) Play around to see which leading column gives your index better performance
	2) Drop all other indexes with same columns so writes are not impacted
*/

DROP INDEX idx_film_length;
DROP INDEX idx_film_length_rating;
DROP INDEX idx_film_rating_length;

----------------------- cover index -----------------------------------
-- contains all the columns in select and where clauses

select title, length, rating, replacement_cost, rental_rate
from film
where length between 60 and 70 and rating = 'G'
;

EXPLAIN ANALYZE select title, length, rating, replacement_cost, rental_rate
from film
where length between 60 and 70 and rating = 'G'
;



CREATE INDEX idx_film_cover ON film (rating, length, title, replacement_cost, rental_rate);

----------------------- index maintenance -----------------------------------

  -- reindex a specific index
REINDEX INDEX idx_film_cover;
  -- reindex whole table
REINDEX TABLE film;



----------------------- Unique indexes -----------------------------------

/*
	Unique Index - Basically, you never need to do this yourself
	Primary Key - Automatically creates a Unique Index
	Unique Constraint - Automatically creates a Unique Index
*/

create table SampleTable(
	id integer PRIMARY KEY, --notice there is no index in the GUI, but it's still there somehow
	firstcol character varying(40),
	secondcol integer
);

-- view primary key index below
SELECT
	idx.indrelid :: REGCLASS AS table_name,
	i.relname				 AS index_name, --rel = relation
	idx.indisunique			 AS is_unique,
	idx.indisprimary		 AS is_primary
FROM pg_index AS idx	
	JOIN pg_class as i ON idx.indexrelid = i.oid
WHERE idx.indrelid = 'sampletable'::regclass
;

CREATE INDEX id_SampleTable_id ON SampleTable (id);

ALTER TABLE sampletable
	ADD CONSTRAINT sampletable_firstcol UNIQUE (firstcol); -- not visible in GUI

CREATE UNIQUE INDEX unq_sampletable_firstcol ON SampleTable (firstcol); -- visible in GUI


----------------------- Case insensitve search -----------------------------------

select 
* 
from film
where title = 'Arizona Bang';

EXPLAIN ANALYZE select 
* 
from film
where title = 'Arizona Bang';

-- indexes are thrown out when functions are applied in where clauses like below
EXPLAIN ANALYZE select 
* 
from film
where lower(title) = 'arizona bang';

EXPLAIN ANALYZE select 
* 
from film
where lower(title) = lower('arizona bang');

CREATE INDEX film_title_search_lower
	ON film (lower(title)); --functions can be used in creating indexes


----------------------- Partial Index -----------------------------------


















