-- =============================================================================
-- LECTURE 04 - CARDINALITY + JOINS + CTE (Common Table Expressions)
-- Course  : Data Science & SQL Bootcamp
-- Date    : 22-24 May 2026
-- Topics  : Cardinality (table relationships), ALL join types, CTE, Recursive CTE,
--           ANY vs ALL operators, Subquery evolution, What comes next (Temp Tables/Views)
-- Database: sakila (and inline demo tables for cardinality examples)
-- Note    : This session also covered recap of subqueries (ANY/ALL/derived tables)
--           from students sharing screens, then moved into new topics.
-- =============================================================================

USE sakila;


-- =============================================================================
-- 1. SUBQUERY RECAP - ANY vs ALL (student recap from previous class)
-- =============================================================================
-- ANY and ALL are operators used with subqueries to compare a value
-- against a SET of values returned by an inner query.

-- ANY
--   Condition is TRUE if it holds for AT LEAST ONE value in the subquery result.
--   Think: "Is this value greater than any one of these?" -> even beating the minimum satisfies it.
--   Example: salary > ANY (60000, 75000, 90000)
--   -> salary just needs to be > 60000 (the smallest) to qualify.
--   Any single match is enough. More relaxed condition.

-- ALL
--   Condition is TRUE only if it holds for EVERY value in the subquery result.
--   Think: "Is this value greater than all of these?" -> must beat the maximum.
--   Example: salary > ALL (60000, 75000, 90000)
--   -> salary must be > 90000 (the largest) to qualify.
--   Must pass the toughest test. Much stricter condition.

-- Example using sakila payment amounts:
-- Find payments greater than ANY amount paid by customer 1
SELECT payment_id, customer_id, amount
FROM sakila.payment
WHERE amount > ANY (
    SELECT amount FROM sakila.payment WHERE customer_id = 1
);

-- Find payments greater than ALL amounts paid by customer 1
-- (must be greater than their highest payment)
SELECT payment_id, customer_id, amount
FROM sakila.payment
WHERE amount > ALL (
    SELECT amount FROM sakila.payment WHERE customer_id = 1
);

-- Key difference recap:
-- ANY  -> beats at least ONE value in the subquery set  (easier to satisfy)
-- ALL  -> beats EVERY value in the subquery set         (harder to satisfy, only largest values pass)


-- =============================================================================
-- 2. CARDINALITY - TABLE RELATIONSHIPS
-- =============================================================================
-- Cardinality = how many rows of one table relate to rows of another table.
-- Defined by the primary key and foreign key relationships between tables.
-- Understanding cardinality helps you:
--   - Design a proper normalized database
--   - Avoid data redundancy
--   - Understand how tables connect
--   - Write the CORRECT JOIN query for your use case
--
-- There are 4 types of cardinality relationships:

-- ─────────────────────────────────────────────────────────────
-- 2.1 ONE-TO-ONE (1:1)
-- ─────────────────────────────────────────────────────────────
-- One record in Table A matches with EXACTLY ONE record in Table B.
-- The foreign key in the second table is also UNIQUE.
--
-- Real example from class: user table <-> user_profile table
--   - User 1 (Alice) has exactly one profile: active
--   - User 2 (Bob)   has exactly one profile: inactive
--   - One user = one profile. No user can have two profiles.
--
-- Sakila example: customer <-> address
--   Each customer has one address, each address belongs to one customer.
--
-- When you JOIN these: you get exactly 1 matching row per row. Clean 1:1 result.

-- ─────────────────────────────────────────────────────────────
-- 2.2 ONE-TO-MANY (1:M)
-- ─────────────────────────────────────────────────────────────
-- One record in Table A matches with MULTIPLE records in Table B.
-- The foreign key in Table B is NOT unique (can repeat).
--
-- Real example: user table <-> orders table
--   - Alice placed 1 order
--   - Bob placed 2 orders (order IDs 102 and 103)
--   - One user -> many orders. User ID repeats in orders table.
--
-- Sakila example: customer <-> rental
--   One customer can rent many films. customer_id repeats in rental table.
--   One customer can have many payments. customer_id repeats in payment table.
--
-- When you JOIN: the left table row (customer) appears MULTIPLE TIMES,
--               once per matching row in the right table (rental).

-- ─────────────────────────────────────────────────────────────
-- 2.3 MANY-TO-ONE (M:1)
-- ─────────────────────────────────────────────────────────────
-- This is just the REVERSE VIEW of 1:M.
-- Many records in Table A connect to ONE record in Table B.
--
-- Example: many orders placed BY one user.
--   Orders table has many rows with the same user_id (Bob's orders).
--   They all point back to ONE row in the user table (Bob).
--
-- 1:M and M:1 describe the same relationship, just from opposite ends.
-- Which table is "left" and which is "right" determines which label you use.

-- ─────────────────────────────────────────────────────────────
-- 2.4 MANY-TO-MANY (M:M)
-- ─────────────────────────────────────────────────────────────
-- Many records in Table A connect to many records in Table B.
-- Requires a BRIDGE TABLE (junction/associative table) to implement.
--
-- Real example: friendship table (user <-> user)
--   Alice is friends with Bob. Bob is friends with Alice and Charlie.
--   One user has many friends. Each friend is also a user.
--   The same user table is joined with itself via the friendship bridge table.
--   -> This is BOTH many-to-many AND self-join.
--
-- Sakila example: film <-> actor (via film_actor bridge table)
--   One film has many actors. One actor works in many films.
--   film_actor is the bridge table holding (film_id, actor_id) pairs.

-- Summary:
--   Relationship  | Example                          | FK unique?
--   1:1           | customer -> address              | Yes (unique FK)
--   1:M           | customer -> rental               | No  (FK repeats)
--   M:1           | rental -> customer               | Same as 1:M reversed
--   M:M           | film <-> actor (via film_actor)  | Bridge table needed


-- =============================================================================
-- 3. JOINS
-- =============================================================================
-- JOINs combine rows from two or more tables based on a related column.
-- Usually: PRIMARY KEY from one table joins FOREIGN KEY from another.
-- Which JOIN you use depends on the cardinality and what data you need.
--
-- Why JOINs over subqueries?
--   Subqueries are costly and scoped to query level.
--   JOINs are generally faster and can combine full rows across tables.
--   Use subqueries when you only need ONE column from another table.
--   Use JOINs when you need MULTIPLE columns from another table.

-- ─────────────────────────────────────────────────────────────
-- 3.1 INNER JOIN - only matching rows from both tables
-- ─────────────────────────────────────────────────────────────
-- Returns ONLY rows where the key exists in BOTH tables.
-- Non-matching rows from either table are excluded entirely.
-- The intersection of both tables.
-- Syntax: SELECT ... FROM A INNER JOIN B ON A.key = B.key

-- Customers who have actually rented movies
SELECT c.customer_id, c.first_name, r.rental_id
FROM sakila.customer c
INNER JOIN sakila.rental r
ON c.customer_id = r.customer_id;
-- Only customers with rentals appear. Customers with no rentals are excluded.

-- Film titles with their language name
SELECT f.title, l.name AS language_name
FROM sakila.film f
INNER JOIN sakila.language l
ON f.language_id = l.language_id;

-- ─────────────────────────────────────────────────────────────
-- 3.2 LEFT JOIN - ALL rows from left table + matching from right
-- ─────────────────────────────────────────────────────────────
-- Returns EVERY row from the LEFT table.
-- For matching rows in the right table: shows the data.
-- For non-matching rows (right has no match): shows NULL.
-- Think: "Keep everything on the left, fill in right where possible."

-- All customers, even those with no rentals
SELECT c.customer_id, c.first_name, r.rental_id
FROM sakila.customer c
LEFT JOIN sakila.rental r
ON c.customer_id = r.customer_id;
-- All customers appear. Customers with no rentals: rental_id = NULL.

-- All actors and their films (even actors not in any film)
SELECT a.actor_id, a.first_name, f.title
FROM sakila.actor a
LEFT JOIN sakila.film_actor fa ON a.actor_id = fa.actor_id
LEFT JOIN sakila.film f        ON fa.film_id = f.film_id;

-- ─────────────────────────────────────────────────────────────
-- 3.3 LEFT JOIN EXCLUDING INNER JOIN - only LEFT unmatched rows
-- ─────────────────────────────────────────────────────────────
-- Shows rows from the LEFT table that have NO match in the right table.
-- Add WHERE right_table.key IS NULL after the LEFT JOIN.
-- Use case: find things in A that don't exist in B.

-- Find customers who have NEVER rented anything
SELECT c.customer_id, c.first_name
FROM sakila.customer c
LEFT JOIN sakila.rental r ON c.customer_id = r.customer_id
WHERE r.rental_id IS NULL;

-- Films that have NO inventory copies
SELECT f.film_id, f.title, i.inventory_id
FROM sakila.film f
LEFT JOIN sakila.inventory i ON f.film_id = i.film_id
WHERE i.inventory_id IS NULL;

-- IMPORTANT: wrong vs right usage
-- WRONG - this WHERE turns LEFT JOIN into INNER JOIN behaviour:
-- SELECT * FROM customer c LEFT JOIN rental r ON c.customer_id = r.customer_id WHERE r.customer_id = 1;
-- Adding a WHERE on the right table column filters out NULLs (defeats the LEFT JOIN purpose).
-- CORRECT: use WHERE right_table.key IS NULL to get unmatched rows only.

-- ─────────────────────────────────────────────────────────────
-- 3.4 RIGHT JOIN - ALL rows from right table + matching from left
-- ─────────────────────────────────────────────────────────────
-- Mirror of LEFT JOIN. Returns EVERY row from the RIGHT table.
-- Matching rows from left: shows data. Non-matching: NULL.
-- Less common - you can usually rewrite as LEFT JOIN by swapping table order.

-- All rentals, even if customer data is missing
SELECT c.first_name, r.rental_id
FROM sakila.customer c
RIGHT JOIN sakila.rental r
ON c.customer_id = r.customer_id;

-- ─────────────────────────────────────────────────────────────
-- 3.5 RIGHT JOIN EXCLUDING INNER JOIN - only RIGHT unmatched rows
-- ─────────────────────────────────────────────────────────────
-- Rows in the RIGHT table that have no match in the LEFT table.
-- Add WHERE left_table.key IS NULL after RIGHT JOIN.

-- Inventory records that have no matching film (orphaned inventory)
SELECT f.film_id, f.title, i.inventory_id
FROM sakila.film f
RIGHT JOIN sakila.inventory i ON f.film_id = i.film_id
WHERE f.film_id IS NULL;
-- Usually returns empty in sakila (proper foreign keys prevent this).

-- ─────────────────────────────────────────────────────────────
-- 3.6 FULL OUTER JOIN - everything from both tables
-- ─────────────────────────────────────────────────────────────
-- Returns: matched rows + unmatched left rows + unmatched right rows.
-- ALL records from BOTH tables regardless of matching.
-- MySQL does NOT support FULL OUTER JOIN directly.
-- Simulate it with: LEFT JOIN UNION RIGHT JOIN

SELECT c.customer_id, r.rental_id
FROM sakila.customer c
LEFT JOIN sakila.rental r ON c.customer_id = r.customer_id
UNION
SELECT c.customer_id, r.rental_id
FROM sakila.customer c
RIGHT JOIN sakila.rental r ON c.customer_id = r.customer_id;
-- UNION removes duplicate rows automatically.
-- LEFT JOIN alone misses: rentals with no customer.
-- RIGHT JOIN alone misses: customers with no rental.
-- UNION of both = complete picture.

-- This will FAIL in MySQL (not supported):
-- SELECT * FROM customer c FULL JOIN rental r ON c.customer_id = r.customer_id;

-- ─────────────────────────────────────────────────────────────
-- 3.7 FULL OUTER JOIN EXCLUDING INNER JOIN - only unmatched from both
-- ─────────────────────────────────────────────────────────────
-- Shows only rows that do NOT have a match in the other table.
-- Excludes the matched/common rows entirely.
-- Simulate: LEFT EXCLUDING INNER UNION RIGHT EXCLUDING INNER

SELECT f.film_id, f.title, i.inventory_id
FROM sakila.film f
LEFT JOIN sakila.inventory i ON f.film_id = i.film_id
WHERE i.inventory_id IS NULL           -- films with no inventory
UNION
SELECT f.film_id, f.title, i.inventory_id
FROM sakila.film f
RIGHT JOIN sakila.inventory i ON f.film_id = i.film_id
WHERE f.film_id IS NULL;               -- inventory with no film

-- ─────────────────────────────────────────────────────────────
-- 3.8 CROSS JOIN - every possible combination (Cartesian product)
-- ─────────────────────────────────────────────────────────────
-- No ON condition. Every row from Table A is combined with every row from Table B.
-- Result rows = count(A) × count(B)
-- Example: 6 users × 7 orders = 42 rows
-- Use carefully - can create massive outputs.

-- Every customer combined with every store (all possible customer-store pairs)
SELECT c.first_name, s.store_id
FROM sakila.customer c
CROSS JOIN sakila.store s;
-- 599 customers × 2 stores = 1198 rows

-- ─────────────────────────────────────────────────────────────
-- 3.9 SELF JOIN - joining a table with itself
-- ─────────────────────────────────────────────────────────────
-- The same table is used twice with different aliases.
-- Used when a table has a relationship with itself.
-- Common use cases:
--   - Employee <-> Manager (managers are also employees)
--   - User <-> Friend (friends are also users) - the friendship bridge table example
--
-- MUST use aliases so SQL knows which copy of the table you're referring to.

-- Find pairs of customers who belong to the same store
SELECT c1.customer_id AS customer_1_id,
       c1.first_name  AS customer_1_name,
       c2.customer_id AS customer_2_id,
       c2.first_name  AS customer_2_name,
       c1.store_id
FROM sakila.customer c1
INNER JOIN sakila.customer c2
ON c1.store_id = c2.store_id
WHERE c1.customer_id <> c2.customer_id;  -- exclude matching with itself
-- c1 and c2 are both the customer table - two copies joined on the same store_id.

-- COMPLETE JOIN REFERENCE:
-- Join Type                        | What it returns
-- --------------------------------|------------------------------------------------
-- INNER JOIN                       | Only matching rows from both tables
-- LEFT JOIN                        | All left rows + matching right rows (NULLs for no match)
-- RIGHT JOIN                       | All right rows + matching left rows (NULLs for no match)
-- FULL OUTER JOIN (via UNION)      | Everything from both tables
-- LEFT EXCLUDING INNER             | Only left-side unmatched rows (WHERE right IS NULL)
-- RIGHT EXCLUDING INNER            | Only right-side unmatched rows (WHERE left IS NULL)
-- FULL EXCLUDING INNER (via UNION) | Only unmatched rows from both sides
-- CROSS JOIN                       | Every possible combination (count A × count B)
-- SELF JOIN                        | Table joined with itself using aliases


-- =============================================================================
-- 4. CTE - COMMON TABLE EXPRESSION
-- =============================================================================
-- WHY CTE was created:
-- As subquery complexity grows, you end up nesting multiple subqueries
-- inside one giant query. This becomes unreadable and hard to debug.
-- Example: a query with 3 nested subqueries is nearly impossible to follow.
--
-- CTE solves this by letting you:
--   1. Break subqueries into named, separate blocks (WITH clause)
--   2. Reference those named blocks by name in the main query
--   3. Reuse the same CTE multiple times in the same query
--
-- CTE ADVANTAGES over subqueries:
--   1. Readability    - complex logic is broken into clear named steps
--   2. Reusability    - one CTE can be referenced multiple times in the same query
--   3. Maintainability - easier to debug and modify each step independently
--
-- CTE DISADVANTAGE (same as subquery):
--   Scope is still at QUERY EXECUTION LEVEL only.
--   The CTE does NOT physically exist in the database.
--   You MUST always run the WITH block and the main SELECT together.
--   If you try to run only the SELECT (without the WITH block), it errors:
--   -> "No database selected" or "Table doesn't exist"
--   The CTE only exists for the duration of that single query execution.

-- ─────────────────────────────────────────────────────────────
-- 4.1 Basic CTE Syntax
-- ─────────────────────────────────────────────────────────────
-- WITH cte_name AS (
--     -- inner query (what used to be a subquery)
--     SELECT col1, col2 FROM table_name
-- )
-- -- main query uses the CTE by name, like a real table
-- SELECT * FROM cte_name;

-- ─────────────────────────────────────────────────────────────
-- 4.2 Simple CTE - total payment per customer
-- ─────────────────────────────────────────────────────────────
-- This is the same as a derived table subquery, but named and separated.
WITH customer_total_payment AS (
    SELECT customer_id,
           SUM(amount) AS total_amount
    FROM sakila.payment
    GROUP BY customer_id
)
SELECT customer_id, total_amount
FROM customer_total_payment
ORDER BY total_amount DESC
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 4.3 CTE joined with another table - film count per category
-- ─────────────────────────────────────────────────────────────
-- CTE computes something, then the main query joins it with another table.
WITH category_film_count AS (
    SELECT category_id,
           COUNT(film_id) AS total_films
    FROM sakila.film_category
    GROUP BY category_id
)
SELECT c.category_id,
       c.name AS category_name,
       cfc.total_films
FROM sakila.category c
INNER JOIN category_film_count cfc ON c.category_id = cfc.category_id
ORDER BY cfc.total_films DESC;
-- film_category is the bridge table connecting category and film.
-- CTE counts films per category. Main query gets the category name by joining.

-- ─────────────────────────────────────────────────────────────
-- 4.4 Multiple CTEs - customer payment total + rental count together
-- ─────────────────────────────────────────────────────────────
-- Multiple CTEs are comma-separated after the first WITH.
-- No need to write WITH again for the second CTE.
-- Both CTEs are available in the main query.
WITH customer_payment_total AS (
    -- First CTE: total amount paid by each customer
    SELECT customer_id,
           SUM(amount) AS total_paid
    FROM sakila.payment
    GROUP BY customer_id
),
customer_rental_total AS (
    -- Second CTE: total rentals by each customer (comma-separated, no second WITH)
    SELECT customer_id,
           COUNT(rental_id) AS total_rentals
    FROM sakila.rental
    GROUP BY customer_id
)
-- Main query joins both CTEs with the customer table
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       cpt.total_paid,
       crt.total_rentals
FROM sakila.customer c
INNER JOIN customer_payment_total cpt ON c.customer_id = cpt.customer_id
INNER JOIN customer_rental_total  crt ON c.customer_id = crt.customer_id
ORDER BY cpt.total_paid DESC;
-- Two CTEs, one main query, three tables combined cleanly.
-- Compare this to doing it all with nested subqueries - much more readable.

-- ─────────────────────────────────────────────────────────────
-- 4.5 CTE vs Subquery - same result, different readability
-- ─────────────────────────────────────────────────────────────
-- SUBQUERY version (harder to read when complex):
-- SELECT customer_id, total_amount
-- FROM (
--     SELECT customer_id, SUM(amount) AS total_amount
--     FROM payment GROUP BY customer_id
-- ) AS customer_totals
-- WHERE total_amount > 100;

-- CTE version (same logic, much cleaner):
WITH customer_totals AS (
    SELECT customer_id, SUM(amount) AS total_amount
    FROM sakila.payment
    GROUP BY customer_id
)
SELECT customer_id, total_amount
FROM customer_totals
WHERE total_amount > 100;

-- CODE REUSABILITY example: use the same CTE twice in one query
WITH high_value_customers AS (
    SELECT customer_id, SUM(amount) AS total_paid
    FROM sakila.payment
    GROUP BY customer_id
    HAVING SUM(amount) > 150
)
SELECT c.customer_id, c.first_name, hvc.total_paid
FROM sakila.customer c
INNER JOIN high_value_customers hvc ON c.customer_id = hvc.customer_id
ORDER BY hvc.total_paid DESC;
-- With subqueries, you'd have to write the same subquery twice if needed in two places.
-- With CTE, you write it once and reference the name.


-- =============================================================================
-- 5. RECURSIVE CTE
-- =============================================================================
-- A recursive CTE calls itself repeatedly until a stop condition is met.
-- Similar to a loop or recursive function in Python/Java.
-- Used when you need to generate sequences or traverse hierarchical data.
--
-- Structure:
--   WITH RECURSIVE cte_name AS (
--       -- ANCHOR MEMBER: starting point (runs ONCE)
--       SELECT starting_value
--       UNION ALL
--       -- RECURSIVE MEMBER: repeats, calls itself
--       SELECT next_value FROM cte_name
--       WHERE stop_condition          -- CRITICAL: prevents infinite loop
--   )
--   SELECT * FROM cte_name;
--
-- How it works:
--   1. Anchor runs first -> produces first row(s)
--   2. Recursive member runs using the previous result
--   3. Keeps repeating until stop_condition is FALSE
--   4. All results accumulated via UNION ALL

-- ─────────────────────────────────────────────────────────────
-- 5.1 Generate first 20 natural numbers (1 to 20)
-- ─────────────────────────────────────────────────────────────
WITH RECURSIVE numbers AS (
    -- Anchor: start at 1
    SELECT 1 AS n
    UNION ALL
    -- Recursive: add 1 each time, stop when n reaches 20
    SELECT n + 1
    FROM numbers
    WHERE n < 20     -- stop condition: when n = 20, this becomes FALSE and recursion stops
)
SELECT n FROM numbers;
-- Execution trace:
-- Step 1 (anchor):     n=1
-- Step 2 (recursive):  n=2 (1+1, WHERE 1<20 is TRUE)
-- Step 3 (recursive):  n=3 (2+1, WHERE 2<20 is TRUE)
-- ...
-- Step 20 (recursive): n=20 (19+1, WHERE 19<20 is TRUE)
-- Step 21:             WHERE 20<20 is FALSE -> STOP
-- The CTE calls itself: "FROM numbers" inside numbers = calling itself = recursive.

-- ─────────────────────────────────────────────────────────────
-- 5.2 Generate a sequence of dates and count daily rentals
-- ─────────────────────────────────────────────────────────────
-- Goal: go back 10 days from the latest rental date and
--       count how many rentals happened on each of those days.
-- sakila rental data is from 2005-2006. Most activity on Feb 14, 2006.
WITH RECURSIVE date_series AS (
    -- Anchor: start from (max_date - 9 days) = 10 days ago
    SELECT DATE(MAX(rental_date)) - INTERVAL 9 DAY AS rental_day
    FROM sakila.rental
    UNION ALL
    -- Recursive: add 1 day each time, stop at max date
    SELECT DATE_ADD(rental_day, INTERVAL 1 DAY)
    FROM date_series
    WHERE rental_day < (SELECT DATE(MAX(rental_date)) FROM sakila.rental)
),
daily_rentals AS (
    -- Count rentals per day from the actual rental table
    SELECT DATE(rental_date) AS rental_day,
           COUNT(rental_id)  AS total_rentals
    FROM sakila.rental
    GROUP BY DATE(rental_date)
)
-- Join generated date series with actual rental counts
-- COALESCE replaces NULL with 0 for days with no rentals
SELECT ds.rental_day,
       COALESCE(dr.total_rentals, 0) AS total_rentals
FROM date_series ds
LEFT JOIN daily_rentals dr ON ds.rental_day = dr.rental_day
ORDER BY ds.rental_day;
-- Days with no rentals show 0 (not NULL) thanks to COALESCE.
-- Most activity was on Feb 14, 2006 -> 182 rentals on that day.

-- ─────────────────────────────────────────────────────────────
-- 5.3 Generate all dates between first and last payment (from friend's notes)
-- ─────────────────────────────────────────────────────────────
WITH RECURSIVE date_list AS (
    -- Anchor: start from the minimum payment date
    SELECT MIN(DATE(payment_date)) AS payment_day
    FROM sakila.payment
    UNION ALL
    -- Recursive: add 1 day each time until max date
    SELECT DATE_ADD(payment_day, INTERVAL 1 DAY)
    FROM date_list
    WHERE payment_day < (
        SELECT MAX(DATE(payment_date)) FROM sakila.payment
    )
),
daily_payments AS (
    -- Actual daily totals from payment table
    SELECT DATE(payment_date) AS payment_day,
           SUM(amount)        AS total_amount
    FROM sakila.payment
    GROUP BY DATE(payment_date)
)
-- Join all dates with payment data; show 0 for days with no payments
SELECT dl.payment_day,
       COALESCE(dp.total_amount, 0) AS total_amount
FROM date_list dl
LEFT JOIN daily_payments dp ON dl.payment_day = dp.payment_day
ORDER BY dl.payment_day;


-- =============================================================================
-- 6. EVOLUTION: SUBQUERY -> CTE -> TEMP TABLES / VIEWS
-- =============================================================================
-- The journey of how SQL handles temporary/reusable query results:
--
-- SUBQUERY
--   - Query inside a query
--   - Works but gets complex when nested multiple levels deep
--   - Drawbacks: hard to read, not reusable, scope = query level only
--
-- CTE (Common Table Expression)
--   - Solves: readability and code reusability
--   - Still has same scope limitation: query execution level only
--   - CTE must always be followed by its main SELECT in the same execution
--
-- TEMP TABLES (next session)
--   - Physically stored in session memory (not in the main database)
--   - Can be reused across multiple queries within the same SESSION
--   - Scope: session level (persists until you close the connection)
--   - Solves the scope limitation of CTE and subquery
--
-- VIEWS (next session)
--   - Stored permanently in the database as a named virtual table
--   - Can be reused across sessions and by multiple users
--   - Scope: database level (persists until you DROP it)
--   - Solves the scope limitation of ALL the above
--
-- Summary ladder:
--   Subquery -> CTE (better readability/reuse) ->
--   Temp Table (session-level storage) -> View (database-level storage)


-- =============================================================================
-- 7. NEXT SESSION - LECTURE 05
-- =============================================================================
-- Topics to be covered:
--   - Temporary Tables (CREATE TEMPORARY TABLE)
--   - Views (CREATE VIEW)
--   - Difference: Subquery vs CTE vs Temp Table vs View


