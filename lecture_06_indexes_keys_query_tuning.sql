-- =============================================================================
-- Topics  : Indexes (Clustered / Non-Clustered / Composite),
--           Natural Keys vs Surrogate Keys, Composite Keys,
--           Query Fine Tuning Techniques, EXPLAIN, EXISTS
-- =============================================================================

USE sakila;


-- =============================================================================
-- 1. INDEXES
-- =============================================================================
-- An index is like the index page of a book.
-- Without an index, MySQL scans every row one by one to find what you need.
-- With an index, MySQL jumps directly to the matching rows. Much faster.

--
-- Indexes reduce cost, reduce time, and reduce computation during data fetch.
-- There are 3 types: Clustered, Non-Clustered, Composite.

-- ─────────────────────────────────────────────────────────────
-- 1.1 CLUSTERED INDEX
-- ─────────────────────────────────────────────────────────────
-- A clustered index determines the PHYSICAL ORDER of data rows in the table.
-- The data itself is stored in sorted order based on this index.
-- In MySQL InnoDB, the PRIMARY KEY is always the clustered index.
-- There can be ONLY ONE clustered index per table.
-- When you create a primary key, MySQL automatically creates the clustered index.
--
-- EXPLAIN output types:
-- type = const  -> clustered index (PK), fetching exactly 1 row. Fastest.
-- type = ref    -> using a non-clustered index reference.
-- type = ALL    -> full table scan. No index used. Worst case.
-- rows          -> how many rows MySQL will scan.
-- key           -> which index MySQL is actually using.

-- customer_id is the primary key (clustered index) in the customer table.
-- Searching by primary key is the fastest possible lookup.
SELECT customer_id, first_name, last_name
FROM customer
WHERE customer_id = 10;

-- Use EXPLAIN to see the execution plan
EXPLAIN SELECT customer_id, first_name, last_name
FROM customer
WHERE customer_id = 10;
-- type = const, rows = 1, key = PRIMARY -> clustered index used. Fastest.

-- See all indexes on a table
SHOW INDEX FROM customer;

-- ─────────────────────────────────────────────────────────────
-- 1.2 NON-CLUSTERED INDEX
-- ─────────────────────────────────────────────────────────────
-- A non-clustered index does NOT change the physical order of the data.
-- It is a SEPARATE structure stored in memory.
-- It stores the indexed column value + a pointer that references the actual row.
-- You can create MULTIPLE non-clustered indexes on the same table.
-- Used for non-primary key columns that are frequently filtered or searched.
--
-- How it works:
-- Original table stays in its physical order (sorted by primary key).
-- A separate index structure is built containing:
--   [indexed column value] -> [pointer to actual row location]
-- When you filter by that column, MySQL goes to the index first,
-- finds the pointer, then jumps directly to the matching rows.
-- No full table scan needed.
--
-- Without index on product_name: EXPLAIN shows type = ALL, rows = 14.
-- After CREATE INDEX on product_name: type = ref, rows scanned drops.
-- After CREATE INDEX on product_name AND amount: type = index_merge, rows drop further.
-- DROP INDEX: type goes back to ALL (full table scan again).

-- Create non-clustered index on last_name column
CREATE INDEX idx_customer_last_name ON customer(last_name);

-- Now this query uses the index instead of scanning the whole table
SELECT customer_id, first_name, last_name
FROM customer
WHERE last_name = 'SMITH';

-- EXPLAIN shows index is being used now
EXPLAIN SELECT customer_id, first_name, last_name
FROM customer
WHERE last_name = 'SMITH';

-- JOIN also benefits from indexes on the join columns
SELECT c.customer_id, c.first_name, c.last_name, p.amount, p.payment_date
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
WHERE c.customer_id = 5;

-- Drop index when no longer needed
DROP INDEX idx_customer_last_name ON customer;
-- After DROP: EXPLAIN shows type = ALL again (full table scan)

-- Index names must be UNIQUE. You cannot reuse the same index name on a different table.
-- Trying to do so throws: ERROR: Duplicate key name 'index_name'.
-- Always use descriptive names like: idx_tablename_columnname.

-- ─────────────────────────────────────────────────────────────
-- 1.3 COMPOSITE INDEX
-- ─────────────────────────────────────────────────────────────
-- A composite index is created on MULTIPLE COLUMNS together.
-- Useful when queries always filter on a combination of columns.
-- Column order in the composite index matters.
-- The index works best when the query filters on the leftmost columns first.

CREATE INDEX idx_rental_customer_date ON rental(customer_id, rental_date);

-- This query benefits from the composite index on (customer_id, rental_date)
SELECT rental_id, customer_id, rental_date, return_date
FROM rental
WHERE customer_id = 10
ORDER BY rental_date;


-- =============================================================================
-- 2. NATURAL KEYS vs SURROGATE KEYS
-- =============================================================================
-- When creating a primary key we have two choices for what that key is:
-- Option 1: use a column that already exists naturally in the data (NATURAL KEY)
-- Option 2: create a system-generated artificial ID (SURROGATE KEY)

-- ─────────────────────────────────────────────────────────────
-- 2.1 NATURAL KEY
-- ─────────────────────────────────────────────────────────────
-- A natural key is a column that already exists in the real world and
-- uniquely identifies a record by its own nature.
-- Examples: SSN number, Aadhaar card, Passport number, Email address.
--
-- Key property: uniqueness comes from reality, not from the system.
-- An SSN is unique to one person. A passport number stays unique even after expiry.
-- (The same passport number is never reassigned to someone else.)
--
-- Problem with natural keys:
-- Natural data CAN change -- customer changes email, phone, name.
-- If email is the primary key and customer changes it, every child table
-- referencing it also needs to update. Risk of broken references.
-- That is why natural keys are often NOT preferred as primary keys.

-- Email is a natural key for customer -- unique real-world value
SELECT customer_id, first_name, last_name, email
FROM customer
WHERE email = 'MARY.SMITH@sakilacustomer.org';

SELECT customer_id, first_name, last_name, email
FROM customer
WHERE email = 'PATRICIA.JOHNSON@sakilacustomer.org';

-- ─────────────────────────────────────────────────────────────
-- 2.2 SURROGATE KEY
-- ─────────────────────────────────────────────────────────────
-- A surrogate key is an ARTIFICIAL identifier created by the system.
-- It has NO real-world meaning. It exists only inside the database.
-- Typically created using AUTO_INCREMENT.
--
-- AUTO_INCREMENT behaviour:
-- Default starts at 1. Each new row gets the next value: 1, 2, 3, 4...
-- You can set the starting value: AUTO_INCREMENT = 1000 -> starts at 1000.
-- When a record is deleted the number is NOT reused. Sequence continues.
-- Deletion creates gaps (1, 2, 4, 5 if 3 was deleted). That is normal.
--
-- Why surrogate keys are preferred:
-- Never changes. The auto-generated ID stays with the row forever.
-- No dependency on changing business data.
-- Simple integer = efficient for indexing and joining.
-- Already unique by construction (AUTO_INCREMENT guarantees uniqueness).
--
-- Examples in sakila (all surrogate keys):
-- customer_id, film_id, actor_id, rental_id, payment_id, address_id

-- Surrogate key example: customer_id connects customer and rental
SELECT c.customer_id, c.first_name, c.last_name, r.rental_id, r.rental_date
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
WHERE c.customer_id = 1;

-- ─────────────────────────────────────────────────────────────
-- 2.3 Key relationships 
-- ─────────────────────────────────────────────────────────────
-- Are all natural keys primary keys?   -> NO. Not all natural keys are used as PK.
-- Are all primary keys natural keys?   -> NO. Primary keys can be surrogate keys.
-- Are all surrogate keys primary keys? -> NO. Surrogate CAN be PK only if unique.
-- Are all primary keys surrogate keys? -> NO. PK can be a natural key.
--
-- Primary Key = either a Natural Key OR a Surrogate Key (not both)
-- Natural keys CAN be PKs if they are unique, stable, and never change.
-- But most databases prefer surrogate keys because they never change.

-- ─────────────────────────────────────────────────────────────
-- 2.4 COMPOSITE KEY
-- ─────────────────────────────────────────────────────────────
-- When no single column uniquely identifies a row, combine 2 or 3 columns
-- to form ONE primary key. This is called a COMPOSITE KEY.
-- A table can have only ONE primary key -- but it can span multiple columns.
-- Example: first_name alone is not unique. last_name alone is not unique.
-- But first_name + last_name + email together may be unique.
-- A composite primary key is still a clustered index.

-- Composite key syntax example (reference only):
-- CREATE TABLE enrollments (
--     student_id INT,
--     course_id  INT,
--     PRIMARY KEY (student_id, course_id)
-- );


-- =============================================================================
-- 3. SQL QUERY FINE TUNING TECHNIQUES
-- =============================================================================
-- Query fine tuning = writing SQL in ways that save computation,
-- reduce scan time, save memory, and use indexes effectively.
-- These are best practices to follow in every query you write.

-- ─────────────────────────────────────────────────────────────
-- Technique 1: Use EXPLAIN to analyse query execution plan
-- ─────────────────────────────────────────────────────────────
-- EXPLAIN shows how MySQL plans to run a query before executing it.
-- Key columns: type (ALL=bad, ref/const=good), key (which index used), rows (rows scanned).
-- If key is NULL and type is ALL -> no index used -> consider adding an index.

EXPLAIN SELECT customer_id, first_name, last_name
FROM customer
WHERE last_name = 'SMITH';

-- ─────────────────────────────────────────────────────────────
-- Technique 2: Avoid SELECT * -- select only needed columns
-- ─────────────────────────────────────────────────────────────
-- SELECT * fetches every column even if you only need two.
-- More data read + transferred = more memory, more time, more cost.

-- Bad practice
SELECT * FROM customer;

-- Better practice -- only what you need
SELECT customer_id, first_name, last_name, email
FROM customer;

-- ─────────────────────────────────────────────────────────────
-- Technique 3: Use WHERE to filter early before GROUP BY
-- ─────────────────────────────────────────────────────────────
-- WHERE filters individual rows BEFORE grouping.
-- Fewer rows going into GROUP BY = less computation = faster.
-- No point grouping inactive customers if you only want active ones.

-- Less efficient: groups everything first
SELECT store_id, COUNT(*) AS active_count
FROM customer
GROUP BY store_id
HAVING COUNT(*) > 200;

-- Better: WHERE filters first, GROUP BY processes fewer rows
SELECT store_id, COUNT(*) AS active_count
FROM customer
WHERE active = 1
GROUP BY store_id
HAVING COUNT(*) > 200;

-- ─────────────────────────────────────────────────────────────
-- Technique 4: Create index on frequently filtered columns
-- ─────────────────────────────────────────────────────────────
-- If you search payment by amount often, put an index on it.

CREATE INDEX idx_payment_amount ON payment(amount);

SELECT payment_id, customer_id, amount
FROM payment
WHERE amount > 8;
-- Now MySQL uses the index instead of scanning all payment rows.

-- ─────────────────────────────────────────────────────────────
-- Technique 5: Avoid functions on indexed columns in WHERE
-- ─────────────────────────────────────────────────────────────
-- Applying a function to an indexed column prevents index usage.
-- MySQL applies the function to every row first. Defeats the index.

-- Bad: DATE() on payment_date prevents index usage -> type = ALL
SELECT payment_id, payment_date, amount
FROM payment
WHERE DATE(payment_date) = '2005-05-25';

-- Better: use range directly on the column -> index can be used -> type = range
SELECT payment_id, payment_date, amount
FROM payment
WHERE payment_date >= '2005-05-25'
  AND payment_date <  '2005-05-26';

-- Same rule for YEAR():
-- Bad:  WHERE YEAR(rental_date) = 2005      -- scans all rows, applies YEAR() to each
-- Good: WHERE rental_date BETWEEN '2005-01-01' AND '2005-12-31'   -- uses index directly

-- ─────────────────────────────────────────────────────────────
-- Technique 6: Use JOIN instead of subqueries where possible
-- ─────────────────────────────────────────────────────────────
-- Subquery execution steps: inner query runs -> result passed to outer query
-- -> outer query filters. Around 6 logical steps total.
-- JOIN execution steps: tables joined + filter applied together. Around 3 steps.
-- JOIN also allows the optimizer to use indexes more effectively.

-- Less efficient: subquery style
SELECT customer_id, first_name, last_name
FROM customer
WHERE customer_id IN (
    SELECT customer_id
    FROM payment
    WHERE amount > 10
);

-- Better: JOIN style -- fewer steps, better optimizer decisions
SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
WHERE p.amount > 10;

-- ─────────────────────────────────────────────────────────────
-- Technique 7: Use LIMIT when testing or previewing data
-- ─────────────────────────────────────────────────────────────
-- Never query all rows just to check what a table looks like.
-- Top 10 rows tells you the structure just as well. Much cheaper.

SELECT rental_id, rental_date, customer_id
FROM rental
LIMIT 10;

SELECT * FROM sakila.film ORDER BY film_id LIMIT 100;

-- ─────────────────────────────────────────────────────────────
-- Technique 8: Index columns used in JOIN (foreign key columns)
-- ─────────────────────────────────────────────────────────────
-- Primary keys are indexed automatically (clustered).
-- Foreign key columns should also be indexed for fast joins.

SELECT f.film_id, f.title, i.inventory_id
FROM film f
JOIN inventory i ON f.film_id = i.film_id;
-- film_id in inventory is a foreign key -- should be indexed for fast joins.

-- ─────────────────────────────────────────────────────────────
-- Technique 9: Use composite index for multiple column filters
-- ─────────────────────────────────────────────────────────────
-- If you always filter by customer_id AND amount together,
-- a composite index on both columns is more efficient.

CREATE INDEX idx_payment_customer_amount ON payment(customer_id, amount);

SELECT payment_id, customer_id, amount
FROM payment
WHERE customer_id = 10
  AND amount > 5;

-- ─────────────────────────────────────────────────────────────
-- Technique 10: Be careful with OR -- consider UNION instead
-- ─────────────────────────────────────────────────────────────
-- OR can prevent MySQL from using indexes efficiently.
-- UNION allows each part to use its own index separately.

-- Less efficient (OR may cause full scan)
SELECT customer_id, first_name, last_name
FROM customer
WHERE first_name = 'MARY'
   OR last_name  = 'SMITH';

-- Sometimes better -- each part uses its own index
SELECT customer_id, first_name, last_name FROM customer WHERE first_name = 'MARY'
UNION
SELECT customer_id, first_name, last_name FROM customer WHERE last_name  = 'SMITH';

-- ─────────────────────────────────────────────────────────────
-- Technique 11: Use EXISTS for checking if a row exists
-- ─────────────────────────────────────────────────────────────
-- EXISTS stops as soon as it finds ONE matching row.
-- More efficient than IN when you only need to know if something exists.
-- SELECT 1 inside EXISTS means: just check if a row exists, return no data.

SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
WHERE EXISTS (
    SELECT 1
    FROM payment p
    WHERE p.customer_id = c.customer_id
);
-- Returns customers who have made at least one payment.
-- Stops after first match per customer. Faster than IN for large datasets.

-- ─────────────────────────────────────────────────────────────
-- Technique 12: Avoid unnecessary DISTINCT
-- ─────────────────────────────────────────────────────────────
-- DISTINCT adds extra deduplication work internally.
-- Only use it when you genuinely have duplicates to remove.

-- Avoid if duplicates are not a problem
SELECT DISTINCT first_name, last_name FROM customer;

-- Better when data is already unique in context
SELECT first_name, last_name FROM customer;

-- ─────────────────────────────────────────────────────────────
-- Technique 13: Use GROUP BY with JOIN for readable output
-- ─────────────────────────────────────────────────────────────
-- Joining with customer adds name column alongside aggregate results.
-- customer_id is indexed in both tables so the JOIN is fast.

SELECT c.customer_id, c.first_name, c.last_name,
       SUM(p.amount) AS total_amount
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

-- ─────────────────────────────────────────────────────────────
-- Technique 14: Filter before GROUP BY using WHERE
-- ─────────────────────────────────────────────────────────────
-- WHERE filters rows BEFORE GROUP BY. HAVING filters groups AFTER GROUP BY.
-- Use WHERE first to reduce the number of rows going into GROUP BY.

-- Less efficient: groups all payments then HAVING filters groups
SELECT customer_id, SUM(amount) AS total_amount
FROM payment
GROUP BY customer_id
HAVING SUM(amount) > 100;

-- Better: WHERE pre-filters rows, then GROUP BY processes fewer rows, then HAVING
SELECT customer_id, SUM(amount) AS total_amount
FROM payment
WHERE amount > 5
GROUP BY customer_id
HAVING SUM(amount) > 100;

-- ─────────────────────────────────────────────────────────────
-- Technique 15: Avoid leading wildcard in LIKE
-- ─────────────────────────────────────────────────────────────
-- LIKE '%ACADEMY%' has % at the start -> MySQL cannot use an index.
-- MySQL does not know where the pattern starts -> full table scan.
-- LIKE 'ACADEMY%' has no leading % -> MySQL uses index to jump directly.

-- Bad for index usage (leading %)
SELECT film_id, title FROM film WHERE title LIKE '%ACADEMY%';

-- Better (no leading %) -- index can be used
SELECT film_id, title FROM film WHERE title LIKE 'ACADEMY%';

-- ─────────────────────────────────────────────────────────────
-- Technique 16: Use proper data types for each column
-- ─────────────────────────────────────────────────────────────
-- Storing wrong types wastes space and prevents index use.
-- amount    -> DECIMAL    (not VARCHAR)
-- dates     -> DATE or DATETIME (not VARCHAR)
-- IDs       -> INT        (not VARCHAR)
-- names     -> VARCHAR with a reasonable length limit

-- ─────────────────────────────────────────────────────────────
-- Technique 17: Avoid sorting huge data without LIMIT
-- ─────────────────────────────────────────────────────────────
-- ORDER BY on a large table without LIMIT sorts millions of rows unnecessarily.
-- Always pair ORDER BY with LIMIT unless you truly need all sorted rows.
-- If the sort column is indexed, performance improves even more.

-- Unnecessary (sorts all rentals)
SELECT rental_id, rental_date, customer_id FROM rental ORDER BY rental_date;

-- Better
SELECT rental_id, rental_date, customer_id FROM rental ORDER BY rental_date LIMIT 20;

-- Create index on sort column for further improvement
CREATE INDEX idx_rental_date ON rental(rental_date);

-- ─────────────────────────────────────────────────────────────
-- Technique 18: Use covering index
-- ─────────────────────────────────────────────────────────────
-- A covering index contains ALL the columns the query needs.
-- MySQL answers the query entirely from the index without touching the table.
-- This is the fastest possible query pattern -- no table access at all.

CREATE INDEX idx_customer_name_email ON customer(last_name, first_name, email);

SELECT first_name, email
FROM customer
WHERE last_name = 'SMITH';
-- MySQL gets last_name, first_name and email all from the index. No table read.

-- ─────────────────────────────────────────────────────────────
-- Technique 19: Avoid too many indexes
-- ─────────────────────────────────────────────────────────────
-- Indexes speed up SELECT but SLOW DOWN INSERT, UPDATE, DELETE.
-- Every write operation must also update all indexes on that table.
-- Create indexes only where they make a real difference.
--
-- Good columns for indexes: WHERE columns, JOIN columns, ORDER BY columns,
--                            GROUP BY columns, foreign key columns.
-- Bad columns for indexes:  columns rarely used in filters,
--                            boolean/flag columns (Y/N), very small tables.

-- ─────────────────────────────────────────────────────────────
-- Technique 20: Check existing indexes before creating new ones
-- ─────────────────────────────────────────────────────────────
-- Before creating a new index check if one already exists.
-- Duplicate indexes waste memory and slow down write operations.

SHOW INDEX FROM customer;
SHOW INDEX FROM rental;
SHOW INDEX FROM payment;
SHOW INDEX FROM film;


-- =============================================================================
-- 4. SCOPE LADDER -- COMPLETE EVOLUTION SUMMARY
-- =============================================================================
-- Subquery   -> scope = query execution only. Gone after one query.
-- CTE        -> scope = query execution. Readable + reusable within same query.
-- Temp Table -> scope = session level. Reusable across multiple queries same session.
-- View       -> scope = global / database level. Permanent. Anyone can access.
-- Each one was created to solve the limitation of the previous.
-- Subquery -> CTE -> Temp Table -> View



