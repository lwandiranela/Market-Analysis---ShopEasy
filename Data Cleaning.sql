-- Cleaning the products table

SELECT *
FROM dbo.products;

-- Categorise products based on their price
SELECT ProductID,
	ProductName,
	Price,
	Category,

	CASE 
		WHEN Price < 50 THEN 'Low'
		WHEN Price BETWEEN 50 AND 200 THEN 'Medium'
		ELSE 'High'
	END AS Price_Category
FROM dbo.products


-- Cleaning the customers and geography tables
SELECT *
FROM dbo.customers;

SELECT *
FROM dbo.geography;

-- Joining the customers and geography tables
SELECT 
	c.CustomerID,
	c.CustomerName,
	c.Email,
	c.Gender,
	c.Age,
	g.Country,
	g.City	
FROM customers AS c
LEFT JOIN
	dbo.geography AS g
ON 
	c.GeographyID = g.GeographyID


-- Cleaning the customer reviews table
SELECT *
FROM customer_reviews;

-- Replace the double white spaces found in the ReviewDate column with just single spaces
SELECT
	ReviewID,
	CustomerID,
	ProductID,
	ReviewDate,
	Rating,
	REPLACE(ReviewText,'  ',' ') AS ReviewText
FROM dbo.customer_reviews
;


-- Cleaning the engagement data table
SELECT *
FROM dbo.engagement_data;

/*Change Socialmedia to Social Media
Separate view and clicks into separate columns
Format the EngagementDate column dates to dd-MM-yyy
*/
SELECT 
	EngagementID,
	ContentID,
	CampaignID,
	ProductID,
	UPPER(REPLACE(ContentType, 'Socialmedia', 'Social media')) AS ContentType,
	LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined) - 1) AS Views,
	RIGHT(ViewsClicksCombined, LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)) AS Clicks,
	Likes,
	EngagementDate
FROM dbo.engagement_data
WHERE ContentType <> 'Newsletter';


-- Cleaning the customers journey table
SELECT *
FROM dbo.customer_journey
;

-- Filter out duplicate row numbers using a CTE
WITH DuplicateRecords AS (
SELECT 
	JourneyID,
	CustomerID,
	ProductID,
	VisitDate,
	Stage,
	Action,
	Duration,
	ROW_NUMBER() OVER(
		PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action
		ORDER BY JourneyID) AS row_num
FROM dbo.customer_journey
)
SELECT *
FROM DuplicateRecords
WHERE row_num > 1
ORDER BY JourneyID
;

/*
Standardising the data
replace null durations with the average duration
remove duplicate journeyID rows
*/
SELECT 
    JourneyID,  
    CustomerID,  
    ProductID,  
    VisitDate,  
    Stage, 
    Action,  
    COALESCE(Duration, avg_duration) AS Duration  -- Replaces missing durations with the average duration for the corresponding date
FROM 
    (
        -- Subquery to process and clean the data
        SELECT 
            JourneyID,  
            CustomerID, 
            ProductID,  
            VisitDate,  
            UPPER(Stage) AS Stage,  -- Converts Stage values to uppercase for consistency in data analysis
            Action,  
            Duration,  
            AVG(Duration) OVER (PARTITION BY VisitDate) AS avg_duration,  -- Calculates the average duration for each date, using only numeric values
            ROW_NUMBER() OVER (
                PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action  -- Groups by these columns to identify duplicate records
                ORDER BY JourneyID 
            ) AS row_num 
        FROM 
            dbo.customer_journey  
    ) AS subquery  
WHERE 
    row_num = 1; 