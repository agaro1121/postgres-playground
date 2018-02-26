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