-- Data Cleaning
SELECT *
FROM project_layoffs.layoffs;

-- First, I'm going to create a staging table, which I will use to clean the data.
-- This will ensure I still have the raw data in case I need it.

CREATE TABLE  project_layoffs.layoffs_staging
LIKE  project_layoffs.layoffs;

INSERT INTO project_layoffs.layoffs_staging
SELECT *
FROM project_layoffs.layoffs;

-- Next, I will follow these steps to clean my data:
-- 1. Check for duplicates and remove them.
-- 2. Standardize the data.
-- 3. Look for null or blank values.
-- 4. Remove any unnecessary columns or rows.

-- 1. Removing Duplicates:
-- To start, I will check for duplicates:

SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		project_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
-- All entries with row_num greater than 1 are duplicates and should be deleted.
-- To do this, I will create the following CTE:

WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		project_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;

WITH DELETE_CTE AS (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM project_layoffs.layoffs_staging
)
DELETE FROM project_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
	FROM DELETE_CTE
) AND row_num > 1;

-- Since some SQL dialects don't support direct deletion from a CTE (like MySQL), I will use the following method:
-- I will create another table, add a row_num column, and use that to delete the duplicates.

ALTER TABLE project_layoffs.layoffs_staging ADD row_num INT;

SELECT *
FROM project_layoffs.layoffs_staging
;

CREATE TABLE `project_layoffs`.`layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` INT,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` INT,
  `row_num` INT
);

INSERT INTO `project_layoffs`.`layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		project_layoffs.layoffs_staging;

DELETE
FROM project_layoffs.layoffs_staging2
WHERE row_num > 1;

-- Now I will check to see if all the rows with row_num > 1 were deleted:

SELECT *
FROM project_layoffs.layoffs_staging2;


-- 2. Standardizing the Data:
-- After checking the data, I noticed that in the company column, there are cases where I need to trim whitespace at the beginning of the company name.

SELECT DISTINCT(TRIM(company))
FROM project_layoffs.layoffs_staging2;
 
UPDATE project_layoffs.layoffs_staging2
SET company = TRIM(company);

-- Looking further into the industry column reveals another issue: there are cases where the same industry has different names.
-- For example, the Crypto industry appears as 'Crypto', 'Crypto Currency', or 'CryptoCurrency'.
-- This would be a problem when performing an EDA, so it needs to be standardized.

UPDATE project_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- A similar problem can be seen in the country column. 'USA' is sometimes saved as 'United States' and in other cases as 'United States.' (with a period).

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM project_layoffs.layoffs_staging2;
 
UPDATE project_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Another issue I found is that the date column is formatted as text instead of as a date.
-- This will cause problems during EDA.

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM project_layoffs.layoffs_staging2;

UPDATE project_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE project_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. Handling Null or Missing Values:
-- The industry column contains null or missing values.
-- I will replace blank entries with NULL since they are easier to handle.

UPDATE project_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM project_layoffs.layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- There are four companies with missing industry values.
-- To fix this, I will check for other entries of these companies that have industry data.

SELECT *
FROM project_layoffs.layoffs_staging2 t1
JOIN project_layoffs.layoffs_staging2 t2
	ON 	t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Three of the four companies have other entries with industry values.
-- I will use those to update the missing values.

UPDATE project_layoffs.layoffs_staging2 t1
JOIN project_layoffs.layoffs_staging2 t2
	ON 	t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- 4. Removing Unnecessary Columns:
-- The total_laid_off and percentage_laid_off columns have many rows with null values in both columns.
-- This indicates inaccurate data that cannot be trusted.
-- After careful consideration, I have decided to delete these rows.

DELETE
FROM project_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- To finish the cleaning process, I will remove the row_num column since it is no longer needed.

ALTER TABLE project_layoffs.layoffs_staging2
DROP COLUMN row_num;

-- Now, I can view my cleaned dataset:

SELECT *
FROM project_layoffs.layoffs_staging2

