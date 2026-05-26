USE sakila;

-- 1. Identify if there are duplicates in Customer table. Don't use customer id to check the duplicates
SELECT first_name, last_name, email, COUNT(*) AS duplicate_count
FROM customer
GROUP BY first_name, last_name, email
HAVING COUNT(*) > 1;

-- 2. Number of times letter 'a' is repeated in film descriptions
SELECT SUM(
    LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'a', ''))
) AS total_a_count
FROM film;

-- 3. Number of times each vowel is repeated in film descriptions
SELECT 
    SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'a', ''))) AS a_count,
    SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'e', ''))) AS e_count,
    SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'i', ''))) AS i_count,
    SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'o', ''))) AS o_count,
    SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'u', ''))) AS u_count
FROM film;

-- 4.1 Display the payments made by each customer Month wise
SELECT customer_id,
       MONTH(payment_date) AS payment_month,
       SUM(amount) AS total_amount
FROM payment
GROUP BY customer_id, MONTH(payment_date)
ORDER BY customer_id;

-- 4.2 Display the payments made by each customer Year wise
SELECT customer_id,
       YEAR(payment_date) AS payment_year,
       SUM(amount) AS total_amount
FROM payment
GROUP BY customer_id, YEAR(payment_date)
ORDER BY customer_id;

-- 4.3 Display the payments made by each customer Week wise
SELECT customer_id,
       WEEK(payment_date) AS payment_week,
       SUM(amount) AS total_amount
FROM payment
GROUP BY customer_id, WEEK(payment_date)
ORDER BY customer_id;

-- 5. Check if any given year is a leap year or not
SELECT 
CASE
    WHEN (2024 % 400 = 0) OR (2024 % 4 = 0 AND 2024 % 100 <> 0)
    THEN 'Leap Year'
    ELSE 'Not a Leap Year'
END AS leap_year_status;

-- 6. Display number of days remaining in the current year from today
SELECT DATEDIFF(
    CONCAT(YEAR(CURDATE()), '-12-31'),
    CURDATE()
) AS days_remaining;

-- 7. Display quarter number(Q1,Q2,Q3,Q4) for the payment dates from payment table
SELECT payment_id,
       payment_date,
       CONCAT('Q', QUARTER(payment_date)) AS quarter_number
FROM payment;

-- 8. Display the age in year, months, days based on your date of birth
SELECT 
    TIMESTAMPDIFF(YEAR, '2002-09-04', CURDATE()) AS years,
    TIMESTAMPDIFF(MONTH, '2002-09-04', CURDATE()) % 12 AS months,
    DATEDIFF(
        CURDATE(),
        DATE_ADD(
            DATE_ADD(
                '2002-09-04',
                INTERVAL TIMESTAMPDIFF(YEAR, '2002-09-04', CURDATE()) YEAR
            ),
            INTERVAL (TIMESTAMPDIFF(MONTH, '2002-09-04', CURDATE()) % 12) MONTH
        )
    ) AS days;
