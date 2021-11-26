USE commodity_db;
-- 1. Determine the common commodities between the Top 10 costliest commodities of 2019 and 2020.
WITH year1_summary AS
(
SELECT MAX(retail_price) as price,commodity_id,date
FROM price_details
WHERE Year(date) = 2019
GROUP BY commodity_id
ORDER BY price DESC
LIMIT 10),
year2_summary AS
(
SELECT MAX(retail_price) as price,commodity_id,date
FROM price_details
WHERE Year(date) = 2020
GROUP BY commodity_id
ORDER BY price DESC
LIMIT 10),
commodity_price as
(
SELECT y1.commodity_id,y1.price,y2.price as y2_price 
FROM year1_summary as y1
INNER JOIN year2_summary as y2
ON y1.commodity_id = y2.commodity_id
)
SELECT DISTINCT commodity
FROM commodities_info as ci
INNER JOIN commodity_price as cp
ON cp.commodity_id = ci.id;

-- What is the maximum difference between the prices of a commodity at one place vs the 
-- other for the month of June 2021? Which commodity was it for?
-- Algorithm used:
-- Filter Jun 2021 in Date column of price_details
-- To get the max difference: Take MIN(retail_price) and MAX(retail_price) from price_details 
-- groupby commodity from  commodities_info
-- Compute the difference between MAX & MIN retail_price
-- Sort in descending order of price : Retain the topmost row
WITH Commodity_price_details AS
(
SELECT Date, MIN(retail_price) as Min_price,MAX(retail_price) as Max_price , Commodity
FROM price_details as p
INNER JOIN Commodities_info as c
ON p.Commodity_id = c.id
WHERE Year(Date) = 2020 AND month(Date) = 06
GROUP BY Commodity
)
SELECT DISTINCT Commodity,(Max_price - Min_price) as Price_diff
FROM Commodity_price_details
ORDER BY Price_diff DESC
LIMIT 1; 
-- Arrange the commodities in an order based on the number of variants in which they are available, 
-- with the highest one shown at the top, which is the third commodity in the list.
SELECT commodity,COUNT(variety) as Num,category
FROM commodities_info
GROUP BY commodity
ORDER BY NUM DESC,Commodity ASC;

-- In a state with the least number of data points available, 
-- which commodity has the highest number of data points available?
-- Step 1: Join region information and price details by using the Region_Id from price_details with Id from region_info.
-- Step 2: From the result of Step 1, perform aggregation – COUNT(Id), group by State.
-- Step 3: Sort the result based on the record count computed in Step 2 in ascending order; Filter for the top State.
-- Step 4: Filter for the state identified from Step 3 from the price_details table.
-- Step 5: Aggregation – COUNT(Id), group by commodity_id; Sort in descending order of count.
-- Step 6: Filter for top 1 value and join with commodities_info to get the commodity name.
WITH joined AS
(
SELECT State,p.*
FROM price_details as p
LEFT JOIN 
region_info as r
ON p.region_id = r.id
),
State_dp as
(
SELECT State,COUNT(id) as record_count
FROM joined
GROUP BY state
ORDER BY record_count
LIMIT 1
),
Commodity_count AS 
(
SELECT commodity_id,COUNT(id) AS record
FROM joined 
WHERE state in (SELECT DISTINCT state from State_dp)
GROUP BY commodity_id
ORDER BY record DESC
)
SELECT commodity,SUM(record) as count
FROM commodity_count as cc
LEFT JOIN commodities_info as c
ON cc.commodity_id = c.id
GROUP BY commodity
ORDER BY count DESC
LIMIT 1;

-- What is the price variation of commodities for each city from January 2019 to December 2020? 
-- Which commodity has seen the highest price variation and in which city?
-- Step 1: Filter for January 2019 from the Date column of the price_details table.
-- Step 2: Filter for December 2020 from the Date column of the price_details table. 
-- 		   Firstly, we filtered the price_details data separately for January 2019 and December 2020. Next, we had two tables onto which we could apply queries to find the price difference and variation.
-- Step 3: Do an inner join between the results from Step 1 and Step 2 on region_id and commodity id.
-- Step 4: Name the price from Step 1 result as Start Price and Step 2 result as End Price.
-- Step 5: Calculate variations in absolute and percentage; 
-- 		   Sort the final table in descending order of variation percentage. After obtaining entries for January 2019 and December 2020, we joined the tables and found the price variation. We also did an inner join to avoid any blank entries. Then, sort the final table in descending order of variation to get maximum variation.
-- Step 6: Filter for the first record and join with region_info, 
--         commodities_info to get city and commodity name. 
--         Then, we LIMITed the records to one entry and joined it with region_info and 
--         commodities_info to get the name of the city and commodity.
WITH record_2019 AS
(
SELECT p1.* 
FROM price_details as p1
WHERE year(date)=2019 AND month(date) = 01
),
record_2020 AS
(
SELECT p2.* 
FROM price_details as p2
WHERE year(date)=2020 AND month(date) = 12
),
details as
(
SELECT r1.commodity_id,r1.region_id,
r1.date as Start_Date,r2.date as End_Date,r1.retail_price as Start_Price,
r2.retail_price as End_Price 
FROM record_2019 as r1
INNER JOIN record_2020 as r2
ON r1.commodity_id = r2.commodity_id
AND r1.region_id = r2.region_id -- Here the region and commodity has to be same in order to compare the price
ORDER BY r1.date DESC
),
Variation_data AS
(
SELECT commodity_id,region_id,Start_Date,End_Date,Start_Price,End_Price,(End_Price - Start_Price) as Variation,
((End_Price - Start_Price)/Start_Price)*100 as Percent_change
FROM details
ORDER BY Percent_change DESC
LIMIT 1
)
SELECT  Commodity,Centre,Start_Date,End_Date,Start_Price,End_Price,Variation,Percent_change
FROM Variation_data as v
INNER JOIN region_info as r
ON r.id = v.region_id
INNER JOIN commodities_info as c
ON c.id = v.commodity_id;
-- Lessons lerant:
-- In case of comparison between two tables with similar columns, we use INNER JOIN




























