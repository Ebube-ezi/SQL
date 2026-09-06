-- Data Cleaning

SELECT *
FROM layoffs;

-- Step 1: Remove Duplicates
-- Step 2: Standardize the date
-- Step 3: Null values or blank values
-- Step 4: Remove col/row unneccessary - there are instances this can and shouldn't be done


-- Creating a table similar to our raw data so we keep our raw data RAW
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Inserting the raw data into the new table
SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- STEP 1: Remove Duplicates
-- We need to add and extra column called ID to make it easy with identification

-- Create a row number
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off,
 `date`) AS row_num
FROM layoffs_staging;

-- Creating a CTE or sbuquery
WITH duplicate_cte AS 
(SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
`date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)

SELECT *
FROM duplicate_cte
WHERE row_num > 1 ;

-- To verify the duplicates, lets test with one company, at the end we found out that 'Oda' are not duplicates
-- and we need to partition by all the columns
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Now that we have found the dup, we need to delete one and leave the right one, from the CTE 
-- WITH duplicate_cte AS 
-- (SELECT *,
-- ROW_NUMBER() OVER(
-- PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
-- `date`, stage, country, funds_raised_millions) AS row_num
-- FROM layoffs_staging)

-- DELETE
-- FROM duplicate_cte
-- WHERE row_num > 1 ; -- Because the delete funct is not updatable, this will not work

-- We'll have to create another table using our columns before deleting anything. Create an extra row and delete 
-- where the row=2

-- Create a table layoffs_staging2 
CREATE TABLE `layoffs_staging2` (
`company` text,
`location` text,
`industry` text,
`total_laid_off` int DEFAULT NULL,
`percentage_laid_off` text,
`date` text,
`stage` text,
`country` text,
`funds_raised_millions` int DEFAULT NULL, 
`row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2
WHERE row_num >1 ;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
`date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num >1 ;

SELECT *
FROM layoffs_staging2;


-- STEP 2: Standaising is finding issues in your data and fixing it.

SELECT company, (TRIM(company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
; -- Next is to update all industry to be Crypto rather than CryptoCurrency

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) -- Trailing where we specify in the quote what we are looking for
FROM layoffs_staging2
ORDER BY 1 ;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- formating the date to what we want using the % sign
SELECT `date`
FROM layoffs_staging2;

-- UPDATE layoffs_staging2  (used to update date format)
-- SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y') 

-- To change it to a date column
ALTER TABLE  layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;


-- STEP 3: NULL and BLANK values
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- To update a row with missing data provided they are from the same company category
SELECT t1.company, t2.company
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
	-- AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;  

UPDATE  layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;
    
SELECT *
FROM layoffs_staging2;


-- STEP 4
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- we want to drop a column from the table
SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
