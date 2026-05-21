-- =============================================================================
-- LECTURE 03 - MATH FUNCTIONS + DATE/TIME FUNCTIONS + SUBQUERIES
-- Course  : Data Science & SQL Bootcamp
-- Date    : 21 May 2026
-- Topics  : Built-in Math Functions, Built-in Date/Time Functions,
--           Subqueries (WHERE / SELECT / Derived Table / Correlated),
--           Bridge Tables, When Subqueries Fail
-- Database: sakila
-- Note    : This class marks the TRANSITION from basics to advanced SQL.
--           Everything from DDL, DML, DQL, WHERE, GROUP BY, HAVING,
--           built-in functions, ORDER BY, LIMIT = BASICS (used in every query).
--           From subqueries onwards = ADVANCED topics.
-- =============================================================================

USE sakila;


-- =============================================================================
-- 1. BUILT-IN MATH FUNCTIONS
-- =============================================================================
-- SQL has built-in functions for mathematical operations.
-- You can either write custom arithmetic directly in your query
-- OR use these built-in functions. Both produce the same result.
-- These are all DQL operations - they DO NOT change the stored data.

-- ─────────────────────────────────────────────────────────────
-- 1.1 POWER() - raise a value to a power
-- ─────────────────────────────────────────────────────────────
-- Syntax: POWER(value, exponent)
-- Same as writing value * value (for power 2), but cleaner.

-- Square of rental_duration (same as rental_duration * rental_duration)
SELECT title, rental_duration,
       rental_duration * rental_duration      AS manual_square,
       POWER(rental_duration, 2)              AS power_square
FROM sakila.film
LIMIT 5;

-- ─────────────────────────────────────────────────────────────
-- 1.2 MOD() - modulus / remainder after division
-- ─────────────────────────────────────────────────────────────
-- Syntax: MOD(value, divisor)
-- Returns the REMAINDER when value is divided by divisor.
-- Example: MOD(86, 60) = 26 (86 divided by 60 leaves remainder 26)
-- Useful: convert total minutes to hours + leftover minutes

-- Find the leftover minutes after full hours for each film length
SELECT title, length,
       MOD(length, 60) AS leftover_minutes
FROM sakila.film
LIMIT 10;

-- Find payment IDs that are even numbers (remainder 0 when divided by 2)
SELECT payment_id, amount
FROM sakila.payment
WHERE MOD(payment_id, 2) = 0
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 1.3 CEIL() - ceiling: round UP to nearest integer
-- ─────────────────────────────────────────────────────────────
-- Always rounds to the UPPER value.
-- Example: CEIL(0.99) = 1, CEIL(2.99) = 3, CEIL(3.3) = 4
-- Use when you want to charge the next full unit (e.g., billing)

SELECT payment_id, amount,
       CEIL(amount) AS rounded_up_amount
FROM sakila.payment
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 1.4 FLOOR() - floor: round DOWN to nearest integer
-- ─────────────────────────────────────────────────────────────
-- Always rounds to the LOWER value.
-- Example: FLOOR(0.99) = 0, FLOOR(2.99) = 2, FLOOR(3.3) = 3
-- Use when you want the conservative/lower estimate

SELECT payment_id, amount,
       FLOOR(amount) AS rounded_down_amount
FROM sakila.payment
LIMIT 10;

-- CEIL vs FLOOR comparison on rental_rate:
-- 0.99 -> CEIL = 1,  FLOOR = 0
-- 2.99 -> CEIL = 3,  FLOOR = 2
-- 4.99 -> CEIL = 5,  FLOOR = 4
-- Pick the right one based on your business rule.
SELECT rental_rate,
       CEIL(rental_rate)  AS ceil_value,
       FLOOR(rental_rate) AS floor_value
FROM sakila.film
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 1.5 ROUND() - round to specified decimal places
-- ─────────────────────────────────────────────────────────────
-- Syntax: ROUND(value, decimal_places)
-- ROUND(3.3, 0)  -> 3   (zero decimal places = whole number)
-- ROUND(3.56, 1) -> 3.6 (one decimal place)
-- ROUND(3.567, 2)-> 3.57 (two decimal places)
-- Standard rounding rules apply (>= .5 rounds up, < .5 rounds down)

SELECT film_id, title, replacement_cost,
       ROUND(replacement_cost, 0) AS rounded_to_integer,
       ROUND(replacement_cost, 1) AS rounded_1_decimal,
       ROUND(replacement_cost, 2) AS rounded_2_decimal
FROM sakila.film
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 1.6 RAND() - generate random numbers
-- ─────────────────────────────────────────────────────────────
-- RAND() returns a random decimal between 0 and 1 (e.g., 0.0037...)
-- Multiply by 100 to scale it to 0-100 range.
-- Use FLOOR(RAND() * 100) to get a whole random integer.
-- Every time you run the query, different random values appear.

SELECT customer_id,
       RAND()               AS raw_random,
       RAND() * 100         AS scaled_random,
       FLOOR(RAND() * 100)  AS random_integer_score
FROM sakila.customer
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 1.7 Aggregate Math Functions (recap - used with GROUP BY)
-- ─────────────────────────────────────────────────────────────
-- AVG()   - average value
-- SUM()   - total / sum
-- COUNT() - count of rows
-- MIN()   - smallest value
-- MAX()   - largest value

-- Average payment amount across all transactions
SELECT AVG(amount) AS average_payment FROM sakila.payment;

-- Lowest and highest replacement cost in film table
SELECT MIN(replacement_cost) AS lowest_cost,
       MAX(replacement_cost) AS highest_cost
FROM sakila.film;

-- Total transactions, total collected, and average per transaction
SELECT COUNT(*)      AS total_payments,
       SUM(amount)   AS total_amount_collected,
       AVG(amount)   AS average_amount
FROM sakila.payment;

-- Per-customer payment summary using GROUP BY + math functions
SELECT customer_id,
       COUNT(*)          AS total_payments,
       SUM(amount)       AS total_paid,
       ROUND(AVG(amount), 2) AS average_payment,
       MAX(amount)       AS highest_payment,
       MIN(amount)       AS lowest_payment
FROM sakila.payment
GROUP BY customer_id
LIMIT 10;

-- Top 10 customers who paid the highest total amount
SELECT customer_id, SUM(amount) AS total_paid
FROM sakila.payment
GROUP BY customer_id
ORDER BY total_paid DESC
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 1.8 Custom column using ALTER TABLE + UPDATE (demo from class)
-- ─────────────────────────────────────────────────────────────
-- To store a calculated value permanently in a new column:
-- Step 1: ALTER TABLE to add the new column
-- Step 2: SET SQL_SAFE_UPDATES = 0; to allow the update
-- Step 3: UPDATE with the calculated value

-- ALTER TABLE sakila.film ADD COLUMN rental_duration_double INT;
-- SET SQL_SAFE_UPDATES = 0;
-- UPDATE sakila.film
-- SET rental_duration_double = rental_duration * 2
-- WHERE length IS NOT NULL;
-- SET SQL_SAFE_UPDATES = 1;
-- (These are commented out to avoid modifying the shared sakila database)

-- Average payment per customer calculated manually (without AVG built-in)
SELECT customer_id,
       COUNT(payment_id)               AS total_payments,
       SUM(amount)                     AS total_amount,
       SUM(amount) / COUNT(payment_id) AS manual_average
FROM sakila.payment
GROUP BY customer_id
LIMIT 10;


-- =============================================================================
-- 2. BUILT-IN DATE AND TIME FUNCTIONS
-- =============================================================================
-- Date and time functions extract, format, calculate, or compare date values.
-- Very commonly used in real-world reports and analytics.

-- ─────────────────────────────────────────────────────────────
-- 2.1 NOW(), CURDATE(), CURRENT_TIME() - current date/time
-- ─────────────────────────────────────────────────────────────
-- NOW()          -> current date AND time (full timestamp): 2026-05-21 12:07:40
-- CURDATE()      -> current date only (no time):            2026-05-21
-- CURRENT_TIME() -> current time only (no date):            12:07:40
-- Choose based on your need - date only, time only, or both.

SELECT NOW()           AS current_timestamp,
       CURDATE()       AS current_date_only,
       CURRENT_TIME()  AS current_time_only;

-- Concatenate current date into a readable message using CONCAT + CURDATE
SELECT CONCAT('Today is: ', CURDATE())  AS date_message;
SELECT CONCAT('Now is: ', NOW())        AS full_timestamp_message;

-- ─────────────────────────────────────────────────────────────
-- 2.2 DATE() - extract just the date from a datetime/timestamp column
-- ─────────────────────────────────────────────────────────────
-- payment_date is stored as a timestamp (includes time).
-- DATE(payment_date) strips the time and returns the date only.
-- Use when you want to GROUP BY day, not by exact timestamp.

SELECT payment_id, payment_date,
       DATE(payment_date) AS only_date
FROM sakila.payment
LIMIT 10;

-- Group total payments by day (GROUP BY DATE not raw timestamp)
SELECT DATE(payment_date)  AS payment_day,
       COUNT(*)            AS total_payments,
       SUM(amount)         AS total_amount
FROM sakila.payment
GROUP BY DATE(payment_date)
ORDER BY payment_day;

-- ─────────────────────────────────────────────────────────────
-- 2.3 DATEDIFF() - difference in days between two dates
-- ─────────────────────────────────────────────────────────────
-- Syntax: DATEDIFF(end_date, start_date)
-- Returns number of days between the two dates.
-- Example: DATEDIFF('2026-05-26', '2026-05-21') = 5

-- How many days was each film rented for?
SELECT rental_id, rental_date, return_date,
       DATEDIFF(return_date, rental_date) AS rented_days
FROM sakila.rental
WHERE return_date IS NOT NULL
LIMIT 10;

-- Average rental duration across all completed rentals
SELECT AVG(DATEDIFF(return_date, rental_date)) AS average_rental_days
FROM sakila.rental
WHERE return_date IS NOT NULL;

-- ─────────────────────────────────────────────────────────────
-- 2.4 DATE_ADD() and DATE_SUB() - add or subtract time intervals
-- ─────────────────────────────────────────────────────────────
-- Syntax: DATE_ADD(date, INTERVAL n unit)
-- Syntax: DATE_SUB(date, INTERVAL n unit)
-- Units: DAY, MONTH, YEAR, HOUR, MINUTE, SECOND
-- DATE_ADD with negative interval = same as DATE_SUB

-- Add/subtract from the current date
SELECT NOW()                                       AS right_now,
       DATE_ADD(NOW(), INTERVAL 7 DAY)             AS plus_7_days,
       DATE_ADD(NOW(), INTERVAL 1 MONTH)           AS plus_1_month,
       DATE_ADD(NOW(), INTERVAL 1 YEAR)            AS plus_1_year,
       DATE_SUB(NOW(), INTERVAL 7 DAY)             AS minus_7_days,
       DATE_SUB(NOW(), INTERVAL 1 MONTH)           AS minus_1_month,
       NOW() - INTERVAL 1 DAY                      AS yesterday;

-- Add 7 days and subtract 7 days from each payment date
SELECT payment_id, payment_date,
       DATE_ADD(payment_date, INTERVAL 7 DAY)   AS plus_7,
       DATE_ADD(payment_date, INTERVAL -7 DAY)  AS minus_7
FROM sakila.payment
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 2.5 Extracting parts of a date: DAY, MONTH, YEAR, DAYOFWEEK etc.
-- ─────────────────────────────────────────────────────────────
-- DAY(date)        -> day number of the month (1-31)
-- MONTH(date)      -> month number (1-12)
-- YEAR(date)       -> 4-digit year
-- DAYOFWEEK(date)  -> 1=Sunday, 2=Monday ... 7=Saturday
-- DAYOFMONTH(date) -> same as DAY(), day of month (1-31)
-- DAYOFYEAR(date)  -> day of the year (1-365)
-- MONTHNAME(date)  -> full month name (January, February...)
-- WEEK(date)       -> which week number of the year (1-52)

SELECT last_update,
       DAY(last_update)        AS day_number,
       MONTH(last_update)      AS month_number,
       YEAR(last_update)       AS year_number,
       DAYOFWEEK(last_update)  AS day_of_week,   -- 1=Sunday, 7=Saturday
       MONTHNAME(last_update)  AS month_name,
       WEEK(last_update)       AS week_of_year
FROM sakila.film
LIMIT 10;
-- Example: 2006-02-15 -> DAYOFWEEK = 4 (Wednesday), MONTH = 2, YEAR = 2006

-- ─────────────────────────────────────────────────────────────
-- 2.6 DATE_FORMAT() - display dates in a custom format
-- ─────────────────────────────────────────────────────────────
-- Syntax: DATE_FORMAT(date, 'format_string')
-- Common format symbols:
--   %Y = 4-digit year  (2026)
--   %y = 2-digit year  (26)
--   %m = month number  (05)
--   %M = full month name (May)
--   %d = day number    (21)
--   %W = full weekday  (Thursday)
--   %H = hour (24h)    (14)
--   %i = minutes       (30)
--   %s = seconds       (00)

SELECT payment_id, payment_date,
       DATE_FORMAT(payment_date, '%Y-%m-%d')       AS fmt_yyyy_mm_dd,
       DATE_FORMAT(payment_date, '%d-%m-%Y')       AS fmt_dd_mm_yyyy,
       DATE_FORMAT(payment_date, '%M %d, %Y')      AS readable_date,
       DATE_FORMAT(payment_date, '%W')              AS weekday_name,
       DATE_FORMAT(payment_date, '%M')              AS month_name
FROM sakila.payment
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 2.7 Filtering by date using subquery + MAX
-- ─────────────────────────────────────────────────────────────
-- The sakila payment data goes up to 2006 (not current year).
-- So NOW() - INTERVAL 10 DAY returns no results (no 2026 data).
-- Instead: find MAX date in the table and go back 10 days from that.
-- This pattern is commonly used when working with historical datasets.

SELECT *
FROM sakila.payment
WHERE payment_date >= (
    SELECT MAX(payment_date) - INTERVAL 10 DAY
    FROM sakila.payment
);

-- ─────────────────────────────────────────────────────────────
-- 2.8 Latest payment by each customer
-- ─────────────────────────────────────────────────────────────
SELECT customer_id,
       MAX(payment_date) AS latest_payment_date
FROM sakila.payment
GROUP BY customer_id
ORDER BY latest_payment_date DESC
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 2.9 CASE + DATEDIFF - create a rental status column
-- ─────────────────────────────────────────────────────────────
-- Combine date functions with CASE logic to label each rental
SELECT rental_id, rental_date, return_date,
       CASE
           WHEN return_date IS NULL                             THEN 'Not Returned'
           WHEN DATEDIFF(return_date, rental_date) <= 3        THEN 'Quick Return'
           WHEN DATEDIFF(return_date, rental_date) BETWEEN 4 AND 7 THEN 'Normal Return'
           ELSE                                                     'Late Return'
       END AS rental_status
FROM sakila.rental
LIMIT 20;

-- ─────────────────────────────────────────────────────────────
-- 2.10 Combined math + date practice query (from friend's notes)
-- ─────────────────────────────────────────────────────────────
-- Full customer payment summary using JOIN + math + date functions together
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       COUNT(p.payment_id)                                 AS total_transactions,
       SUM(p.amount)                                       AS total_paid,
       ROUND(AVG(p.amount), 2)                             AS average_payment,
       CEIL(MAX(p.amount))                                 AS highest_payment_ceiled,
       FLOOR(MIN(p.amount))                                AS lowest_payment_floored,
       MIN(p.payment_date)                                 AS first_payment_date,
       MAX(p.payment_date)                                 AS latest_payment_date,
       DATEDIFF(MAX(p.payment_date), MIN(p.payment_date))  AS days_between_first_and_last
FROM sakila.customer c
JOIN sakila.payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_paid DESC
LIMIT 10;


-- =============================================================================
-- 3. TRANSITION: BASICS vs ADVANCED
-- =============================================================================
-- Everything covered so far = BASICS of SQL:
--   DDL, DML, DQL, WHERE, GROUP BY, HAVING,
--   built-in string / math / date functions,
--   LIKE, wildcards, LIMIT, ORDER BY
-- These are used in almost EVERY query you will ever write.
--
-- From subqueries onwards = ADVANCED SQL topics.
-- Advanced topics build ON TOP of the basics.
-- You cannot do advanced SQL without being solid on basics first.


-- =============================================================================
-- 4. SUBQUERIES
-- =============================================================================
-- A SUBQUERY is a query within a query.
-- The inner query (subquery) runs FIRST and its result is used by the outer query.
-- Also called: nested query, inner query.
--
-- WHY use subqueries?
-- When you need data from another table but only want that ONE specific column
-- (not a full join). When you want to filter or compute something dynamically
-- rather than hardcoding values.
--
-- WHEN to use subqueries?
-- - You need to filter based on a value that doesn't exist in your current table
-- - You want to add a computed column that comes from another table
-- - You want to avoid writing a complex JOIN
-- - You need to compare each row against an aggregate (e.g., average)
--
-- FOUR TYPES of subqueries:
--   Type 1: Subquery in WHERE clause  (most common - for filtering)
--   Type 2: Subquery in SELECT clause (for adding computed columns)
--   Type 3: Derived Table - subquery in FROM clause (acts as a temp table)
--   Type 4: Correlated Subquery       (inner query references outer query)


-- =============================================================================
-- 5. TYPE 1 - SUBQUERY IN WHERE CLAUSE (filtering)
-- =============================================================================
-- Use case: filter rows based on a value or set of values from another query.
-- Instead of hardcoding: WHERE address_id IN (1, 2, 4, 5...)
-- We use a subquery to get those values dynamically.

-- Example 1: Find customers who live in the city 'Aurora'
-- Without subquery you'd have to manually look up city_id, then address_id.
-- With subquery: it's all in one query, dynamic and clean.
SELECT first_name, last_name
FROM sakila.customer
WHERE address_id IN (
    SELECT address_id
    FROM sakila.address
    WHERE city_id = (
        SELECT city_id
        FROM sakila.city
        WHERE city = 'Aurora'
    )
);

-- Example 2: Films with rental_rate above the average rental rate
-- Inner query calculates AVG(rental_rate) -> outer query filters by that
SELECT title, rental_rate
FROM sakila.film
WHERE rental_rate > (
    SELECT AVG(rental_rate)
    FROM sakila.film
);

-- Example 3: Payments above the average payment amount
SELECT payment_id, customer_id, amount
FROM sakila.payment
WHERE amount > (
    SELECT AVG(amount)
    FROM sakila.payment
);

-- Example 4: Get actor details for actors who acted in at least 10 films
-- Inner query: group film_actor by actor_id, keep those with count >= 10
-- Outer query: get actor names for those actor_ids
SELECT actor_id, first_name, last_name
FROM sakila.actor
WHERE actor_id IN (
    SELECT actor_id
    FROM sakila.film_actor
    GROUP BY actor_id
    HAVING COUNT(film_id) >= 10
);
-- Note: subqueries are COSTLY. Each one adds an extra execution step.
-- That's why subqueries are considered advanced - they take more time.


-- =============================================================================
-- 6. TYPE 2 - SUBQUERY IN SELECT CLAUSE (adding computed columns)
-- =============================================================================
-- Use case: add a column that doesn't exist in the main table.
-- The subquery is placed inside SELECT and runs once per row.
-- The result appears as a new computed column in the output.
-- Important: the subquery MUST return exactly ONE value per row.
-- If it returns multiple rows, SQL throws: "Subquery returns more than 1 row"

-- Example 1: Show each customer with their total payment (from payment table)
-- actor table has no 'total_paid' column - we derive it via subquery
SELECT customer_id, first_name, last_name,
       (
           SELECT SUM(amount)
           FROM sakila.payment
           WHERE payment.customer_id = customer.customer_id
       ) AS total_paid
FROM sakila.customer;

-- Example 2: Show each category with how many films belong to it
-- film_category is the bridge table connecting categories and films
SELECT category_id, name,
       (
           SELECT COUNT(*)
           FROM sakila.film_category
           WHERE film_category.category_id = category.category_id
       ) AS film_count
FROM sakila.category;

-- Example 3: Show each actor with their film count (from film_actor table)
-- actor table has no film count - bring it from film_actor via subquery
SELECT actor_id, first_name, last_name,
       (
           SELECT COUNT(*)
           FROM sakila.film_actor
           WHERE film_actor.actor_id = actor.actor_id
       ) AS film_count
FROM sakila.actor;
-- Before: could only see actor_id, first_name, last_name.
-- After adding subquery in SELECT: now we also see film_count alongside.


-- =============================================================================
-- 7. TYPE 3 - DERIVED TABLE (subquery in FROM clause)
-- =============================================================================
-- A derived table is a subquery used inside the FROM clause.
-- It acts as a TEMPORARY TABLE that exists ONLY during query execution.
-- You must give it an alias name (required - no alias = error).
--
-- IMPORTANT: Derived tables are NOT stored physically in the database.
-- They are created and destroyed at query execution time.
-- If you try SELECT * FROM derived_table_name outside the query -> ERROR.
-- Scope is ONLY at the query level.
--
-- Two drawbacks of subqueries in general:
--   1. Scope limited to execution time (not persistent)
--   2. Performance cost: runs two queries (inner + outer) = slower

-- Example 1: Find customers whose total payment is greater than 150
SELECT *
FROM (
    SELECT customer_id, SUM(amount) AS total_paid
    FROM sakila.payment
    GROUP BY customer_id
) AS customer_totals                       -- alias is REQUIRED
WHERE total_paid > 150;

-- Example 2: Get top 25 customers by total spend
SELECT customer_id, total_payment
FROM (
    SELECT customer_id, SUM(amount) AS total_payment
    FROM sakila.payment
    GROUP BY customer_id
    ORDER BY total_payment DESC
    LIMIT 25
) AS top_customers;

-- Example 3: Find categories with more than 60 films
SELECT *
FROM (
    SELECT c.name AS category_name,
           COUNT(fc.film_id) AS film_count
    FROM sakila.category c
    JOIN sakila.film_category fc ON c.category_id = fc.category_id
    GROUP BY c.name
) AS category_summary
WHERE film_count > 60;

-- Example 4: Ratings where average rental duration > 5 days
SELECT *
FROM (
    SELECT rating, AVG(rental_duration) AS avg_rental_days
    FROM sakila.film
    GROUP BY rating
) AS rating_summary
WHERE avg_rental_days > 5;

-- Example 5: CASE statement as derived table
-- CASE logic creates a custom 'name_group' column that doesn't exist in the table.
-- We derive it in a subquery, then query from that derived table.
SELECT customer_id, last_name, name_group
FROM (
    SELECT customer_id, last_name,
           CASE
               WHEN LEFT(last_name, 1) BETWEEN 'A' AND 'M' THEN 'A to M'
               WHEN LEFT(last_name, 1) BETWEEN 'N' AND 'Z' THEN 'N to Z'
               ELSE 'Other'
           END AS name_group
    FROM sakila.customer
) AS grouped_customers
WHERE name_group = 'A to M';


-- =============================================================================
-- 8. TYPE 4 - CORRELATED SUBQUERY
-- =============================================================================
-- A correlated subquery is a subquery that REFERENCES A COLUMN from the outer query.
-- This creates a dependency: the inner query CANNOT run independently.
-- The inner query executes ONCE PER ROW of the outer query.
-- The inner query's result CHANGES for each row of the outer query.
--
-- Why "correlated"? Because the inner and outer queries are CORRELATED
-- (linked / dependent on each other) via a shared column reference.

-- Example 1: Show films with their actor count (inner query references outer film table)
-- For each film in the outer query, inner query counts actors for THAT SPECIFIC film_id
SELECT f.title,
       (
           SELECT COUNT(*)
           FROM sakila.film_actor fa
           WHERE fa.film_id = f.film_id   -- f.film_id comes from OUTER query
       ) AS actor_count
FROM sakila.film f;
-- Execution: for title "Academy Dinosaur" -> inner query runs with film_id=1 -> counts actors for film 1
--            for title "Ace Goldfinger"   -> inner query runs with film_id=2 -> counts actors for film 2
-- This is the CORRELATION. Inner query uses values from the current outer row.

-- Example 2: Show films with more than 5 actors
SELECT film_id, title
FROM sakila.film f
WHERE (
    SELECT COUNT(*)
    FROM sakila.film_actor fa
    WHERE fa.film_id = f.film_id
) > 5;

-- Example 3: Show actors who acted in more than 20 films
SELECT actor_id, first_name, last_name
FROM sakila.actor a
WHERE (
    SELECT COUNT(*)
    FROM sakila.film_actor fa
    WHERE fa.actor_id = a.actor_id
) > 20;

-- Example 4: Payments above the average payment for THAT SPECIFIC CUSTOMER
-- (Not the overall average - the average per customer)
-- p1 = outer payment table, p2 = inner payment table
-- Inner query calculates AVG only for the same customer_id as the current outer row
SELECT p1.payment_id, p1.customer_id, p1.amount, p1.payment_date
FROM sakila.payment p1
WHERE p1.amount > (
    SELECT AVG(p2.amount)
    FROM sakila.payment p2
    WHERE p2.customer_id = p1.customer_id   -- p1.customer_id from OUTER query
);
-- This shows payments where the customer paid MORE than their OWN average.

-- Example 5: Customers who paid more than the overall average payment total
SELECT customer_id, first_name, last_name
FROM sakila.customer c
WHERE (
    SELECT SUM(amount)
    FROM sakila.payment p
    WHERE p.customer_id = c.customer_id
) > (
    SELECT AVG(amount)
    FROM sakila.payment
);


-- =============================================================================
-- 9. BRIDGE TABLES
-- =============================================================================
-- A bridge table (also called junction/associative table) is used when
-- two tables have a MANY-TO-MANY relationship.
-- Neither table can hold a foreign key to the other directly because
-- one film has MANY actors and one actor works in MANY films.
--
-- film table:       film_id, title, description... (no actor_id FK)
-- actor table:      actor_id, first_name, last_name (no film_id FK)
-- film_actor table: film_id + actor_id (the BRIDGE - links both)
--
-- How to query across all three:
--   Join film -> film_actor (on film_id)
--   Join film_actor -> actor (on actor_id)
-- This gives you access to both film info and actor info.

-- Example 1: Find all films featuring actor 'NICK WAHLBERG'
SELECT film_id, title
FROM sakila.film
WHERE film_id IN (
    SELECT fa.film_id
    FROM sakila.film_actor fa
    WHERE fa.actor_id = (
        SELECT actor_id
        FROM sakila.actor
        WHERE first_name = 'NICK'
          AND last_name = 'WAHLBERG'
    )
);

-- Example 2: Find all films in the 'Action' category
-- category -> film_category (bridge) -> film
SELECT film_id, title
FROM sakila.film
WHERE film_id IN (
    SELECT film_id
    FROM sakila.film_category
    WHERE category_id = (
        SELECT category_id
        FROM sakila.category
        WHERE name = 'Action'
    )
);

-- Example 3: JOIN approach using bridge table (film + film_actor + actor)
-- Three-table join to see film title alongside actor first and last name
SELECT f.title,
       a.actor_id,
       a.first_name,
       a.last_name
FROM sakila.film f
JOIN sakila.film_actor fa ON f.film_id = fa.film_id     -- film -> bridge
JOIN sakila.actor a        ON fa.actor_id = a.actor_id; -- bridge -> actor
-- This bridge approach gives the full picture:
-- which actors starred in each film


-- =============================================================================
-- 10. WHEN SUBQUERIES FAIL
-- =============================================================================
-- Subqueries fail in several predictable situations. Know these:

-- FAILURE 1: Returns multiple rows where only ONE is expected
-- Using '=' when subquery returns more than one value
-- WRONG (will error if film_category has multiple rows):
-- SELECT title FROM film WHERE film_id = (SELECT film_id FROM film_category);
-- CORRECT: use IN instead of = when multiple values are possible
SELECT title
FROM sakila.film
WHERE film_id IN (
    SELECT film_id
    FROM sakila.film_category
);

-- FAILURE 2: Subquery in SELECT returns multiple rows (must return exactly 1)
-- Adding LIMIT 1 forces it to return only one value - removes ambiguity
-- Without LIMIT 1: "Subquery returns more than 1 row" error
SELECT first_name,
       (
           SELECT address_id
           FROM sakila.address
           WHERE district = 'California'
           LIMIT 1                        -- limits to exactly 1 row
       ) AS california_address_id
FROM sakila.customer
LIMIT 5;
-- Note: LIMIT 1 assigns the SAME value to ALL rows in the outer query.
-- This is a query-level transformation only. Original table data is unchanged.

-- FAILURE 3: Derived table without an alias (alias is REQUIRED)
-- WRONG:
-- SELECT * FROM (SELECT * FROM actor);
-- CORRECT: always give derived tables an alias
SELECT *
FROM (
    SELECT *
    FROM sakila.actor
) AS actor_table;                  -- alias 'actor_table' is required

-- FAILURE 4: Using aggregate function inside WHERE (not allowed)
-- WRONG: SELECT first_name FROM customer WHERE SUM(store_id) > 1;
-- Aggregate functions (SUM, AVG, COUNT, MIN, MAX) cannot go inside WHERE.
-- Use HAVING after GROUP BY, or use a subquery.
-- CORRECT:
SELECT customer_id
FROM sakila.payment
GROUP BY customer_id
HAVING SUM(amount) > 100;

-- FAILURE 5: Data type mismatch
-- If subquery returns a text value but outer query expects an integer, it will error.
-- Always make sure the subquery returns the same data type the outer query expects.

-- SUMMARY of subquery failure causes:
-- 1. Returns multiple rows where = expects 1   -> use IN or LIMIT 1
-- 2. SELECT subquery returns more than 1 row   -> use LIMIT 1 or aggregate
-- 3. Derived table has no alias                -> always alias it
-- 4. Aggregate in WHERE clause                 -> use HAVING or subquery
-- 5. Data type mismatch                        -> match types


-- =============================================================================
-- 11. NEXT SESSION - LECTURE 04
-- =============================================================================
-- Topics to be covered (tomorrow, 9:00 AM):
--   - CTEs (Common Table Expressions)
--   - JOINs (INNER, LEFT, RIGHT, FULL)
--   - JOIN cardinality
--   - Remaining string functions not covered yet
