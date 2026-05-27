USE sakila;
-- =============================================================================
-- 1. TEMPORARY TABLES
-- =============================================================================
-- A temporary table is a table that exists ONLY for the duration of a session
-- or until it is explicitly dropped. It is NOT stored as a physical table.
-- It lives in server memory and is accessible only within the same session.
--
-- Why use it?
-- Subquery and CTE scope = query execution level only (gone after one query).
-- Temporary table scope = SESSION level (stays alive across multiple queries
-- within the same session until you close the connection or drop it).
--
-- Use cases:
-- - Breaking complex queries into steps
-- - Storing intermediate results to reuse multiple times in the same session
-- - ETL / data transformation pipelines
-- - Reporting and performance optimization
-- - Testing transformations without affecting actual data
--
-- Scope: only within your own session.
-- Other users on the same server CANNOT see your temporary table.
-- When the session ends the memory is released and the table is gone.
-- Or you can drop it explicitly with DROP TEMPORARY TABLE.

-- ─────────────────────────────────────────────────────────────
-- 1.1 Basic syntax
-- ─────────────────────────────────────────────────────────────

-- Drop it first (safe to recreate if already exists in memory)
DROP TEMPORARY TABLE IF EXISTS sakila.top_categories;

-- Create the temporary table
CREATE TEMPORARY TABLE sakila.top_categories AS
SELECT c.name AS category_name,
       COUNT(r.rental_id) AS total_rentals
FROM sakila.rental r
JOIN sakila.inventory i        ON r.inventory_id = i.inventory_id
JOIN sakila.film_category fc   ON i.film_id       = fc.film_id
JOIN sakila.category c         ON fc.category_id  = c.category_id
GROUP BY c.name
ORDER BY total_rentals DESC
LIMIT 5;

-- Query the temporary table (works across multiple queries in the same session)
SELECT * FROM sakila.top_categories;

-- Query it again in a different query -- still available because scope is session level
SELECT category_name FROM sakila.top_categories WHERE total_rentals > 7000;

-- ─────────────────────────────────────────────────────────────
-- 1.2 Temporary table vs CTE vs Subquery (scope comparison)
-- ─────────────────────────────────────────────────────────────
-- Subquery  -> scope = inside one query only. Gone after execution.
-- CTE       -> scope = one query execution. Must always run WITH + SELECT together.
-- Temp Table-> scope = entire session. Reusable across multiple separate queries.
-- View      -> scope = global / database level. Anyone on the server can access.
--
-- Temp table stores ACTUAL DATA (runs the query once, saves the result).
-- View stores ONLY THE QUERY (re-executes the query fresh every time you call it).

-- ─────────────────────────────────────────────────────────────
-- 1.3 Generic temp table example 
-- ─────────────────────────────────────────────────────────────
CREATE TEMPORARY TABLE temp_employees (
    id   INT,
    name VARCHAR(100)
);

INSERT INTO temp_employees VALUES (1, 'John');
SELECT * FROM temp_employees;
DROP TABLE temp_employees;


-- =============================================================================
-- 2. VIEWS
-- =============================================================================
-- A VIEW is a virtual table created by storing a SQL query inside the database.
-- The view does NOT store the actual data.
-- Only the QUERY is stored. Every time you call the view, the query re-executes
-- at that moment and returns fresh data from the underlying tables.
--
-- Scope: GLOBAL (database level).
-- Unlike temp tables which are session-only, views are physically stored.
-- Anyone on the same server can access the view.
-- The view persists until you explicitly DROP it.
-- Killing or closing your session does NOT remove the view.
--
-- Why use views?
-- 1. Data Abstraction -- hide original table names and column names using aliases.
--    Users see only what you expose. They cannot see the original tables inside.
-- 2. Security -- give users access to only the columns they need.
--    No need to expose the full table. Grant access to the view, not the base table.
-- 3. Simplify complex queries -- wrap a complex JOIN + GROUP BY into a named view.
--    Others just run SELECT * FROM view_name without knowing the inner logic.
-- 4. Share outside -- views can be connected to Power BI, Tableau, web apps.
--    The external tool just queries the view and never sees the underlying tables.
--
-- Important: VIEW contains only the QUERY, not the data.
-- Real-world analogy: an ATM machine. You enter your PIN and get money.
-- You never see what is running behind the screen. The view works the same way.
-- The user sees column names you gave them. They never know the original structure.

-- ─────────────────────────────────────────────────────────────
-- 2.1 Create a basic view
-- ─────────────────────────────────────────────────────────────

-- Drop if already exists
DROP VIEW IF EXISTS sakila.recent_rentals;

-- Create the view -- only the query gets stored, not the data
CREATE VIEW sakila.recent_rentals AS
SELECT customer_id,
       MAX(rental_date) AS last_rental_date
FROM sakila.rental
GROUP BY customer_id;

-- Query the view -- this re-executes the stored query and returns fresh data
SELECT * FROM sakila.recent_rentals;
SELECT * FROM sakila.recent_rentals WHERE customer_id = 1;

-- ─────────────────────────────────────────────────────────────
-- 2.2 View with data abstraction (column aliasing)
-- ─────────────────────────────────────────────────────────────
-- The original column is rental_date. We expose it as ruchick.
-- The user accessing the view sees recheck. They never know the original name.
-- This is DATA ABSTRACTION -- protecting original column names under the view.

DROP VIEW IF EXISTS sakila.customer_last_visit;

CREATE VIEW sakila.customer_last_visit AS
SELECT customer_id,
       MAX(rental_date) AS ruchick   -- aliased -- hides original column name
FROM sakila.rental
GROUP BY customer_id;

SELECT * FROM sakila.customer_last_visit LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 2.3 View with limited columns (security use case)
-- ─────────────────────────────────────────────────────────────
-- The customer table has many columns including sensitive ones.
-- We create a view that exposes only the safe columns.
-- Grant users access to this view only -- they never touch the base table.

DROP VIEW IF EXISTS sakila.public_customer_info;

CREATE VIEW sakila.public_customer_info AS
SELECT customer_id,
       first_name,
       last_name,
       email
FROM sakila.customer
WHERE active = 1;

SELECT * FROM sakila.public_customer_info LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- 2.4 Drop a view
-- ─────────────────────────────────────────────────────────────
-- DROP VIEW removes it from the database permanently.
-- Anyone who was using the view will lose access after this.

DROP VIEW IF EXISTS sakila.recent_rentals;

-- ─────────────────────────────────────────────────────────────
-- 2.5 Generic view example 
-- ─────────────────────────────────────────────────────────────
CREATE VIEW employee_view AS
SELECT id, name, department
FROM employees
WHERE active = 1;


-- =============================================================================
-- 3. STORED PROCEDURES
-- =============================================================================
-- A stored procedure is a saved block of SQL code stored physically in the database.
-- Think of it like writing a function in Python or Java and saving it in the database.
-- Write it once. Call it multiple times with different parameters.
-- Unlike views which only store a SELECT query, stored procedures can contain
-- INSERT, UPDATE, DELETE, loops, conditions and complex logic.
--
-- Why use stored procedures?
-- - Reusability: write once, call many times with different inputs
-- - Performance: execution plan is pre-compiled and cached by the database
-- - Security: users call the procedure without needing direct table access.
--   They pass in a parameter. The procedure fetches only what it is allowed to.
-- - Reduced network traffic: one CALL executes multiple SQL statements inside
-- - Real-world use: login validation, medical records lookup, payment processing
--
-- DELIMITER //
-- The DELIMITER tells MySQL that // is the new statement-ending symbol.
-- This is needed because the procedure body contains semicolons.
-- Without changing the delimiter, MySQL would think the first ; inside
-- BEGIN...END ends the entire statement -- which would break the procedure.
-- After the procedure is created we reset delimiter back to ;

-- ─────────────────────────────────────────────────────────────
-- 3.1 Basic stored procedure (no parameters)
-- ─────────────────────────────────────────────────────────────

DROP PROCEDURE IF EXISTS GetCustomerPayments;

DELIMITER //
CREATE PROCEDURE GetCustomerPayments()
BEGIN
    SELECT customer_id, amount, payment_date
    FROM sakila.payment
    ORDER BY payment_date DESC
    LIMIT 20;
END //
DELIMITER ;

-- Call the procedure (no parameters needed)
CALL GetCustomerPayments();

-- ─────────────────────────────────────────────────────────────
-- 3.2 IN Parameter -- pass a value INTO the procedure
-- ─────────────────────────────────────────────────────────────
-- IN = input parameter. You pass a value when calling the procedure.
-- The procedure uses that value internally to filter or process data.
-- The caller decides the value. The procedure does not hardcode it.
--
-- Real-world example: user ID and password passed as IN parameters.
-- The procedure checks the database, validates credentials, returns result.
-- Medical records example: pass member ID as IN, get their records as output.

DROP PROCEDURE IF EXISTS GetPaymentsByCustomer;

DELIMITER //
CREATE PROCEDURE GetPaymentsByCustomer(IN c_id INT)
BEGIN
    SELECT payment_id, amount, payment_date
    FROM sakila.payment
    WHERE customer_id = c_id;
END //
DELIMITER ;

-- Call with customer_id = 5
CALL GetPaymentsByCustomer(5);

-- Call again with customer_id = 6 -- same procedure, different input, different result
CALL GetPaymentsByCustomer(6);

-- ─────────────────────────────────────────────────────────────
-- 3.3 OUT Parameter -- return a value FROM the procedure
-- ─────────────────────────────────────────────────────────────
-- OUT = output parameter. The procedure calculates something and stores the
-- result in a variable. You must SELECT that variable to see the result.
--
-- Real-world example: forgot username. Pass phone number as IN.
-- Procedure matches it to the row and returns username as OUT.
-- Or: pass customer ID, get total amount spent back as OUT.

DROP PROCEDURE IF EXISTS GetTotalAmountSpent;

DELIMITER //
CREATE PROCEDURE GetTotalAmountSpent(IN c_id INT, OUT total DECIMAL(10,2))
BEGIN
    SELECT SUM(amount) INTO total
    FROM sakila.payment
    WHERE customer_id = c_id;
END //
DELIMITER ;

-- Call the procedure -- @total is the output variable that receives the result
CALL GetTotalAmountSpent(5, @total);

-- Must SELECT the output variable to display it (it is stored in the variable)
SELECT @total AS total_amount_paid_by_customer_5;

-- Change input to customer 6
CALL GetTotalAmountSpent(6, @total);
SELECT @total AS total_amount_paid_by_customer_6;

-- ─────────────────────────────────────────────────────────────
-- 3.4 INOUT Parameter -- acts as both input and output
-- ─────────────────────────────────────────────────────────────
-- INOUT = the same variable is passed in AND the result is stored back into it.
-- You pass a value in. The procedure modifies it. You get the modified value back.
-- Useful when you want to pass a starting value and get back a transformed result.
--
-- Real-world example: pass total expenditure from one function as input,
-- calculate credits minus debits, store result back into same variable,
-- pass that result into the next function for further processing.

DROP PROCEDURE IF EXISTS IncreaseValue;

DELIMITER //
CREATE PROCEDURE IncreaseValue(INOUT num INT)
BEGIN
    SET num = num + 10;
END //
DELIMITER ;

-- Set the starting value
SET @mynum = 5;
CALL IncreaseValue(@mynum);
SELECT @mynum AS result_after_increase;  -- outputs 15

-- ─────────────────────────────────────────────────────────────
-- 3.5 Multiple parameters
-- ─────────────────────────────────────────────────────────────
-- You can have multiple IN, OUT or INOUT parameters separated by commas.
-- Each parameter has: direction (IN/OUT/INOUT), name, and data type.

DROP PROCEDURE IF EXISTS GetFilmsByRating;

DELIMITER //
CREATE PROCEDURE GetFilmsByRating(IN film_rating VARCHAR(10), IN max_rows INT)
BEGIN
    SELECT film_id, title, rental_rate, length
    FROM sakila.film
    WHERE rating = film_rating
    ORDER BY rental_rate DESC
    LIMIT max_rows;
END //
DELIMITER ;

CALL GetFilmsByRating('PG', 10);
CALL GetFilmsByRating('R', 5);

-- ─────────────────────────────────────────────────────────────
-- 3.6 Stored procedure with abstraction
-- ─────────────────────────────────────────────────────────────
-- The user calling the procedure only passes a parameter.
-- They never see the payment table or any underlying tables inside.
-- They only get back what the procedure chooses to return.
-- This is the same abstraction concept as views but for procedures.

DROP PROCEDURE IF EXISTS GetEmployeeByDept;

DELIMITER //
CREATE PROCEDURE GetEmployeeByDept(IN dept_name VARCHAR(50))
BEGIN
    SELECT *
    FROM employees
    WHERE department = dept_name;
END //
DELIMITER ;

-- ─────────────────────────────────────────────────────────────
-- 3.7 Advantages and disadvantages
-- ─────────────────────────────────────────────────────────────
-- Advantages:
--   1. REUSABILITY     -> write once, call many times with different parameters
--   2. PERFORMANCE     -> execution plan is pre-compiled and can be cached
--   3. SECURITY        -> users call the procedure, not the base table directly
--   4. NETWORK TRAFFIC -> one CALL executes many statements instead of many round trips
--
-- Disadvantages:
--   - Harder to debug than regular SQL
--   - Syntax is database-specific (MySQL procedures won't work on PostgreSQL)
--   - Complex logic inside procedures becomes hard to maintain over time


-- =============================================================================
-- 4. DYNAMIC STORED PROCEDURES
-- =============================================================================
-- A regular stored procedure has a fixed SQL query inside it.
-- The query is written once and stays the same. Only the parameter values change.
--
-- A DYNAMIC stored procedure generates the SQL query itself at runtime.
-- The query does not exist when the procedure is created.
-- It is BUILT as a string inside the procedure using the input parameter.
-- Then it is executed using PREPARE / EXECUTE / DEALLOCATE.
--
-- When to use dynamic stored procedures:
-- - Table names are dynamic (passed as a parameter)
-- - Column names change depending on input
-- - Optional filter conditions that vary at runtime
-- - ETL pipelines where you need to query all tables in a database
-- - Copying or validating data from one database to another
--
-- Key commands inside dynamic stored procedures:
--   SET @sql = CONCAT(...)  -> build the SQL query as a string
--   PREPARE stmt FROM @sql  -> parse/prepare the SQL string
--   EXECUTE stmt            -> run the prepared SQL
--   DEALLOCATE PREPARE stmt -> free up memory after execution

-- ─────────────────────────────────────────────────────────────
-- 4.1 Dynamic query using table name as parameter
-- ─────────────────────────────────────────────────────────────
-- Pass any table name. The procedure builds and runs a COUNT query for that table.
-- Example: pass 'sakila.actor' -> returns 200. Pass 'sakila.city' -> returns 600.
-- The SQL query itself is not hardcoded -- it is constructed from the input.

DROP PROCEDURE IF EXISTS sakila.DynamicQuery;

DELIMITER //
CREATE PROCEDURE sakila.DynamicQuery(IN tbl_name VARCHAR(64))
BEGIN
    SET @s = CONCAT('SELECT COUNT(*) AS total_rows FROM ', tbl_name);
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

CALL sakila.DynamicQuery('sakila.actor');    -- returns 200
CALL sakila.DynamicQuery('sakila.city');     -- returns 600
CALL sakila.DynamicQuery('sakila.payment');  -- returns count of payments

-- ─────────────────────────────────────────────────────────────
-- 4.2 Dynamic procedure using INFORMATION_SCHEMA + Cursor
-- ─────────────────────────────────────────────────────────────
-- More advanced: pass a database name. The procedure fetches ALL table names
-- from information_schema, iterates over them one by one using a CURSOR,
-- builds a SELECT query for each table, and inserts all generated queries
-- into a temporary table. Used in ETL pipelines to validate or copy data.
--
-- CURSOR = a mechanism to loop through query results row by row.
-- Like a for loop in Python that reads one row at a time.
-- Steps: DECLARE cursor -> OPEN cursor -> FETCH row -> process -> CLOSE cursor
--
-- Workflow (from class demo):
-- 1. Create a temp table to store the generated SQL queries
-- 2. Create stored procedure that takes a database name as IN parameter
-- 3. Inside procedure: select all table names from information_schema
-- 4. Open cursor, start loop -> for each table:
--    a. Build a SELECT query as a string
--    b. Insert that query string into the temp table
-- 5. End the loop
-- 6. End the procedure
-- Then a second procedure can execute all those stored queries one by one.

DROP TEMPORARY TABLE IF EXISTS select_statements;

CREATE TEMPORARY TABLE select_statements (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    query_txt TEXT
);

DROP PROCEDURE IF EXISTS sakila.GenerateSelectStatements;

DELIMITER //
CREATE PROCEDURE sakila.GenerateSelectStatements(IN db_name VARCHAR(64))
BEGIN
    DECLARE tbl_name VARCHAR(64);
    DECLARE done      INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = db_name;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO tbl_name;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Build a dynamic SELECT query for each table
        SET @dyn_sql = CONCAT('SELECT * FROM ', db_name, '.', tbl_name);

        -- Insert the generated query into our temp table
        SET @insert_sql = CONCAT(
            'INSERT INTO select_statements (query_txt) VALUES (''',
            @dyn_sql, ''')'
        );
        PREPARE ins_stmt FROM @insert_sql;
        EXECUTE ins_stmt;
        DEALLOCATE PREPARE ins_stmt;

    END LOOP;

    CLOSE cur;

    -- Show all generated queries
    SELECT * FROM select_statements;
END //
DELIMITER ;

-- Call it -- pass any database name to generate SELECT queries for all its tables
CALL sakila.GenerateSelectStatements('sakila');
-- Call with a different database
-- CALL sakila.GenerateSelectStatements('joins');


-- =============================================================================
-- 5. SCOPE COMPARISON -- COMPLETE EVOLUTION LADDER
-- =============================================================================
-- This is the full picture of how SQL evolved from subqueries to views.
-- Each step was created to solve the limitation of the previous one.
--
-- SUBQUERY
--   Scope: query execution level only
--   Lives inside one query. Once executed, gone.
--   Hard to read when deeply nested. Not reusable.
--
-- CTE (Common Table Expression)
--   Scope: query execution level
--   Named and readable. Reusable within the same query.
--   Still gone after that one execution. Cannot use in a separate query.
--   Must always run the WITH block and the main SELECT together.
--
-- TEMPORARY TABLE
--   Scope: session level
--   Runs the query ONCE, stores actual data in memory.
--   Reusable across multiple separate queries within the same session.
--   Only YOU can see it. Other users on the same server cannot access it.
--   Gone when session ends or when explicitly dropped.
--
-- VIEW
--   Scope: global / database level
--   Stores only the query (not data). Re-executes fresh every time called.
--   Persists permanently until explicitly dropped with DROP VIEW.
--   Anyone on the same server can access it.
--   Can be shared with Power BI, Tableau, web applications.
--   Provides data abstraction and security (hides original tables and columns).
--
-- Summary:
--   Subquery -> CTE -> Temp Table -> View
--   Each one extends the scope and reusability of the previous.



