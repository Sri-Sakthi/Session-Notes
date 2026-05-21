-- =============================================================================
-- LECTURE 02 - DQL (SELECT IN DEPTH) + BUILT-IN STRING FUNCTIONS
-- Course  : Data Science & SQL Bootcamp
-- Date    : 20 May 2026
-- Topics  : SELECT, DISTINCT, COUNT, LIMIT, WHERE, ORDER BY, AND/OR/NOT,
--           LIKE + Wildcards, NULL handling, BETWEEN, GROUP BY, HAVING,
--           SQL Execution Order, Built-in String Functions
-- Database: sakila (sample database used in all examples)
-- Note    : Instructor said: keep queries + comments in ONE .sql file.
--           Don't split into Word doc + SQL separately.
-- =============================================================================

USE sakila;

-- =============================================================================
-- 1. SELECT - DATA QUERY LANGUAGE (DQL)
-- =============================================================================
-- SELECT is the only DQL command. Used to READ/FETCH data from tables.
-- It never modifies the original data. Everything here is query-level only.
-- Real world: you ALWAYS query data more than you insert/update it.

-- 1.1 SELECT ALL COLUMNS
-- * means all columns. Fetches every column and every row from the table.
SELECT * FROM sakila.actor;
SELECT * FROM sakila.film;

-- 1.2 SELECT SPECIFIC COLUMNS
-- Only fetch the columns you actually need. Saves memory and cost on real servers.
SELECT first_name, last_name FROM sakila.actor;
SELECT title, rental_rate FROM sakila.film;

-- 1.3 DISTINCT - remove duplicates in results
-- Without DISTINCT: 200 first_name rows returned (many duplicates)
-- With DISTINCT: only unique first names returned
SELECT DISTINCT first_name FROM sakila.actor;

-- DISTINCT with WHERE: unique titles where original_language_id is NULL
SELECT DISTINCT title FROM sakila.film WHERE original_language_id IS NULL;

-- 1.4 COUNT - count number of records
-- COUNT(*) counts ALL rows including NULLs
SELECT COUNT(*) FROM sakila.film;
-- COUNT(column) counts only NON-NULL values in that column
SELECT COUNT(first_name) FROM sakila.actor;

-- COUNT DISTINCT - count only unique values in a column
SELECT COUNT(DISTINCT title) FROM sakila.film;
SELECT COUNT(DISTINCT first_name) FROM sakila.actor;

-- Compare COUNT vs COUNT DISTINCT to find duplicates:
-- Total first names: 200 | Unique first names: 128 -> 72 people share same first name
-- This is how you detect duplicates in your data.

-- 1.5 LIMIT - restrict how many rows are returned
-- DO NOT query all 1000 rows just to preview data.
-- Every query on a real server costs computation, memory, and money.
-- Use LIMIT to sample the data first and understand its structure.
SELECT * FROM sakila.actor LIMIT 10;
SELECT first_name, last_name FROM sakila.actor LIMIT 5;
SELECT * FROM sakila.film LIMIT 100;


-- =============================================================================
-- 2. WHERE CLAUSE - FILTERING ROWS
-- =============================================================================
-- WHERE filters at the individual ROW level BEFORE any grouping.
-- Always applied to raw records in the original table data.

-- 2.1 WHERE with text condition
-- Shows only films with PG rating
SELECT * FROM sakila.film WHERE rating = 'PG';

-- 2.2 WHERE with numeric condition
-- Shows films where rental rate is greater than 2.99
SELECT title, rental_rate FROM sakila.film WHERE rental_rate > 2.99;

-- 2.3 WHERE with IS NULL - find missing/empty values
-- Shows films where original_language_id has no value assigned
SELECT * FROM sakila.film WHERE original_language_id IS NULL;
SELECT title, original_language_id FROM sakila.film WHERE original_language_id IS NULL;

-- IMPORTANT: Never use = NULL. Always use IS NULL.
-- X = NULL  -> WRONG (always returns nothing)
-- X IS NULL -> CORRECT

-- 2.4 WHERE with IS NOT NULL - find rows that HAVE a value
-- Shows addresses where address2 has some value filled in
SELECT address, address2 FROM sakila.address WHERE address2 IS NOT NULL;
-- Rentals that HAVE been returned (return_date is filled)
SELECT rental_id, inventory_id, customer_id, return_date
FROM sakila.rental
WHERE return_date IS NOT NULL;

-- 2.5 Rentals NEVER returned (return_date IS NULL)
-- NULL here is NOT an error - it tells a meaningful story:
-- customer still has the film / has not returned it yet
SELECT rental_id, inventory_id, customer_id, return_date
FROM sakila.rental
WHERE return_date IS NULL;
-- Result: 183 customers haven't returned their film

-- Key lesson on NULLs:
-- NOT all nulls need replacing. Understand what the NULL means first.
--   return_date = NULL -> valid business state (film not returned yet) -> KEEP it
--   age = NULL         -> likely missing/bad data that needs fixing -> HANDLE it

-- 2.6 WHERE with multiple column conditions and AND
-- Films with rating R AND length greater than 92 minutes
SELECT * FROM sakila.film
WHERE rating = 'R' AND length > 92;
-- Result: 135 rows

-- 2.7 BETWEEN - filter within a range (inclusive on both ends)
-- Works on numbers AND dates
SELECT title, rental_duration FROM sakila.film
WHERE rental_duration BETWEEN 3 AND 5;

SELECT title, replacement_cost FROM sakila.film
WHERE replacement_cost BETWEEN 10.99 AND 20.99;

-- BETWEEN with dates: rentals returned within a specific date window
SELECT rental_id, inventory_id, customer_id, return_date
FROM sakila.rental
WHERE return_date BETWEEN '2005-05-26' AND '2005-05-30';
-- Result: 196 transactions in that window


-- =============================================================================
-- 3. LOGICAL OPERATORS - AND, OR, NOT, IN, NOT IN
-- =============================================================================
-- Combine or negate multiple conditions inside WHERE clause.

-- 3.1 AND - ALL conditions must be true (strict / narrow filter)
SELECT title, rating, rental_rate FROM sakila.film
WHERE rating = 'PG' AND rental_rate = 2.99;

-- AND with rental duration
SELECT * FROM sakila.film
WHERE rating = 'PG' AND rental_duration = 5;

-- 3.2 OR - ANY one condition can be true (relaxed / wider filter)
SELECT title, rating FROM sakila.film
WHERE rating = 'PG' OR rating = 'G';

-- OR with rental duration
SELECT * FROM sakila.film
WHERE rating = 'PG' OR rental_duration = 5;

-- 3.3 AND + OR together - use brackets to avoid confusion
-- Shows PG or G movies with rental rate of 2.99
SELECT title, rating, rental_rate FROM sakila.film
WHERE (rating = 'PG' OR rating = 'G') AND rental_rate = 2.99;

-- Rental duration = 6 AND rating is G or PG
SELECT * FROM sakila.film
WHERE rental_duration = 6
  AND (rating = 'G' OR rating = 'PG');

-- 3.4 NOT - negate/exclude a condition
SELECT title, rating FROM sakila.film WHERE NOT rating = 'PG';

-- 3.5 NOT IN - exclude multiple specific values
SELECT title, rating FROM sakila.film WHERE rating NOT IN ('PG', 'G');
SELECT * FROM sakila.film WHERE rental_duration NOT IN (6, 7, 3);

-- 3.6 IN - include only specific values
SELECT * FROM sakila.film WHERE rental_duration IN (6, 7, 3);

-- 3.7 NOT EQUAL TO - three equivalent ways to write it
SELECT * FROM sakila.film WHERE rental_duration != 6;
SELECT * FROM sakila.film WHERE rental_duration <> 6;
SELECT * FROM sakila.film WHERE NOT rental_duration = 6;


-- =============================================================================
-- 4. ORDER BY - SORTING RESULTS
-- =============================================================================
-- Sorts the query result set.
-- Default is ASC (ascending - smallest to largest, A to Z).
-- Must write DESC explicitly for descending (largest to smallest, Z to A).

-- 4.1 Default ascending order (low to high)
SELECT title, rental_rate FROM sakila.film ORDER BY rental_rate;

-- 4.2 Descending order (high to low)
SELECT title, rental_rate FROM sakila.film ORDER BY rental_rate DESC;

-- 4.3 Sort combined with WHERE filter
SELECT * FROM sakila.film
WHERE rating = 'R' AND length > 92
ORDER BY length DESC;

-- 4.4 Sort by length in ascending order (default)
SELECT * FROM sakila.film ORDER BY length;

-- 4.5 ORDER BY with GROUP BY (alias works here since SELECT runs before ORDER BY)
SELECT rating, COUNT(*) AS total_films
FROM sakila.film
GROUP BY rating
ORDER BY total_films DESC;


-- =============================================================================
-- 5. LIKE OPERATOR + WILDCARDS
-- =============================================================================
-- Used when you know a PATTERN but not the exact value.
-- Two wildcards:
--   %  (percent)    = zero, one, or MANY characters -> use when position is unknown
--   _  (underscore) = exactly ONE character at a SPECIFIC position

-- 5.1 EXACT match (no wildcard needed, use = instead)
SELECT * FROM sakila.city WHERE city = 'New York';

-- 5.2 % wildcard - STARTS WITH 'A'
SELECT first_name, last_name FROM sakila.actor WHERE first_name LIKE 'A%';

-- 5.3 % wildcard - ENDS WITH 'A'
SELECT first_name, last_name FROM sakila.actor WHERE first_name LIKE '%A';

-- 5.4 % wildcard - CONTAINS 's' anywhere in the name
SELECT * FROM sakila.city WHERE city LIKE '%s%';

-- 5.5 % wildcard - STARTS WITH 'S' ends with anything
SELECT * FROM sakila.city WHERE city LIKE 'S%';

-- 5.6 % wildcard - ENDS WITH 's'
SELECT * FROM sakila.city WHERE city LIKE '%s';

-- 5.7 % wildcard - STARTS WITH 'A' AND ENDS WITH 's' (anything in between)
SELECT * FROM sakila.city WHERE city LIKE 'A%s';

-- 5.8 _ wildcard - 2nd character must be 'A', rest can be anything
SELECT first_name, last_name FROM sakila.actor WHERE first_name LIKE '_A%';

-- 5.9 _ wildcard - 4th character must be 'A', rest can be anything
SELECT * FROM sakila.city WHERE city LIKE '___A%';

-- 5.10 _ wildcard - specific positions with mixed wildcards
-- 4th char = 'A', 6th char = 's', everything else can be anything
SELECT * FROM sakila.city WHERE city LIKE '___A_s%';

-- Rule of thumb:
-- Use %  when you DON'T know the position of the character
-- Use _  when you DO know the exact position of the character


-- =============================================================================
-- 6. GROUP BY + HAVING
-- =============================================================================
-- GROUP BY: groups rows sharing the same value into a single summary row.
--           Always used with aggregate functions: COUNT, SUM, AVG, MIN, MAX.
-- HAVING:   filters the GROUPED data AFTER aggregation.
--           WHERE filters individual rows. HAVING filters groups.

-- 6.1 GROUP BY - count films for each rating category
SELECT rating, COUNT(*) AS total_films
FROM sakila.film
GROUP BY rating;

-- 6.2 GROUP BY on rental table - count how many rentals each customer made
SELECT customer_id, COUNT(*) AS count_rentals
FROM sakila.rental
GROUP BY customer_id;

-- 6.3 HAVING - filter groups: only ratings with more than 200 films
SELECT rating, COUNT(*) AS total_films
FROM sakila.film
GROUP BY rating
HAVING COUNT(*) > 200;

-- 6.4 HAVING - only customers who rented 30 or more times
SELECT customer_id, COUNT(*) AS count_rentals
FROM sakila.rental
GROUP BY customer_id
HAVING COUNT(*) >= 30
ORDER BY count_rentals DESC;
-- NOTE: Use COUNT(*) in HAVING, NOT the alias 'count_rentals'
-- Reason: HAVING executes BEFORE SELECT, so alias doesn't exist yet (see Section 7)

-- 6.5 GROUP BY + HAVING + ORDER BY combined
SELECT rating, COUNT(*) AS total_films
FROM sakila.film
GROUP BY rating
HAVING COUNT(*) > 150
ORDER BY total_films DESC;

-- 6.6 GROUP BY at TWO column levels (customer + inventory)
-- Splits the count further per customer per item.
-- Only add multiple GROUP BY columns when you genuinely need that granularity.
SELECT customer_id, inventory_id, COUNT(*) AS count_rentals
FROM sakila.rental
GROUP BY customer_id, inventory_id;

-- 6.7 WHERE + GROUP BY + HAVING together
-- WHERE filters raw rows FIRST, THEN group, THEN HAVING filters groups
-- Films with rental_rate > 2.99 grouped by rating, only ratings with 50+ such films
SELECT rating, COUNT(*) AS total_films
FROM sakila.film
WHERE rental_rate > 2.99          -- row-level filter applied first
GROUP BY rating
HAVING COUNT(*) > 50;             -- group-level filter applied after

-- 6.8 WHERE + GROUP BY + HAVING on payment table
SELECT customer_id, SUM(amount) AS total_payment
FROM sakila.payment
WHERE customer_id BETWEEN 1 AND 100   -- filter rows first
GROUP BY customer_id
HAVING SUM(amount) >= 100             -- filter groups after
ORDER BY total_payment DESC;

-- 6.9 WHERE vs HAVING - KEY DIFFERENCE (summary)
-- WHERE  -> filters individual ROWS on the original raw data (before grouping)
-- HAVING -> filters GROUPS after aggregation (after GROUP BY)
-- You CANNOT use aggregate functions (COUNT, SUM...) inside WHERE
-- You CAN use them inside HAVING


-- =============================================================================
-- 7. SQL QUERY EXECUTION ORDER
-- =============================================================================
-- The order you WRITE a query is NOT the order it executes internally.
-- SQL has its own fixed backend execution sequence.
--
-- Written order:   SELECT -> FROM -> WHERE -> GROUP BY -> HAVING -> ORDER BY -> LIMIT
-- Execution order: FROM -> (JOINS) -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY -> LIMIT
--
-- Step-by-step breakdown:
--   1. FROM        - fetch raw table data (apply JOINs here if any)
--   2. WHERE       - filter individual rows from raw data
--   3. GROUP BY    - group filtered rows
--   4. HAVING      - filter groups based on aggregate conditions
--   5. SELECT      - pick which columns to return + apply aliases
--   6. ORDER BY    - sort the final result
--   7. LIMIT       - cut output to N rows
--
-- Why this matters in practice:
--   - Alias names defined in SELECT are NOT available during HAVING
--     because HAVING runs BEFORE SELECT
--   - So always use the ORIGINAL aggregate expression in HAVING:
--     CORRECT:   HAVING COUNT(*) >= 30
--     INCORRECT: HAVING count_rentals >= 30   (alias doesn't exist yet)
--
-- Unlike Python which runs line by line top to bottom,
-- SQL has its own internal execution order regardless of how you write it.

-- Example showing execution order in action:
SELECT rating, COUNT(*) AS total_films   -- Step 5: SELECT (alias created here)
FROM sakila.film                          -- Step 1: FROM
WHERE rental_rate > 2.99                 -- Step 2: WHERE  (row-level filter)
GROUP BY rating                          -- Step 3: GROUP BY
HAVING COUNT(*) > 50                     -- Step 4: HAVING (must use COUNT(*), not alias)
ORDER BY total_films DESC                -- Step 6: ORDER BY (alias available here)
LIMIT 10;                                -- Step 7: LIMIT


-- =============================================================================
-- 8. BUILT-IN STRING FUNCTIONS
-- =============================================================================
-- Pre-written functions to manipulate string/text data.
-- Save you from writing custom logic from scratch for common operations.
-- ALL of these are DQL operations. They DO NOT change the original stored data.
-- They transform the OUTPUT at query execution time only.
-- When you go back and SELECT the original table, nothing is changed.

-- ─────────────────────────────────────────────────────────────
-- 8.1 LPAD() - Left Padding
-- ─────────────────────────────────────────────────────────────
-- Adds characters to the LEFT of a string until total length is reached.
-- Syntax: LPAD(string, total_length, pad_character)

-- Pad actor first_name to 10 characters using '*' on the left
SELECT first_name,
       LPAD(first_name, 10, '*') AS padded_name
FROM sakila.actor;

-- Practical use: format customer_id to always be 5 digits (1 -> 00001)
SELECT customer_id,
       LPAD(customer_id, 5, '0') AS formatted_customer_id
FROM sakila.customer;

-- Film titles padded to 20 chars with '*' on the left
SELECT title,
       LPAD(title, 20, '*') AS left_padded_title
FROM sakila.film;

-- ─────────────────────────────────────────────────────────────
-- 8.2 RPAD() - Right Padding
-- ─────────────────────────────────────────────────────────────
-- Adds characters to the RIGHT of a string until total length is reached.
-- Syntax: RPAD(string, total_length, pad_character)

SELECT first_name,
       RPAD(first_name, 10, '*') AS padded_name
FROM sakila.actor;

-- ─────────────────────────────────────────────────────────────
-- 8.3 LPAD + RPAD combined - pad on BOTH sides
-- ─────────────────────────────────────────────────────────────
-- Apply LPAD first to reach 10 chars, then RPAD to reach 15 chars
-- Result: padding on both left and right sides
SELECT first_name,
       RPAD(LPAD(first_name, 10, '*'), 15, '-') AS formatted_name
FROM sakila.actor;

-- Class demo version: 25 chars total using star padding on both sides
SELECT title,
       LPAD(RPAD(title, 22, '*'), 25, '*') AS both_padded_title
FROM sakila.film;

-- ─────────────────────────────────────────────────────────────
-- 8.4 SUBSTRING() - Extract part of a string
-- ─────────────────────────────────────────────────────────────
-- Syntax: SUBSTRING(string, start_position, length)
-- IMPORTANT: SQL string indexing starts at 1 (unlike Python which starts at 0)

-- Extract first 5 characters of title (positions 1 to 5)
SELECT title,
       SUBSTRING(title, 1, 5) AS first_5_chars
FROM sakila.film;

-- Extract from position 2, take 5 characters (friend's example)
SELECT title,
       SUBSTRING(title, 2, 5) AS first_five_letters
FROM sakila.film;

-- Extract from position 5, take 5 characters
SELECT title,
       SUBSTRING(title, 5, 5) AS mid_chars
FROM sakila.film;

-- ─────────────────────────────────────────────────────────────
-- 8.5 CONCAT() - Join strings together
-- ─────────────────────────────────────────────────────────────
-- Syntax: CONCAT(value1, separator, value2, ...)
-- Result is NOT in the original table - this is a transformed display output.

-- Combine first_name and last_name with a space
SELECT first_name, last_name,
       CONCAT(first_name, ' ', last_name) AS full_name
FROM sakila.actor;

-- Combine with dot separator (instructor demo)
SELECT first_name, last_name,
       CONCAT(first_name, '.', last_name) AS full_name
FROM sakila.customer;

-- Combine title with rental rate into a readable sentence
SELECT title, rental_rate,
       CONCAT(title, ' costs $', rental_rate) AS film_price_text
FROM sakila.film
LIMIT 10;

-- Real-world use: create email ID from first_name + last_name + domain
-- CONCAT(first_name, '.', last_name, '@company.com') AS email_id

-- ─────────────────────────────────────────────────────────────
-- 8.6 REVERSE() - Reverse a string
-- ─────────────────────────────────────────────────────────────
-- Returns characters in reverse order

SELECT first_name,
       REVERSE(first_name) AS reversed_name
FROM sakila.actor;

-- ─────────────────────────────────────────────────────────────
-- 8.7 LENGTH() - Count characters in a string
-- ─────────────────────────────────────────────────────────────
-- Returns the number of characters (bytes) in the string

SELECT first_name,
       LENGTH(first_name) AS name_length
FROM sakila.actor;

-- Sort films by longest title first
SELECT title, LENGTH(title) AS title_length
FROM sakila.film
ORDER BY title_length DESC;

-- Filter using LENGTH in WHERE clause
-- Get titles with exactly 8 characters
SELECT title, LENGTH(title) AS title_length
FROM sakila.film
WHERE LENGTH(title) = 8;

-- Get titles with 8 or more characters
SELECT title, LENGTH(title) AS title_length
FROM sakila.film
WHERE LENGTH(title) >= 8;

-- ─────────────────────────────────────────────────────────────
-- 8.8 LOCATE() - Find position of a character in a string
-- ─────────────────────────────────────────────────────────────
-- Returns the index position where a character first appears.
-- Returns 0 if the character is not found.
-- Syntax: LOCATE(search_character, string)

-- Find where 'A' first appears in each film title
SELECT title,
       LOCATE('A', title) AS position_of_A
FROM sakila.film;

-- ─────────────────────────────────────────────────────────────
-- 8.9 SUBSTRING + LOCATE combined - dynamic string extraction
-- ─────────────────────────────────────────────────────────────
-- Problem: email IDs have different lengths, so '@' is at different positions.
-- Hardcoding a position like SUBSTRING(email, 10, ...) would break for most emails.
-- Solution: use LOCATE to find '@' dynamically, then SUBSTRING to extract.

-- Extract the domain (everything AFTER @)
-- LOCATE('@', email) gives the position of @
-- +1 moves one step past the @ to start after it
SELECT email,
       LOCATE('@', email) AS at_position,
       SUBSTRING(email, LOCATE('@', email) + 1) AS domain
FROM sakila.customer;

-- Extract the username (everything BEFORE @)
-- LOCATE('@', email) - 1 stops one character before the @
SELECT email,
       SUBSTRING(email, 1, LOCATE('@', email) - 1) AS username
FROM sakila.customer;

-- Friend's version (includes the @ in the result)
SELECT email,
       SUBSTRING(email, 1, LOCATE('@', email) + 1) AS username_part
FROM sakila.customer;

-- ─────────────────────────────────────────────────────────────
-- 8.10 SUBSTRING_INDEX() - Split string by delimiter
-- ─────────────────────────────────────────────────────────────
-- Syntax: SUBSTRING_INDEX(string, delimiter, count)
-- Positive count -> extract from the LEFT  (before delimiter)
-- Negative count -> extract from the RIGHT (after delimiter)

-- Get username (part before @)
SELECT email,
       SUBSTRING_INDEX(email, '@', 1) AS username_part
FROM sakila.customer;

-- Get domain (part after @) -> e.g. sakilacustomer.org
SELECT email,
       SUBSTRING_INDEX(email, '@', -1) AS domain_part
FROM sakila.customer;

-- Get TLD only (e.g. 'org' from 'sakilacustomer.org')
-- Step 1: get everything after @ first
-- Step 2: from that result, get everything after the LAST dot
SELECT email,
       SUBSTRING_INDEX(
           SUBSTRING(email, LOCATE('@', email) + 1),
           '.', -1
       ) AS tld
FROM sakila.customer;

-- Direction rule:
-- SUBSTRING_INDEX(string, '.', 1)  -> LEFT  of first dot  (customer part)
-- SUBSTRING_INDEX(string, '.', -1) -> RIGHT of last dot   (org / com / net)

-- ─────────────────────────────────────────────────────────────
-- 8.11 UPPER() and LOWER() - Change text case
-- ─────────────────────────────────────────────────────────────

-- Convert to UPPERCASE
SELECT first_name,
       UPPER(first_name) AS uppercase_name
FROM sakila.actor;

-- Convert to lowercase
SELECT first_name,
       LOWER(first_name) AS lowercase_name
FROM sakila.actor;

-- Use UPPER inside WHERE with LIKE for case-insensitive pattern matching
SELECT title
FROM sakila.film
WHERE UPPER(title) LIKE '%MAN%'
   OR UPPER(title) LIKE '%LOVE%';

-- ─────────────────────────────────────────────────────────────
-- 8.12 LEFT() and RIGHT() - Extract from left or right end
-- ─────────────────────────────────────────────────────────────
-- LEFT(string, n)  -> get first n characters from the beginning
-- RIGHT(string, n) -> get last  n characters from the end

-- First 3 letters of first_name
SELECT first_name,
       LEFT(first_name, 3) AS first_three_letters
FROM sakila.actor;

-- Last 3 letters of last_name
SELECT last_name,
       RIGHT(last_name, 3) AS last_three_letters
FROM sakila.actor;

-- Class demo: 2 from left, 3 from right of film title
SELECT title,
       LEFT(title, 2)  AS left_2,
       RIGHT(title, 3) AS right_3
FROM sakila.film;

-- Combine LEFT with GROUP BY to group films by their first 2 characters
SELECT LEFT(title, 2) AS prefix, COUNT(*) AS count
FROM sakila.film
GROUP BY prefix
ORDER BY count DESC;

-- ─────────────────────────────────────────────────────────────
-- 8.13 CASE Statement - if/else conditional logic in SQL
-- ─────────────────────────────────────────────────────────────
-- Syntax:
--   CASE
--     WHEN condition1 THEN result1
--     WHEN condition2 THEN result2
--     ELSE fallback_result
--   END AS alias_name
--
-- Alias name after END is REQUIRED because CASE creates a new computed column.
-- That column doesn't exist in any table - you must name it.

-- Categorize films by rental rate (cheap / medium / expensive)
SELECT title, rental_rate,
       CASE
           WHEN rental_rate = 0.99 THEN 'Cheap'
           WHEN rental_rate = 2.99 THEN 'Medium'
           WHEN rental_rate = 4.99 THEN 'Expensive'
           ELSE 'Other'
       END AS price_category
FROM sakila.film;

-- Categorize by film length (short / average / long)
SELECT title, length,
       CASE
           WHEN length < 60               THEN 'Short Movie'
           WHEN length BETWEEN 60 AND 120 THEN 'Average Movie'
           ELSE                                'Long Movie'
       END AS movie_duration_type
FROM sakila.film;

-- Class demo: group last names by starting letter (A-M or N-Z)
SELECT last_name,
       CASE
           WHEN LEFT(last_name, 1) BETWEEN 'A' AND 'M' THEN 'A to M'
           WHEN LEFT(last_name, 1) BETWEEN 'N' AND 'Z' THEN 'N to Z'
           ELSE 'Other'
       END AS group_label
FROM sakila.actor;

-- ─────────────────────────────────────────────────────────────
-- 8.14 REPLACE() - Replace characters in a string
-- ─────────────────────────────────────────────────────────────
-- Syntax: REPLACE(string, find_this, replace_with_this)
-- DQL operation only - does NOT change the stored data. Output-only transformation.

-- Replace all 'A' in titles with 'X'
SELECT title,
       REPLACE(title, 'A', 'X') AS replaced_title
FROM sakila.film;

-- Practical: replace .org with .com in email for display purposes
SELECT email,
       REPLACE(email, '.org', '.com') AS updated_email
FROM sakila.customer;

-- ─────────────────────────────────────────────────────────────
-- 8.15 REGEXP - Regular Expressions (advanced pattern matching)
-- ─────────────────────────────────────────────────────────────
-- More powerful than LIKE. For complex pattern matching.
-- You don't need to memorize regex - look up patterns when needed.
--
-- Common regex symbols:
--   ^       = start of string
--   $       = end of string
--   [abc]   = any one of these characters
--   [a-z]   = any character in this range
--   {n}     = exactly n repetitions of the previous group
--   |       = OR (match this OR that)

-- Find titles containing 'LOVE' OR 'LIFE'
SELECT title FROM sakila.film
WHERE title REGEXP 'LOVE|LIFE';

-- Find actor first names starting with A, B, or C
SELECT first_name, last_name FROM sakila.actor
WHERE first_name REGEXP '^[A-C]';

-- Find actors whose first name does NOT start with A
SELECT first_name, last_name FROM sakila.actor
WHERE first_name NOT REGEXP '^A';

-- Find actors whose first name does NOT start with a vowel
SELECT first_name, last_name FROM sakila.actor
WHERE first_name NOT REGEXP '^[aeiouAEIOU]';

-- Find last names that do NOT contain 3 consecutive vowels
-- [aeiouAEIOU]{3} = any 3 vowels in a row
SELECT customer_id, last_name FROM sakila.customer
WHERE last_name NOT REGEXP '[aeiouAEIOU]{3}';

-- Find titles ending with a vowel ($ = end of string)
SELECT title FROM sakila.film
WHERE title REGEXP '[aeiouAEIOU]$';

-- Find titles ending with 'E' or 'e'
SELECT title,
       RIGHT(title, 2) AS last_2_chars
FROM sakila.film
WHERE title REGEXP '[Ee]$';

-- Count actors whose first name starts with 'A' using LIKE (simpler alternative)
SELECT COUNT(*) AS names_starting_with_A
FROM sakila.actor
WHERE first_name LIKE 'A%';


-- =============================================================================
-- 9. COMBINED EXAMPLES (from friend's notes)
-- =============================================================================

-- 9.1 Format full name: capitalize first letter, rest lowercase, UPPER last name
SELECT first_name, last_name,
       CONCAT(
           UPPER(LEFT(first_name, 1)),        -- capitalize first letter
           LOWER(SUBSTRING(first_name, 2)),   -- lowercase the rest
           ' ',
           UPPER(last_name)                   -- last name all caps
       ) AS formatted_full_name
FROM sakila.actor;

-- 9.2 Multiple string operations on film title at once
SELECT title,
       LENGTH(title)    AS title_length,
       LEFT(title, 5)   AS first_5_chars,
       RIGHT(title, 5)  AS last_5_chars,
       REVERSE(title)   AS reversed_title,
       UPPER(title)     AS uppercase_title
FROM sakila.film
LIMIT 10;

-- 9.3 WHERE vs HAVING side by side (recap example)
-- WHERE filters before grouping, HAVING filters after
SELECT rating, COUNT(*) AS total_films
FROM sakila.film
WHERE rental_rate > 2.99       -- filter individual rows first
GROUP BY rating
HAVING COUNT(*) > 50           -- then filter groups
ORDER BY total_films DESC;

-- 9.4 ORDER BY using alias (works because ORDER BY runs AFTER SELECT)
SELECT rating, COUNT(*) AS total_films
FROM sakila.film
GROUP BY rating
ORDER BY total_films DESC;     -- alias 'total_films' is fine here


-- =============================================================================
-- 10. KEY REMINDERS & NEXT SESSION
-- =============================================================================
-- What we covered in Lecture 02:
--   DQL:
--   - SELECT, SELECT *, SELECT specific columns
--   - DISTINCT, COUNT, COUNT DISTINCT
--   - LIMIT (sample data, reduce cost)
--   - WHERE with =, >, <, IS NULL, IS NOT NULL
--   - BETWEEN (inclusive range for numbers and dates)
--   - AND, OR, NOT, IN, NOT IN, !=, <>
--   - ORDER BY ASC (default) and DESC
--   - LIKE with % (any chars) and _ (one char at known position)
--   - GROUP BY + HAVING (aggregation and group filtering)
--   - SQL Execution Order: FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY -> LIMIT
--
--   String Functions:
--   - LPAD, RPAD (padding to fixed length)
--   - SUBSTRING (extract by position - indexing starts at 1 in SQL)
--   - CONCAT (join strings)
--   - REVERSE (flip string)
--   - LENGTH (count characters, use in WHERE)
--   - LOCATE (find position of a character dynamically)
--   - SUBSTRING_INDEX (split by delimiter, +count = left, -count = right)
--   - UPPER, LOWER (case conversion)
--   - LEFT, RIGHT (extract from ends)
--   - CASE (if/else conditional logic, alias required after END)
--   - REPLACE (substitute characters, query-level only)
--   - REGEXP, NOT REGEXP (advanced pattern matching)
