-- Exploratory Data Analysis

-- Looking at the data to find potential points for deeper examination.
SELECT *
FROM project_layoffs.layoffs_staging2;

-- Checking the maximum number of layoffs and the maximum percentage of company layoffs.
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM project_layoffs.layoffs_staging2;

-- From the last query, I see that there are cases where the max percentage of layoffs within a company is 1.
-- This means there are companies that had basically 100 percent of their personnel laid off.
SELECT *
FROM project_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- It can be seen that these are mostly startups that went out of business.
-- Ordering the companies by funds_raised_millions also lets me know how big some of those companies were.
-- Some of the companies that shut down were big names like Britishvolt, Quibi, Deliveroo Australia, Katerra and BlockFi, companies that raised at least one billion dollars in funding.

-- Now I want to check the companies with the highest total number of layoffs.
SELECT company, SUM(total_laid_off)
FROM project_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
-- The top companies here are the prominent players of the tech sector, including Amazon, Google, Meta, Salesforce and Microsoft.
-- It can be seen that traveling companies like Uber and hotel companies like Booking.com were affected too.

-- Checking the dates available in the dataset:
SELECT MIN(`date`), MAX(`date`)
FROM project_layoffs.layoffs_staging2;
-- My dataset has layoffs data from March of 2020 to March of 2023.

-- Looking at the sum of total layoffs sorted by industry:
SELECT industry, SUM(total_laid_off)
FROM project_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
-- The Consumer, Retail and Transportation industry had the biggest amounts of layoffs.
-- This is expected and can be correlated to the COVID pandemic.

-- Layoffs sorted by country:
SELECT country, SUM(total_laid_off)
FROM project_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
-- The U.S. experienced layoffs on a much larger scale than other countries, potentially due to its high concentration of tech firms and startups..

-- Layoffs sorted by year:
SELECT YEAR(`date`), SUM(total_laid_off)
FROM project_layoffs.layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
-- The biggest rise in layoffs was in 2022 with 160,322 total layoffs, while the data ends at March of 2023, in these months 2023 had 125677 layoffs.
-- This indicates that 2023 might easily surpassed 2022 and have the most layoffs.

-- Layoffs sorted by the company's stage:
SELECT stage, SUM(total_laid_off)
FROM project_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- After looking at the companies with the highest total layoffs, now I want to check the layoffs per year:
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM project_layoffs.layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC
), Company_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;

-- This subquery lets me see the five companies with the largest layoffs each year between March 2020 and March 2023.
-- It can be seen that during 2020 the companies with the most layoff were all from the transportation, hospitality and consumer industries.
-- Tech companies like Amazon, Google, and Meta led layoffs from 2022 onwards, highlighting a shift from early pandemic job losses concentrated in travel and hospitality industries..

-- I also want to analyze monthly layoffs with a rolling total to identify periods with significant spikes:
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM project_layoffs.layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_off
,SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- From the data, I can see that there were significant layoffs between 04/2020 - 05/2020, and again from 06/2022 to 2023.
-- The spike in layoffs in 2022 coincides with economic downturns, rising inflation, and post-pandemic adjustments.


