CREATE DATABASE ecommerce_analytics;

USE ecommerce_analytics;

CREATE TABLE online_retail_raw (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10,2),
    CustomerID INT,
    Country VARCHAR(100)
);

SHOW TABLES;

SELECT COUNT(*) AS total_rows
FROM online_retail_raw;

DESCRIBE online_retail_raw;

USE ecommerce_analytics;

ALTER TABLE online_retail_raw
MODIFY InvoiceDate VARCHAR(30);

TRUNCATE TABLE online_retail_raw;
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

SHOW VARIABLES LIKE 'version%';
SHOW VARIABLES LIKE 'local_infile';
LOAD DATA LOCAL INFILE 'C:/Users/dell/Downloads/Online_Retail.csv'
INTO TABLE ecommerce_analytics.online_retail_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
);

SELECT *
FROM online_retail_raw
LIMIT 10;

SELECT
    MIN(InvoiceDate) AS first_date,
    MAX(InvoiceDate) AS last_date
FROM online_retail_raw;


USE ecommerce_analytics;

SELECT COUNT(*) AS total_rows
FROM online_retail_raw;

SELECT
    COUNT(*) AS total_rows,
    COUNT(CustomerID) AS non_null_customers,
    COUNT(*) - COUNT(CustomerID) AS missing_customers
FROM online_retail_raw;

SELECT
    MIN(InvoiceDate) AS first_date,
    MAX(InvoiceDate) AS last_date
FROM online_retail_raw;


-- Cancelled invoices
SELECT COUNT(*) AS cancelled_invoices
FROM online_retail_raw
WHERE InvoiceNo LIKE 'C%';

-- Invalid quantities
SELECT COUNT(*) AS invalid_quantity
FROM online_retail_raw
WHERE Quantity <= 0;

-- Invalid prices
SELECT COUNT(*) AS invalid_price
FROM online_retail_raw
WHERE UnitPrice <= 0;

-- Missing descriptions
SELECT COUNT(*) AS missing_description
FROM online_retail_raw
WHERE Description IS NULL OR TRIM(Description) = '';


DROP TABLE IF EXISTS online_retail_clean;

CREATE TABLE online_retail_clean AS
SELECT
    InvoiceNo,
    StockCode,
    TRIM(Description) AS Description,
    Quantity,
    STR_TO_DATE(InvoiceDate, '%d-%m-%Y %H:%i') AS InvoiceDate,
    UnitPrice,
    CustomerID,
    TRIM(Country) AS Country
FROM online_retail_raw
WHERE
    InvoiceNo NOT LIKE 'C%'
    AND Quantity > 0
    AND UnitPrice > 0
    AND CustomerID IS NOT NULL
    AND Description IS NOT NULL
    AND TRIM(Description) <> '';
    
SELECT COUNT(*) AS clean_rows
FROM online_retail_clean;

SELECT *
FROM online_retail_clean
LIMIT 10;

SELECT
    MIN(InvoiceDate) AS first_date,
    MAX(InvoiceDate) AS last_date
FROM online_retail_clean;


-- EDA
SELECT
    ROUND(SUM(Quantity * UnitPrice), 2) AS total_revenue
FROM online_retail_clean;

SELECT
    COUNT(DISTINCT CustomerID) AS unique_customers
FROM online_retail_clean;

SELECT
    COUNT(DISTINCT StockCode) AS unique_products
FROM online_retail_clean;

SELECT
    COUNT(DISTINCT InvoiceNo) AS total_orders
FROM online_retail_clean;

SELECT
    Country,
    ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM online_retail_clean
GROUP BY Country
ORDER BY revenue DESC;

SELECT
    StockCode,
    Description,
    ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM online_retail_clean
GROUP BY StockCode, Description
ORDER BY revenue DESC
LIMIT 10;

SELECT
    StockCode,
    Description,
    SUM(Quantity) AS units_sold
FROM online_retail_clean
GROUP BY StockCode, Description
ORDER BY units_sold DESC
LIMIT 10;

SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
    ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM online_retail_clean
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY month;


-- RFM Table -- 
DROP TABLE IF EXISTS customer_rfm;

CREATE TABLE customer_rfm AS
SELECT
    CustomerID,

    DATEDIFF(
        '2011-12-10',
        DATE(MAX(InvoiceDate))
    ) AS Recency,

    COUNT(DISTINCT InvoiceNo) AS Frequency,

    ROUND(
        SUM(Quantity * UnitPrice),
        2
    ) AS Monetary

FROM online_retail_clean

GROUP BY CustomerID;

SELECT *
FROM customer_rfm
LIMIT 10;

-- RFM stats
SELECT
    COUNT(*) AS customers,
    MIN(Recency) AS min_recency,
    MAX(Recency) AS max_recency,
    MIN(Frequency) AS min_frequency,
    MAX(Frequency) AS max_frequency,
    MIN(Monetary) AS min_monetary,
    MAX(Monetary) AS max_monetary
FROM customer_rfm;

SELECT *
FROM customer_rfm
ORDER BY Monetary DESC
LIMIT 10;



-- Summary Table

DROP TABLE IF EXISTS sales_summary;

CREATE TABLE sales_summary AS
SELECT
    InvoiceNo,
    InvoiceDate,
    CustomerID,
    StockCode,
    Description,
    Quantity,
    UnitPrice,
    Quantity * UnitPrice AS Revenue,
    Country
FROM online_retail_clean;


SELECT
    COUNT(*) AS total_rows,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    COUNT(DISTINCT CustomerID) AS total_customers
FROM sales_summary;