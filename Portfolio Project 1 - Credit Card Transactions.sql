
-- SQL porfolio project.
-- download credit card transactions dataset from below link :
-- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
-- import the dataset in sql server with table name : credit_card_transcations
-- change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
-- (alternatively you can use the dataset present in zip file)
-- while importing make sure to change the data types of columns. by defualt it shows everything as varchar.

-- write 4-6 queries to explore the dataset and put your findings 

CREATE DATABASE credit_db;
USE credit_db;

SELECT * 
FROM credit_card_transactions;

-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
SELECT 
    city,
    SUM(amount) AS total_spent,
    (SUM(amount) / (SELECT SUM(amount) FROM credit_card_transactions) * 100) AS percentage_contribution
FROM 
    credit_card_transactions
GROUP BY 
    city
ORDER BY 
    total_spent DESC
LIMIT 5;

-- 2- write a query to print highest spend month and amount spent in that month for each card type
WITH MonthlySpends AS (
    SELECT 
        card_type,
        DATE_FORMAT(transaction_date, '%Y-%m') AS month,
        SUM(amount) AS total_spent
    FROM 
        credit_card_transactions
    GROUP BY 
        card_type, 
        DATE_FORMAT(transaction_date, '%Y-%m')
)
SELECT 
    ms.card_type,
    ms.month,
    ms.total_spent
FROM 
    MonthlySpends ms
INNER JOIN (
    SELECT 
        card_type,
        MAX(total_spent) AS max_spent
    FROM 
        MonthlySpends
    GROUP BY 
        card_type
) max_spends
ON 
    ms.card_type = max_spends.card_type AND ms.total_spent = max_spends.max_spent
ORDER BY 
    ms.card_type;

-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
WITH CumulativeSpends AS (
    SELECT 
        card_type,
        transaction_date,
        transaction_id,
        amount,
        SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date, transaction_id) AS cumulative_spent
    FROM 
        credit_card_transactions
)
SELECT * 
FROM CumulativeSpends
WHERE cumulative_spent >= 1000000
AND cumulative_spent - amount < 1000000;

-- 4- write a query to find city which had lowest percentage spend for gold card type
SELECT 
    city,
    SUM(amount) AS total_spent,
    (SUM(amount) / (SELECT SUM(amount) FROM credit_card_transactions WHERE card_type = 'Gold') * 100) AS percentage_contribution
FROM 
    credit_card_transactions
WHERE 
    card_type = 'Gold'
GROUP BY 
    city
ORDER BY 
    percentage_contribution ASC
LIMIT 1;

-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
WITH ExpenseSummary AS (
    SELECT 
        city,
        exp_type,
        SUM(amount) AS total_spent
    FROM 
        credit_card_transactions
    GROUP BY 
        city, 
        exp_type
),
MaxExpense AS (
    SELECT 
        city,
        MAX(total_spent) AS max_spent
    FROM 
        ExpenseSummary
    GROUP BY 
        city
),
MinExpense AS (
    SELECT 
        city,
        MIN(total_spent) AS min_spent
    FROM 
        ExpenseSummary
    GROUP BY 
        city
)
SELECT 
    e1.city,
    e1.exp_type AS highest_expense_type,
    e2.exp_type AS lowest_expense_type
FROM 
    ExpenseSummary e1
JOIN 
    ExpenseSummary e2 ON e1.city = e2.city
JOIN 
    MaxExpense me ON e1.city = me.city AND e1.total_spent = me.max_spent
JOIN 
    MinExpense mi ON e2.city = mi.city AND e2.total_spent = mi.min_spent;

-- 6- write a query to find percentage contribution of spends by females for each expense type
SELECT 
    exp_type,
    SUM(CASE WHEN gender = 'F' THEN amount ELSE 0 END) AS female_spent,
    (SUM(CASE WHEN gender = 'F' THEN amount ELSE 0 END) / SUM(amount) * 100) AS percentage_contribution
FROM 
    credit_card_transactions
GROUP BY 
    exp_type;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
WITH MonthlySpends AS (
    SELECT 
        card_type,
        exp_type,
        DATE_FORMAT(transaction_date, '%Y-%m') AS month,
        SUM(amount) AS total_spent
    FROM 
        credit_card_transactions
    GROUP BY 
        card_type, 
        exp_type, 
        DATE_FORMAT(transaction_date, '%Y-%m')
),
MoM_Growth AS (
    SELECT 
        card_type,
        exp_type,
        month,
        total_spent,
        LAG(total_spent, 1) OVER (PARTITION BY card_type, exp_type ORDER BY month) AS prev_month_spent
    FROM 
        MonthlySpends
)
SELECT 
    card_type,
    exp_type,
    month,
    ((total_spent - prev_month_spent) / prev_month_spent) * 100 AS growth_percentage
FROM 
    MoM_Growth
WHERE 
    month = '2014-01'
ORDER BY 
    growth_percentage DESC
LIMIT 1;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 
SELECT 
    city,
    SUM(amount) AS total_spent,
    COUNT(*) AS total_transactions,
    (SUM(amount) / COUNT(*)) AS spend_to_transaction_ratio
FROM 
    credit_card_transactions
WHERE 
    DAYOFWEEK(transaction_date) IN (1, 7)  -- 1 = Sunday, 7 = Saturday
GROUP BY 
    city
ORDER BY 
    spend_to_transaction_ratio DESC
LIMIT 1;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH CityTransactions AS (
    SELECT 
        city,
        transaction_date,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date) AS transaction_number
    FROM 
        credit_card_transactions
),
CityDaysTo500 AS (
    SELECT 
        city,
        MIN(transaction_date) AS start_date,
        MAX(CASE WHEN transaction_number = 500 THEN transaction_date ELSE NULL END) AS end_date
    FROM 
        CityTransactions
    GROUP BY 
        city
)
SELECT 
    city,
    DATEDIFF(end_date, start_date) AS days_to_500
FROM 
    CityDaysTo500
ORDER BY 
    days_to_500 ASC
LIMIT 1;
