--SQLZOO 4

--A subquery can give more than one result. To avoid testing a value against multiple results it's safer to use IN.



--1. List each country name where the population is larger than that of 'Russia'.

SELECT name 
FROM world
WHERE population >
    (SELECT population FROM world
    WHERE name='Russia')


--2. Show the countries in Europe with a per capita GDP greater than 'United Kingdom'.

SELECT name 
FROM world
WHERE 
continent = 'Europe' AND
gdp/population >
   (SELECT gdp/population FROM world
   WHERE name = 'United Kingdom')


--3. List the name and continent of countries in the continents containing either Argentina or Australia. Order by name of the country.

SELECT name, continent
FROM world
WHERE 
continent =
    (SELECT continent FROM world
    WHERE name = 'Argentina') OR 
continent = 
    (SELECT continent FROM world
    WHERE name = 'Australia')


--4. Which country has a population that is more than United Kingom but less than Germany? Show the name and the population.

SELECT name, population
FROM world
WHERE 
population >
    (SELECT population FROM world
    WHERE name= 'United Kingdom') AND
population <
    (SELECT population FROM world
    WHERE name= 'Germany')


--5. Show the name and the population of each country in Europe. Show the population as a percentage of the population of Germany.

/* Percentages are approximated at 0%
SELECT name, CONCAT(ROUND(100*(population/(select population from world where name = 'Germany'))),'%') 
FROM world
WHERE continent= 'Europe'
*/

/* Integer out of range
SELECT name, CONCAT(ROUND((100*population/(select population from world where name = 'Germany'))),'%') 
FROM world
WHERE continent= 'Europe'
*/

/* This gives plausible answers, but Austria should be 11% instead of 10%
SELECT name, CONCAT(
ROUND((population/(select population/100 from world where name = 'Germany')),0),'%') 
FROM world
WHERE continent= 'Europe'
*/

/* With PostGreSQL this gives 0, but with MySql it gives decimals
SELECT
name,
population / (SELECT population FROM world WHERE name='Germany')
FROM world
WHERE continent = 'Europe'
*/

--From Stack Overflow some users recommend casting the populations as a string

SELECT
name,
CONCAT(
    ROUND(population *100 /
    (SELECT population FROM world WHERE name='Germany')),
    '%')
FROM world
WHERE continent = 'Europe'

--6. Which countries have a GDP greater than every country in Europe? [Give the name only.] (Some countries may have NULL gdp values)

SELECT name
FROM world
WHERE gdp > 
    ALL(SELECT gdp FROM world
    WHERE gdp>0 AND continent='Europe')


--7. Find the largest country (by area) in each continent, show the continent, the name and the area:
--??? types of JOIN
--It will return additional, erroneous rows if the area of some some continent's largest country happens to be the same area as, for example, some other continent's second largest country. 
SELECT a.continent, name, a.area 
FROM world AS a
    JOIN 
        (SELECT continent, MAX(area) AS area
        FROM world 
        GROUP BY continent) AS b
    ON a.continent = b.continent AND
    a.area = b.area
--Alternative #1
select A.continent, W.name, A.area
from
(select continent, max(area) as area from world group by continent)A, world W
where
A.continent = W.continent
and
A.area = W.area
--Alternative #2
SELECT continent, name, area 
  FROM world x
 WHERE area >= ALL
    (SELECT area 
       FROM world y
      WHERE y.continent=x.continent
        AND area>0)
--Alternative #3
SELECT x.continent, x.name, x.area
FROM world AS x
WHERE x.area = (
  SELECT MAX(y.area)
  FROM world AS y
  WHERE x.continent = y.continent)

/* Doesn't work
SELECT continent, name, area 
  FROM world
 WHERE name IN (SELECT continent, name, MAX(area) 
                  FROM world 
                 GROUP BY continent);
*/

--8. List each continent and the name of the country that comes first alphabetically.

SELECT continent, MIN(name)
FROM world
GROUP BY continent

--Alternative #1
SELECT continent,name 
FROM world x
WHERE x.name <= ALL(select y.name from world y
                    where x.continent=y.continent)


--9. Find the continents where all countries have a population <= 25000000. Then find the names of the countries associated with these continents. Show name, continent and population.

SELECT name, continent, population 
FROM world x
WHERE NOT EXISTS (                  -- there are no countries
    SELECT *
    FROM world y
    WHERE y.continent = x.continent -- on the same continent
    AND y.population > 25000000     -- with more than 25M population 
   );

--Alternative #1
SELECT name, continent, population 
FROM world x
WHERE 25000000>=ALL 
(SELECT population FROM world y
    WHERE x.continent=y.continent
    AND population>0)

--Alternative #2
SELECT name,continent,population
FROM world
WHERE continent IN (
  SELECT continent
  FROM world
  GROUP BY continent
  HAVING MAX(population)<25000000
) 


--10. Some countries have populations more than three times that of all of their neighbours (in the same continent). Give the countries and continents.

SELECT name, continent
FROM world x
WHERE population > ALL
(SELECT population*3 FROM world y
WHERE x.continent=y.continent AND x.name != y.name)

