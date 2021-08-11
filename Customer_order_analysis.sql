/*
Customer Order Data Exploration 

Skills used: Update, Joins, Window Functions, Aggregate Functions, CTEs, Case Statement, Percentage, Converting Data Types
*/


-- Creating tables and importing data
CREATE TABLE `woodcorp_etc_customerdata` ( CUSTOMER_NO VARCHAR(255),
						  LOYALTY_PROGRAM INT, 
                          AGE INT, 
                          CUSTOMER_TYPE INT,
                          GENDER INT);     


CREATE TABLE `woodcorp_etc_offline` ( ORDER_NO VARCHAR(255) NOT NULL,
						  CUSTOMER_NUMBER_OFFLINE VARCHAR(255), 
                          ORDER_VALUE_OFFLINE DECIMAL(10,2) NOT NULL, 
                          DISCOUNT_VALUE_OFFLINE DECIMAL(10,2) NOT NULL ,
                          NUMBER_ITEMS_OFFLINE INT NOT NULL ,
                          NUMBER_DISCOUNT_ITEMS_OFFLINE INT NOT NULL,
                          HIGH_QUALITY_WOOD INT NOT NULL,
                          LOW_QUALITY_WOOD INT NOT NULL);     
                          
CREATE TABLE `woodcorp_etc_online` ( ORDER_NO VARCHAR(255) NOT NULL,
						  CUSTOMER_NUMBER_ONLINE VARCHAR(255), 
                          ORDER_VALUE_ONLINE DECIMAL(10,2) NOT NULL, 
                          DISCOUNT_VALUE_ONLINE DECIMAL(10,2) NOT NULL ,
                          NUMBER_ITEMS_ONLINE INT NOT NULL ,
                          NUMBER_DISCOUNTED_ITEMS_ONLINE INT NOT NULL);
                          

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\WOODCORP_ETC_CUSTOMERDATA.csv'
into table woodcorp_etc_customerdata
fields terminated by ','
optionally enclosed by '"'
escaped by '"'
lines terminated by '\n'
ignore 1 lines;

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\WOODCORP_ETC_OFFLINE.csv'
into table woodcorp_etc_offline
fields terminated by ','
optionally enclosed by '"'
escaped by '"'
lines terminated by '\n'
ignore 1 lines;

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\WOODCORP_ETC_ONLINE.csv'
into table woodcorp_etc_online
fields terminated by ','
optionally enclosed by '"'
escaped by '"'
lines terminated by '\n'
ignore 1 lines;



-- Rename the tables for ease of use
ALTER TABLE woodcorp_etc_customerdata
RENAME TO customerdata;

ALTER TABLE woodcorp_etc_online
RENAME TO customer_online;

ALTER TABLE woodcorp_etc_offline
RENAME TO customer_offline;



-- Data Exploration

-- Number and Percentage of customers by Customer type
ALTER TABLE customerdata
ADD CUSTOMER_TYPE_TEXT NVARCHAR(255);

UPDATE customerdata
SET CUSTOMER_TYPE_TEXT = CASE
	WHEN CUSTOMER_TYPE = 1 THEN "Transporter"
    WHEN CUSTOMER_TYPE = 2 THEN "Factory"
    WHEN CUSTOMER_TYPE = 3 THEN "Trader"
    WHEN CUSTOMER_TYPE = 4 THEN "Private"
    ELSE "Not specified"
END;

SELECT CUSTOMER_TYPE_TEXT FROM customerdata;

SELECT CUSTOMER_TYPE_TEXT, 
	COUNT(CUSTOMER_NO) "Number of customers",
    COUNT(*)*100/ SUM(COUNT(*)) OVER () "% customer"
FROM customerdata
GROUP BY CUSTOMER_TYPE;



-- Number and Percentage of customers by Age group
ALTER TABLE customerdata
ADD AGE_TEXT NVARCHAR(255);

UPDATE customerdata
SET AGE_TEXT = CASE
	WHEN AGE = 1 THEN "0-18"
    WHEN AGE = 2 THEN "19-35"
    WHEN AGE = 3 THEN "36-55"
    WHEN AGE = 4 THEN "> 55"
    ELSE "Not specified"
END;

SELECT AGE_TEXT FROM customerdata;

SELECT AGE_TEXT, 
	COUNT(CUSTOMER_NO) "Number of customers",
    COUNT(*)*100/ SUM(COUNT(*)) OVER () "% customer"
FROM customerdata
GROUP BY AGE_TEXT;



-- The youngest customer type
SELECT CUSTOMER_TYPE_TEXT FROM customerdata
WHERE CUSTOMER_TYPE_TEXT != "Not specified"
GROUP BY CUSTOMER_TYPE
ORDER BY AVG(CAST(AGE AS FLOAT)) ASC
LIMIT 1;



-- Number and percentage of customers by Gender (Female = 1, Male = 0)
SELECT GENDER, 
	COUNT(CUSTOMER_NO) "Number of customers",
    COUNT(*)*100/ SUM(COUNT(*)) OVER () "% customer"
FROM customerdata
GROUP BY GENDER;



-- Compare the average number of items men and women buy online
WITH customer_online_gender AS (
								SELECT d.GENDER, con.NUMBER_ITEMS_ONLINE
                                FROM customer_online con
									INNER JOIN customerdata d ON d.CUSTOMER_NO = con.CUSTOMER_NUMBER_ONLINE)
SELECT GENDER, AVG(NUMBER_ITEMS_ONLINE) FROM customer_online_gender
GROUP BY GENDER;



-- Percentage of customer participating in loyalty program
SELECT LOYALTY_PROGRAM, 
	   COUNT(CUSTOMER_NO) "Number of customers",
       COUNT(*)*100/ SUM(COUNT(*)) OVER () "% customer"
FROM customerdata
GROUP BY LOYALTY_PROGRAM;

-- Gender split among customer in loyalty program
SELECT GENDER, 
	   COUNT(CUSTOMER_NO) "NumberGender", 
	   COUNT(CUSTOMER_NO)*100/SUM(COUNT(*)) OVER () AS "PercentageGender"
FROM customerdata
WHERE LOYALTY_PROGRAM = 1 
GROUP BY GENDER;



-- Customer type that is relatively speaking responsible for most online orders?
-- In order value
SELECT d.CUSTOMER_TYPE, 
	   SUM(o.ORDER_VALUE_ONLINE) 
FROM customer_online o
	INNER JOIN customerdata d on d.CUSTOMER_NO = o.CUSTOMER_NUMBER_ONLINE
GROUP BY d.CUSTOMER_TYPE
ORDER BY SUM(o.ORDER_VALUE_ONLINE) DESC;

-- In order amount, 
SELECT d.CUSTOMER_TYPE, 
	   SUM(o.NUMBER_ITEMS_ONLINE) 
FROM customer_online o
	INNER JOIN customerdata d on d.CUSTOMER_NO = o.CUSTOMER_NUMBER_ONLINE
GROUP BY d.CUSTOMER_TYPE
ORDER BY SUM(o.NUMBER_ITEMS_ONLINE) DESC;



-- Is the average value of an online order higher when more than 6 items are bought in discount?
SELECT 
CASE
	WHEN NUMBER_DISCOUNTED_ITEMS_ONLINE > 6 THEN 1 ELSE 0
END AS 'DISCOUNTED_ITEMS_OVER6',
AVG(ORDER_VALUE_ONLINE)
FROM customer_online
GROUP BY DISCOUNTED_ITEMS_OVER6;



-- Age group orders the most online items? 2
SELECT d.AGE_TEXT, 
	   SUM(o.NUMBER_ITEMS_ONLINE) 
FROM customer_online o
	INNER JOIN customerdata d on d.CUSTOMER_NO = o.CUSTOMER_NUMBER_ONLINE
GROUP BY d.AGE_TEXT
ORDER BY SUM(o.NUMBER_ITEMS_ONLINE) DESC;



-- What customer type orders low quality wood more often?
SELECT d.CUSTOMER_TYPE, 
	   COUNT(o.LOW_QUALITY_WOOD) 
FROM customerdata d
	INNER JOIN customer_offline o ON d.CUSTOMER_NO = o.CUSTOMER_NUMBER_OFFLINE
GROUP BY d.CUSTOMER_TYPE
ORDER BY COUNT(o.LOW_QUALITY_WOOD) DESC;

