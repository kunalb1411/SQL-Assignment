CREATE DATABASE Assignment_2;


use Assignment_2;

--  1.How many olympics games have been held?


SELECT COUNT(*) AS total_olympic_games
FROM athlete_events;

-- 2.List down all Olympics games held so far.


SELECT DISTINCT Year ,City,Season 
FROM athlete_events ;

-- 3.Mention the total no of nations who participated in each olympics game?

SELECT Year, COUNT(DISTINCT NOC) AS Total_Nations
FROM athlete_events
GROUP BY Year
ORDER BY Year;

--4.Which year saw the highest and lowest no of countries participating in olympics?
-- HIGHEST
SELECT TOP 1 Year,COUNT(DISTINCT NOC) AS Total_Nations FROM athlete_events
GROUP BY  Year  ORDER BY Total_Nations DESC  ;

-- LOWEST
SELECT TOP 1 Year,COUNT(DISTINCT NOC) AS Total_Nations FROM athlete_events
GROUP BY  Year  ORDER BY Total_Nations ASC  ;

--5.Which nation has participated in all of the olympic games?
SELECT NOC
FROM noc_regions
WHERE NOT EXISTS (
    SELECT DISTINCT Year
    FROM athlete_events
    WHERE athlete_events.NOC = noc_regions.NOC
    AND Year IS NOT NULL
    GROUP BY NOC,Year
    HAVING COUNT(DISTINCT Year) < (SELECT COUNT(DISTINCT Year) FROM athlete_events WHERE Year IS NOT NULL)
);

--6.Identify the sport which was played in all summer olympics.
SELECT DISTINCT Sport
FROM athlete_events
WHERE Season = 'Summer'
AND Sport NOT IN (
    SELECT DISTINCT Sport
    FROM athlete_events
    WHERE Season = 'Summer'
    AND Year NOT IN (SELECT DISTINCT Year FROM athlete_events WHERE Season = 'Summer')
);

--7.Which Sports were just played only once in the olympics?
SELECT DISTINCT Sport
FROM athlete_events
GROUP BY Sport
HAVING COUNT(DISTINCT Year) = 1;

--8.Fetch the total no of sports played in each olympic games.
SELECT Year, COUNT(DISTINCT Sport) AS Total_Sports
FROM athlete_events
GROUP BY Year
ORDER BY Year;


---9.Fetch details of the oldest athletes to win a gold medal.
SELECT * 
FROM
    athlete_events
WHERE
    Medal = 'Gold'
    AND Age = (SELECT MAX(Age) FROM athlete_events WHERE Medal = 'Gold');


--10.Find the Ratio of male and female athletes participated in all olympic games.
SELECT
    Year,
    Sex,
    COUNT(DISTINCT ID) AS Total_Athletes,
    ROUND(CAST(SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END), 0), 2) AS Male_Female_Ratio
FROM
    athlete_events
GROUP BY
    Year, Sex
ORDER BY
    Year, Sex;

--11.Fetch the top 5 athletes who have won the most gold medals.
SELECT TOP 5
    ID,
    Name,
    COUNT(*) AS Gold_Medals
FROM
    athlete_events
WHERE
    Medal = 'Gold'
GROUP BY
    ID, Name
ORDER BY
    Gold_Medals DESC;
--12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT TOP 5
    ID,
    Name,
    COUNT(*) AS Total_Medals
FROM
    athlete_events
WHERE
    Medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY
    ID, Name
ORDER BY
    Total_Medals DESC;

--13.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
SELECT TOP 5
    Team,
    COUNT(*) AS Total_Medals
FROM
    athlete_events
WHERE
    Medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY
    Team
ORDER BY
    Total_Medals DESC;

--14.List down total gold, silver and broze medals won by each country.

SELECT
    Team,
    COUNT(CASE WHEN Medal = 'Gold' THEN 1 END) AS Gold_Medals,
    COUNT(CASE WHEN Medal = 'Silver' THEN 1 END) AS Silver_Medals,
    COUNT(CASE WHEN Medal = 'Bronze' THEN 1 END) AS Bronze_Medals
FROM
    athlete_events
WHERE
    Medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY
    Team
ORDER BY
    Team;


--15.List down total gold, silver and broze medals won by each country corresponding to each olympic games.
SELECT
    Year,
    Team,
    COUNT(CASE WHEN Medal = 'Gold' THEN 1 END) AS Gold_Medals,
    COUNT(CASE WHEN Medal = 'Silver' THEN 1 END) AS Silver_Medals,
    COUNT(CASE WHEN Medal = 'Bronze' THEN 1 END) AS Bronze_Medals
FROM
    athlete_events
WHERE
    Medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY
    Year, Team
ORDER BY
    Year, Team;



--16.Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH MedalCounts AS (
    SELECT
        Year,
        Team,
        COUNT(CASE WHEN Medal = 'Gold' THEN 1 END) AS Gold_Medals,
        COUNT(CASE WHEN Medal = 'Silver' THEN 1 END) AS Silver_Medals,
        COUNT(CASE WHEN Medal = 'Bronze' THEN 1 END) AS Bronze_Medals,
        ROW_NUMBER() OVER (PARTITION BY Year ORDER BY COUNT(CASE WHEN Medal = 'Gold' THEN 1 END) DESC) AS Gold_Rank,
        ROW_NUMBER() OVER (PARTITION BY Year ORDER BY COUNT(CASE WHEN Medal = 'Silver' THEN 1 END) DESC) AS Silver_Rank,
        ROW_NUMBER() OVER (PARTITION BY Year ORDER BY COUNT(CASE WHEN Medal = 'Bronze' THEN 1 END) DESC) AS Bronze_Rank
    FROM
        athlete_events
    WHERE
        Medal IN ('Gold', 'Silver', 'Bronze')
    GROUP BY
        Year, Team
)
SELECT
    Year,
    MAX(CASE WHEN Gold_Rank = 1 THEN Team END) AS Most_Gold_Country,
    MAX(CASE WHEN Silver_Rank = 1 THEN Team END) AS Most_Silver_Country,
    MAX(CASE WHEN Bronze_Rank = 1 THEN Team END) AS Most_Bronze_Country
FROM
    MedalCounts
GROUP BY
    Year
ORDER BY
    Year;

--17.Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH MedalCounts AS (
    SELECT
        Year,
        Team,
        COUNT(*) AS Total_Medals,
        COUNT(CASE WHEN Medal = 'Gold' THEN 1 END) AS Gold_Medals,
        COUNT(CASE WHEN Medal = 'Silver' THEN 1 END) AS Silver_Medals,
        COUNT(CASE WHEN Medal = 'Bronze' THEN 1 END) AS Bronze_Medals,
        ROW_NUMBER() OVER (PARTITION BY Year ORDER BY COUNT(*) DESC) AS Total_Rank,
        ROW_NUMBER() OVER (PARTITION BY Year ORDER BY COUNT(CASE WHEN Medal = 'Gold' THEN 1 END) DESC) AS Gold_Rank,
        ROW_NUMBER() OVER (PARTITION BY Year ORDER BY COUNT(CASE WHEN Medal = 'Silver' THEN 1 END) DESC) AS Silver_Rank,
        ROW_NUMBER() OVER (PARTITION BY Year ORDER BY COUNT(CASE WHEN Medal = 'Bronze' THEN 1 END) DESC) AS Bronze_Rank
    FROM
        athlete_events
    WHERE
        Medal IN ('Gold', 'Silver', 'Bronze')
    GROUP BY
        Year, Team
)
SELECT
    Year,
    MAX(CASE WHEN Total_Rank = 1 THEN Team END) AS Most_Total_Medals_Country,
    MAX(CASE WHEN Gold_Rank = 1 THEN Team END) AS Most_Gold_Country,
    MAX(CASE WHEN Silver_Rank = 1 THEN Team END) AS Most_Silver_Country,
    MAX(CASE WHEN Bronze_Rank = 1 THEN Team END) AS Most_Bronze_Country
FROM
    MedalCounts
GROUP BY
    Year
ORDER BY
    Year;

--18.Which countries have never won gold medal but have won silver/bronze medals?
SELECT DISTINCT
    Team
FROM
    athlete_events
WHERE
    Team IS NOT NULL
    AND Team != ''
    AND Medal IN ('Silver', 'Bronze')
    AND Team NOT IN (
        SELECT DISTINCT
            Team
        FROM
            athlete_events
        WHERE
            Team IS NOT NULL
            AND Team != ''
            AND Medal = 'Gold'
    );

--19.In which Sport/event, India has won highest medals.
SELECT TOP 1
    Sport,
    Event,
    COUNT(*) AS Total_Medals
FROM
    athlete_events
WHERE
    Team = 'India'
    AND Medal IS NOT NULL
GROUP BY
    Sport, Event
ORDER BY
    Total_Medals DESC;

--20.Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.
SELECT
    Year,
    COUNT(*) AS Total_Hockey_Medals
FROM
    athlete_events
WHERE
    Team = 'India'
    AND Sport = 'Hockey'
    AND Medal IS NOT NULL
GROUP BY
    Year
ORDER BY
    Year;

