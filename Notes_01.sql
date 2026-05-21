-- =============================================================================
-- LECTURE 01 - SQL FUNDAMENTALS
-- Course  : Data Science & SQL Bootcamp
-- Date    : 19 May 2026
-- Topic   : SQL Architecture, Command Types, Constraints, Keys, Normalization
-- Note    : Lecture 00 was intro/overview only. This is Lecture 01.
-- =============================================================================


-- =============================================================================
-- 1. SQL ARCHITECTURE - SERVER, WORKBENCH, DATABASE
-- =============================================================================
-- Three things were installed before this session:
--   1. MySQL Server
--   2. MySQL Workbench
--   3. Database (Circular/SKIL database)
--
-- SQL SERVER
--   - Stores all data locally on your machine
--   - Databases are created ON TOP of the server
--   - Server is like the space/memory where databases live
--   - One server can hold multiple databases at the same time
--   - You can communicate with server directly via CMD (command line)
--
-- WORKBENCH
--   - A UI (graphical interface) that sits on top of the server
--   - Acts as the communication layer between the USER and the SERVER
--   - Used to: write queries, create tables, insert data, fetch data
--   - MySQL Workbench is for MySQL. Each DB has its own UI:
--       MySQL      -> MySQL Workbench
--       SQL Server -> SSMS (SQL Server Management Studio)
--       PostgreSQL -> pgAdmin
--
-- DATABASE
--   - Created on the server
--   - Holds all tables, views, stored procedures, and functions
--   - Example: instructor had 3 databases on one server:
--       "joints", "circular database" (imported), "system" (default)
--
-- HOW THEY CONNECT:
--   User -> Workbench -> Server -> Database -> Tables -> Data


-- =============================================================================
-- 2. SCHEMA
-- =============================================================================
-- Schema = the BLUEPRINT of how data is stored in a database
--
-- Schema defines:
--   - Column names
--   - Data types for each column
--   - Constraints on columns
--
-- A database has MULTIPLE schema types:
--   - Tables schema      -> contains: columns, indexes, primary keys, foreign keys
--   - Views schema       -> virtual tables based on SELECT queries
--   - Stored Procedures  -> saved SQL logic that can be reused
--   - Functions          -> reusable SQL functions
--
-- Example: Creating a table = defining its schema
--   CREATE TABLE test_table (
--       id   INT,
--       name VARCHAR(255)
--   );
--   -> id column stores integers, name column stores text (variable characters)
--
-- VARCHAR = Variable Character
--   - Accepts both text AND integer values
--   - CHAR (without VAR) = only character/text data, rejects integers


-- =============================================================================
-- 3. SQL - STRUCTURED QUERY LANGUAGE
-- =============================================================================
-- SQL is the language used to interact with the database.
-- Used to: create tables, insert data, fetch data, manipulate data.
--
-- SQL commands are grouped into 5 categories:
--
--   DDL  -  Data Definition Language
--   DML  -  Data Manipulation Language
--   DQL  -  Data Query Language
--   DCL  -  Data Control Language
--   TCL  -  Transaction Control Language
--
-- Main focus in this course: DDL, DML, DQL


-- =============================================================================
-- 4. SQL COMMAND CATEGORIES (DDL, DML, DQL, DCL, TCL)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4.1 DDL - DATA DEFINITION LANGUAGE
-- -----------------------------------------------------------------------------
-- Purpose: Define or MODIFY the STRUCTURE of the database (schema level)
-- You are defining HOW data should be stored, not the data itself.
--
-- Commands:
--   CREATE   -> create a new database or table
--   ALTER    -> modify existing table (add column, rename column, add constraint)
--   DROP     -> permanently delete a table or database (structure + data)
--   TRUNCATE -> delete all rows in a table but keep the schema/structure
--   RENAME   -> rename a column or table

-- -----------------------------------------------------------------------------
-- 4.2 DML - DATA MANIPULATION LANGUAGE
-- -----------------------------------------------------------------------------
-- Purpose: Manipulate the DATA inside tables (row level, not structure)
--
-- Commands:
--   INSERT -> add new rows of data into a table
--   UPDATE -> modify existing data in specific rows
--   DELETE -> remove specific rows using a WHERE condition

-- -----------------------------------------------------------------------------
-- 4.3 DQL - DATA QUERY LANGUAGE
-- -----------------------------------------------------------------------------
-- Purpose: RETRIEVE / QUERY data from tables
-- Commands: SELECT (the only command under DQL)

-- -----------------------------------------------------------------------------
-- 4.4 DCL - DATA CONTROL LANGUAGE
-- -----------------------------------------------------------------------------
-- Purpose: Control ACCESS and PERMISSIONS on database objects
--   Who can read? Who can write? Who can drop a table?
-- Commands: GRANT (give access), REVOKE (remove access)

-- -----------------------------------------------------------------------------
-- 4.5 TCL - TRANSACTION CONTROL LANGUAGE
-- -----------------------------------------------------------------------------
-- Purpose: Manage TRANSACTIONS to maintain data integrity
-- Real-world example: money transfer (debit from one account, credit to another)
--   Both operations must succeed together or both must fail - no in-between.
--
-- Commands:
--   COMMIT    -> save/confirm changes permanently so others can see them
--   ROLLBACK  -> undo changes and go back to the previous saved state
--   SAVEPOINT -> bookmark a point mid-transaction to rollback to if needed
--
-- Use case:
--   If someone is reading the table while you are updating it,
--   COMMIT ensures they see your changes only after you confirm them.
--   ROLLBACK undoes a bad update/deployment before it gets committed.


-- =============================================================================
-- 5. CONSTRAINTS
-- =============================================================================
-- Constraints = RULES applied to columns to enforce data integrity
-- Defined when CREATING a table (or added later via ALTER TABLE)
-- If a constraint is violated, the database throws an error and rejects the row.
-- There are 6 constraints:

-- 5.1 NOT NULL
--   The column CANNOT have a null/empty value. A value is always required on insert.
--   Trying to insert NULL for last_name -> ERROR: last_name cannot be null

-- 5.2 UNIQUE
--   Every value in the column must be DIFFERENT. No duplicates allowed.
--   Trying to insert id=1 twice -> ERROR: Duplicate entry '1' for key 'persons'

-- 5.3 PRIMARY KEY
--   Uniquely identifies EACH ROW in the table.
--   PRIMARY KEY already means UNIQUE + NOT NULL combined (both rules in one).
--   Note: adding UNIQUE separately on a PRIMARY KEY column is redundant,
--   but not wrong - just extra (done in class for learning purposes).
--   Only ONE primary key allowed per table.
--   The table with the primary key = PARENT TABLE = REFERENCED TABLE
--
--   Ways to create a primary key:
--     Option 1 - inline during CREATE TABLE:   id INT PRIMARY KEY
--     Option 2 - ALTER TABLE:                  ALTER TABLE t ADD PRIMARY KEY (id);
--     Option 3 - named constraint:             ALTER TABLE t ADD CONSTRAINT pk_t PRIMARY KEY (id);
--     Giving a name (pk_person) stores it in metadata so you can query it later.

-- 5.4 FOREIGN KEY
--   Links a column in one table to the PRIMARY KEY in another table.
--   Establishes a PARENT-CHILD relationship between tables.
--   Enforces REFERENTIAL INTEGRITY:
--     -> child table cannot have a FK value that does not exist in the parent.
--   The table with the foreign key = CHILD TABLE = REFERENCING TABLE
--
--   ON DELETE RESTRICT:
--     -> Blocks deletion of a parent row if child rows still reference it.
--     -> Must delete child rows first, then delete the parent.
--     -> Error: "Cannot delete or update a parent row: foreign key constraint fails"
--
--   ON UPDATE CASCADE:
--     -> When the parent primary key changes, the FK in child auto-updates.
--     -> Example: persons.id changes 1 -> 10, orders.person_id also becomes 10.
--     -> Both tables stay consistent automatically.

-- 5.5 CHECK
--   Enforces a specific CONDITION on a column.
--   Example: age INT CHECK (age >= 18)
--   Inserting age = 17 -> ERROR: Check constraint violated
--   Inserting age = 18+ -> SUCCESS

-- 5.6 DEFAULT
--   Assigns a FALLBACK VALUE automatically if no value is given on insert.
--   Example: country VARCHAR(50) DEFAULT 'India'
--   Inserting a row without specifying country -> country = 'India' automatically


-- =============================================================================
-- 6. DDL COMMANDS - PRACTICAL
-- =============================================================================

-- Create and select the working database
CREATE DATABASE company_db;
USE company_db;

-- Create a departments table with basic columns
CREATE TABLE departments (
    dept_id   INT,
    dept_name VARCHAR(50)
);

-- Create an employees table with basic columns
CREATE TABLE employees (
    emp_id   INT,
    emp_name VARCHAR(100),
    salary   DECIMAL(10,2),
    dept_id  INT
);

-- DESC: Check a table's structure (column names, data types, constraints)
-- Very useful to verify your table was created correctly
DESC departments;
DESC employees;

-- Add a new column to an existing table
-- Existing rows will have NULL for this new column (no data was given for them)
ALTER TABLE employees ADD Email VARCHAR(250);

-- Rename a column
-- ALTER TABLE employees RENAME COLUMN Email TO email_id;

-- Drop a table only if it exists (safer than DROP TABLE alone)
-- DROP TABLE IF EXISTS persons;


-- =============================================================================
-- 7. DML COMMANDS - PRACTICAL
-- =============================================================================

-- INSERT INTO departments
INSERT INTO departments (dept_id, dept_name) VALUES (1, 'IT');
INSERT INTO departments (dept_id, dept_name) VALUES (2, 'HR');
INSERT INTO departments (dept_id, dept_name) VALUES (3, 'Finance');
INSERT INTO departments (dept_id, dept_name) VALUES (4, 'Help Desk');

-- INSERT INTO employees
INSERT INTO employees (emp_id, emp_name, salary, dept_id) VALUES (101, 'Sara',  60000.00, 1);
INSERT INTO employees (emp_id, emp_name, salary, dept_id) VALUES (102, 'Abhi',  40000.18, 4);
INSERT INTO employees (emp_id, emp_name, salary, dept_id) VALUES (103, 'Max',   85000.00, 2);
INSERT INTO employees (emp_id, emp_name, salary, dept_id) VALUES (104, 'Rio',   30000.00, 3);
INSERT INTO employees (emp_id, emp_name, salary, dept_id) VALUES (105, 'Leo',   58000.00, 1);

-- View all inserted data
SELECT * FROM departments;
SELECT * FROM employees;

-- UPDATE salary of a specific employee
-- LIMIT 1 avoids MySQL safe update mode error (Error Code 1175):
-- "You are using safe update mode and tried to update without a WHERE on a KEY column"
UPDATE employees
SET salary = 65000.00
WHERE emp_id = 101
LIMIT 1;

-- UPDATE the email column for each employee (added via ALTER TABLE above)
UPDATE employees SET Email = 'sara@exp.com' WHERE emp_id = 101 LIMIT 1;
UPDATE employees SET Email = 'abhi@exp.com' WHERE emp_id = 102 LIMIT 1;
UPDATE employees SET Email = 'max@exp.com'  WHERE emp_id = 103 LIMIT 1;
UPDATE employees SET Email = 'rio@exp.com'  WHERE emp_id = 104 LIMIT 1;
UPDATE employees SET Email = 'leo@exp.com'  WHERE emp_id = 105 LIMIT 1;

-- Verify updated data
SELECT * FROM employees;


-- =============================================================================
-- 8. DQL COMMANDS - PRACTICAL (SELECT)
-- =============================================================================

-- Show all data from both tables
SELECT * FROM departments;
SELECT * FROM employees;

-- Show only selected columns
SELECT emp_name, salary FROM employees;

-- Filter rows: employees in dept_id = 1 only
SELECT emp_name, Email FROM employees WHERE dept_id = 1;

-- Sort employees by salary from highest to lowest
SELECT * FROM employees ORDER BY salary DESC;


-- =============================================================================
-- 9. CONSTRAINTS - PRACTICAL EXAMPLES
-- =============================================================================

-- ─────────────────────────────────────────────────────────────
-- 9.1 NOT NULL + UNIQUE
-- ─────────────────────────────────────────────────────────────
CREATE TABLE persons (
    person_id   INT          UNIQUE,
    person_name VARCHAR(50)  NOT NULL,
    email       VARCHAR(100),
    age         INT
);

INSERT INTO persons VALUES (1, 'Ravi',  'ravi@example.com',  25);  -- SUCCESS
INSERT INTO persons VALUES (2, 'Sneha', 'sneha@example.com', 28);  -- SUCCESS

-- This will NOT execute: person_name cannot be NULL
INSERT INTO persons VALUES (3, NULL, 'test@example.com', 30);

-- This will NOT execute: person_id must be UNIQUE (2 already exists)
INSERT INTO persons VALUES (2, 'Arjun', 'arjun@example.com', 32);

SELECT * FROM persons;

-- ─────────────────────────────────────────────────────────────
-- 9.2 CHECK + DEFAULT
-- ─────────────────────────────────────────────────────────────

-- Drop and recreate persons table with CHECK and DEFAULT constraints
DROP TABLE IF EXISTS persons;

CREATE TABLE persons (
    person_id   INT,
    person_name VARCHAR(50) NOT NULL,
    country     VARCHAR(50) DEFAULT 'India',  -- auto-fills 'India' if not provided
    age         INT         CHECK (age >= 18) -- rejects any age below 18
);

-- country not given -> DEFAULT 'India' is used automatically
INSERT INTO persons (person_id, person_name, age) VALUES (1, 'Ravi',  25);  -- SUCCESS

-- country given explicitly -> overrides the default
INSERT INTO persons VALUES (2, 'Sneha', 'USA', 30);                         -- SUCCESS

-- country not given -> DEFAULT 'India' again
INSERT INTO persons (person_id, person_name, age) VALUES (3, 'Arjun', 40);  -- SUCCESS

-- This will NOT execute: age 15 violates CHECK (age >= 18)
INSERT INTO persons VALUES (4, 'Kiran', 'India', 15);

-- This will NOT execute: person_name cannot be NULL
INSERT INTO persons VALUES (5, NULL, 'India', 28);

SELECT * FROM persons;

-- ─────────────────────────────────────────────────────────────
-- 9.3 PRIMARY KEY + FOREIGN KEY
-- ─────────────────────────────────────────────────────────────
-- Parent table = persons (holds the PRIMARY KEY)
-- Child table  = orders  (holds the FOREIGN KEY, references persons)

DROP TABLE IF EXISTS persons;

CREATE TABLE persons (
    -- PRIMARY KEY already means UNIQUE + NOT NULL
    -- Adding UNIQUE here is redundant but not wrong (done for learning)
    person_id   INT         PRIMARY KEY UNIQUE,
    person_name VARCHAR(50) NOT NULL,
    email       VARCHAR(100)
);

-- orders depends on persons (child table)
-- person_id in orders must match a person_id that exists in persons
CREATE TABLE orders (
    order_id   INT         PRIMARY KEY,
    order_name VARCHAR(50),
    person_id  INT,
    FOREIGN KEY (person_id) REFERENCES persons(person_id)
        ON DELETE RESTRICT   -- block delete of parent if child rows exist
        ON UPDATE CASCADE    -- auto-update child FK when parent PK changes
);

-- Insert into parent (persons) first
INSERT INTO persons VALUES (1, 'Ravi',  'ravi@example.com');
INSERT INTO persons VALUES (2, 'Sneha', 'sneha@example.com');
INSERT INTO persons VALUES (3, 'Arjun', 'arjun@example.com');

-- This will NOT execute: person_id 1 already exists (PRIMARY KEY = UNIQUE)
INSERT INTO persons VALUES (1, 'Duplicate Ravi', 'duplicate@example.com');

-- Insert into child (orders) table
INSERT INTO orders VALUES (101, 'Laptop',  1);
INSERT INTO orders VALUES (102, 'Phone',   2);
INSERT INTO orders VALUES (103, 'Tablet',  1);
INSERT INTO orders VALUES (104, 'Monitor', 3);

-- This will NOT execute: person_id 5 does not exist in persons table (FK violation)
INSERT INTO orders VALUES (105, 'Keyboard', 5);

-- This will NOT execute: order_id 101 already exists (PRIMARY KEY = UNIQUE)
INSERT INTO orders VALUES (101, 'Mouse', 2);

-- View all data
SELECT * FROM persons;
SELECT * FROM orders;

-- See which orders belong to Ravi (person_id = 1)
SELECT * FROM orders WHERE person_id = 1;


-- =============================================================================
-- 10. ON DELETE RESTRICT - DEMO
-- =============================================================================
-- Ravi (person_id=1) has orders -> cannot delete him directly

-- This will NOT execute: child rows still reference person_id=1
DELETE FROM persons WHERE person_id = 1;

-- To delete Ravi correctly:
-- Step 1: delete his child rows in orders first
DELETE FROM orders WHERE person_id = 1;

-- Step 2: now delete from parent (no child rows left referencing him)
DELETE FROM persons WHERE person_id = 1;

SELECT * FROM persons;  -- Ravi is gone
SELECT * FROM orders;   -- Ravi's orders are gone too


-- =============================================================================
-- 11. ON UPDATE CASCADE - DEMO
-- =============================================================================
-- Before update
SELECT * FROM persons;
SELECT * FROM orders;

-- Change Sneha's person_id from 2 -> 10
-- CASCADE will automatically update orders.person_id from 2 -> 10 as well
UPDATE persons SET person_id = 10 WHERE person_id = 2;

-- Check: Sneha's id is now 10 in BOTH tables
SELECT * FROM persons;
SELECT * FROM orders;  -- person_id is 10 here too, updated automatically


-- =============================================================================
-- 12. DROP vs DELETE vs TRUNCATE
-- =============================================================================
-- All three remove data but work very differently.

-- DELETE: removes selected rows using WHERE. Table structure stays. Can rollback.
DELETE FROM employees WHERE emp_id = 102 LIMIT 1;

-- TRUNCATE: removes ALL rows instantly. No WHERE clause. No rollback. Table stays.
-- Faster than DELETE when clearing all rows.
TRUNCATE TABLE employees;

-- DROP: removes the ENTIRE TABLE including structure, data, and constraints.
-- No rollback. Table no longer exists after this.
DROP TABLE employees;

-- After DROP: this query will fail because the table no longer exists
-- SELECT * FROM employees;   -- ERROR: Table 'company_db.employees' doesn't exist

-- COMPARISON:
-- Command  | What it removes       | Schema kept? | WHERE clause? | Rollback?
-- ---------|----------------------|--------------|---------------|----------
-- DELETE   | Specific rows only    | Yes          | Yes (needed)  | Yes
-- TRUNCATE | All rows              | Yes          | No            | No
-- DROP     | Entire table          | No           | No            | No
--
-- IMPORTANT: Cannot DROP a parent table if a child table still references it.
-- -> ERROR: "Cannot drop table 'persons', referenced by foreign key constraint"
-- -> Solution: DROP child table first (orders), then drop parent (persons).


-- =============================================================================
-- 13. NORMALIZATION & DENORMALIZATION
-- =============================================================================
-- WHY SPLIT DATA INTO MULTIPLE TABLES?
--   If all columns are in one big table with 20-30 columns and huge data,
--   even a small query has to scan all of it -> slow and expensive.
--   Splitting into smaller related tables = NORMALIZATION.
--
-- NORMALIZATION
--   - Splitting data into multiple related tables to reduce REDUNDANCY
--   - Each fact is stored in only ONE place (no duplication)
--   - Tables linked using primary key and foreign key relationships
--   - Maintains data integrity throughout the database
--   - Used in OLTP (Online Transaction Processing / transactional) systems
--   - Normalization forms (not in depth yet):
--       1NF: no multiple values in a single cell/row
--       2NF: no partial dependency on a composite primary key
--       3NF: no dependency between non-primary key columns
--
-- DENORMALIZATION
--   - Combining tables into fewer, wider tables
--   - Accepts some redundancy in exchange for FASTER reads (fewer joins needed)
--   - Used in data marts and data warehouses (analytics / reporting)
--
-- Class example:
--   persons table -> person_id, person_name, email
--   orders table  -> order_id, order_name, person_id (FK -> persons)
--   (Instead of cramming name, mobile, email, orders all into one giant table)


-- =============================================================================
-- 14. METADATA & INFORMATION_SCHEMA
-- =============================================================================
-- METADATA = data about data
--   - Example: taking a photo. The photo = actual data.
--     Metadata = timestamp, GPS location, resolution, file size.
--   - In SQL: the rows/values = data. Metadata = info about the table structure.
--
-- INFORMATION_SCHEMA
--   - A built-in system schema automatically created with every database
--   - Stores metadata: table names, column names, data types, constraints
--
-- Query to find all constraints on a specific table:
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'company_db'
  AND table_name   = 'persons';
-- Returns: something like  pk_person | PRIMARY KEY

-- Query to list all columns in a table:
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'company_db'
  AND table_name   = 'persons';


-- =============================================================================
-- 15. COMPLETE SYNTAX REFERENCE
-- =============================================================================

-- CREATE DATABASE and USE:
--   CREATE DATABASE company_db;
--   USE company_db;

-- DESC - check table structure:
--   DESC table_name;

-- CREATE TABLE (basic):
--   CREATE TABLE employees (
--       emp_id   INT,
--       emp_name VARCHAR(100),
--       salary   DECIMAL(10,2),
--       dept_id  INT
--   );

-- CREATE TABLE with all constraints:
--   CREATE TABLE persons (
--       person_id   INT         PRIMARY KEY,
--       person_name VARCHAR(50) NOT NULL,
--       country     VARCHAR(50) DEFAULT 'India',
--       age         INT         CHECK (age >= 18)
--   );

-- CREATE TABLE with FOREIGN KEY:
--   CREATE TABLE orders (
--       order_id   INT PRIMARY KEY,
--       order_name VARCHAR(50),
--       person_id  INT,
--       FOREIGN KEY (person_id) REFERENCES persons(person_id)
--           ON DELETE RESTRICT
--           ON UPDATE CASCADE
--   );

-- INSERT rows:
--   INSERT INTO departments (dept_id, dept_name) VALUES (1, 'IT');

-- UPDATE with LIMIT (avoids MySQL safe update mode Error 1175):
--   UPDATE employees SET salary = 65000 WHERE emp_id = 101 LIMIT 1;

-- SELECT queries:
--   SELECT * FROM employees;
--   SELECT emp_name, salary FROM employees;
--   SELECT * FROM employees WHERE dept_id = 1;
--   SELECT * FROM employees ORDER BY salary DESC;

-- ALTER TABLE - add column:
--   ALTER TABLE employees ADD Email VARCHAR(250);

-- ALTER TABLE - rename column:
--   ALTER TABLE employees RENAME COLUMN Email TO email_id;

-- ALTER TABLE - add named primary key:
--   ALTER TABLE persons ADD CONSTRAINT pk_person PRIMARY KEY (person_id);

-- ALTER TABLE - drop primary key:
--   ALTER TABLE persons DROP PRIMARY KEY;

-- DELETE specific row (safe update friendly):
--   DELETE FROM employees WHERE emp_id = 102 LIMIT 1;

-- TRUNCATE (all rows gone, table stays):
--   TRUNCATE TABLE employees;

-- DROP TABLE (table gone entirely):
--   DROP TABLE IF EXISTS employees;
--   DROP TABLE orders;    -- drop child first
--   DROP TABLE persons;   -- then drop parent

-- DROP DATABASE:
--   DROP DATABASE company_db;


-- =============================================================================
-- 16. OTHER NOTES FROM CLASS
-- =============================================================================
-- - Information Schema = Metadata = data about data
--   Describes the structure, properties, and info about your actual tables.
-- - We use MULTIPLE TABLES to ensure normalization and maintain granularity.
-- - MySQL safe update mode throws Error 1175 if you UPDATE/DELETE without
--   a WHERE clause on a KEY column. Use LIMIT 1 to safely bypass it.
-- - PRIMARY KEY already includes UNIQUE + NOT NULL.
--   Adding UNIQUE explicitly on a PK column is extra but not harmful.