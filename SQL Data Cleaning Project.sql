/* Data Cleaning Project SQL*/

SELECT * FROM nHousing

--The date column is messed up so
--We standardize the SaleDate Column
SELECT SaleDate 
FROM nHousing

ALTER TABLE nhousing
ALTER COLUMN SaleDate DATE

--OR
SELECT SaleDate,CONVERT(DATE,SaleDate)
FROM nHousing

UPDATE nHousing
SET SaleDate = CONVERT(DATE,SaleDate)

----------------------------------------------------------------------------------------------------------------
-- Popluate PropertyAddress Data
SELECT PropertyAddress
FROM nHousing
WHERE PropertyAddress IS NULL

SELECT a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress FROM 
nHousing as a
join nHousing as b
on a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET a.PropertyAddress = b.PropertyAddress
FROM nHousing AS a
JOIN nHousing AS b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-----------------------------------------------------------------------------------------------------

-- Breaking Out PropertyAddress into Individual Columns (address,city OR states)

SELECT PropertyAddress
FROM nHousing

SELECT
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS ADDRESS,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS ADDRESSS
FROM 
nHousing

--Adding Column And Updating With Corrected Values

ALTER TABLE nhousing
ADD PropertySplitAddress NVARCHAR(255)

UPDATE nHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)


ALTER TABLE nhousing
ADD PropertySplitCity NVARCHAR(255)

UPDATE nHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) 


-------------------------------------------------------------------------------------------------------------
-- Breaking Out OwnerAddress into Individual Columns (address,city OR states)

SELECT OwnerAddress
FROM 
nHousing

SELECT 
PARSENAME(REPLACE(owneraddress,',','.'),3) AS HOME,
PARSENAME(REPLACE(owneraddress,',','.'),2) AS CITY,
PARSENAME(REPLACE(owneraddress,',','.'),1) AS STATE
FROM
nHousing

ALTER TABLE nhousing
ADD OwnerSplitaddress NVARCHAR(255)

UPDATE nHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(owneraddress,',','.'),3)

ALTER TABLE nhousing
ADD OwnerSplitCity NVARCHAR(255)

UPDATE nHousing
SET OwnerSplitCity = PARSENAME(REPLACE(owneraddress,',','.'),2)

ALTER TABLE nhousing
ADD OwnerSplitState NVARCHAR(255)

UPDATE nHousing
SET  OwnerSplitState = PARSENAME(REPLACE(owneraddress,',','.'),1)

--------------------------------------------------------------------------------------------------------------------------
--The Column SoldAsAacant Conatains YES NO and Y AND N, SO its needs to ne coverted to Y = yes And N = No
SELECT SoldAsVacant
FROM 
nHousing

SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVacant) AS Count
FROM 
nHousing
GROUP BY SoldAsVacant
ORDER BY 2

--WILL USE CASE STATEMENT

SELECT soldasvacant,
CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
FROM 
nHousing

UPDATE nHousing
SET SoldAsVacant = CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END

-----------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH windowfnCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ParcelID, saleprice,saledate,propertyaddress,legalreference 
                              ORDER BY UniqueID) AS row_num
    FROM nHousing
)
DELETE 
FROM windowfnCTE
WHERE row_num > 1;

--------------------------------------------------------------------------------------------------------------------------------------------
--Getting rid of unused columns

ALTER TABLE nHousing
DROP COLUMN propertyaddress,owneraddress,taxdistrict