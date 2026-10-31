create database healthcare;
use healthcare;

/* 1 a. Merge the two tables by first identifying the columns in the data tables that will help you
in merging*/

select * from `hospitalisation details`;
select * from `medical examinations`;

-- Merging both the tables on Customer ID Column as it is the common column as a view to use it further

CREATE VIEW MEDICAL_REC AS
SELECT DISTINCT 
H.`Customer ID`,
H.year,
H.month,
H.date,
H.children,
H.charges,
H.`Hospital tier`,
H.`City tier`,
H.`State ID`,
M.BMI,
M.HBA1C,
M.`Heart Issues`,
M.`Any Transplants`,
M.`Cancer history`,
M.NumberOfMajorSurgeries,
M.smoker 
FROM
(SELECT * from `medical examinations`) M
LEFT JOIN
(SELECT * FROM `hospitalisation details`) H
on M.`Customer ID` = H.`Customer ID`;

SELECT * FROM MEDICAL_REC;

/*1 b. In both tables, add a Primary Key constraint for these columns*/

alter table `medical examinations` 
modify column `Customer ID` varchar(10) primary key;

describe `medical examinations`;

SET SQL_SAFE_UPDATES=0;

alter table `hospitalisation details` modify column `Customer ID` varchar(10);
DESCRIBE `hospitalisation details`;

-- REMOVING THE NULL VALUES AND IDS WHICH ARE NOT LISTED IN PRIMARY KEY

DELETE FROM `hospitalisation details` 
WHERE `Customer ID` IN (
    SELECT `Customer ID` FROM (
        SELECT `Customer ID` 
        FROM `hospitalisation details` 
        WHERE `Customer ID` NOT IN (
            SELECT `Customer ID` FROM `medical examinations`
        )
    ) AS tmp
);

ALTER TABLE `hospitalisation details` 
ADD CONSTRAINT `fk`
FOREIGN KEY (`Customer ID`) REFERENCES `medical examinations` (`Customer ID`);

DESCRIBE `hospitalisation details` ;

/*2. Retrieve information about people who are diabetic and have heart problems with their average
age, the average number of dependent children, average BMI, and average hospitalization costs*/

ALTER TABLE  `hospitalisation details` ADD COLUMN AGE INT;

UPDATE `hospitalisation details` 
SET age = TIMESTAMPDIFF(
    YEAR, 
    STR_TO_DATE(CONCAT(year, '-', month, '-', date), '%Y-%b-%d'), 
    CURDATE()
)
WHERE month REGEXP '^[A-Za-z]{3}$' 
  AND year REGEXP '^[0-9]{4}$' 
  AND date REGEXP '^[0-9]{1,2}$';


ALTER VIEW MEDICAL_REC AS
SELECT DISTINCT 
H.`Customer ID`,
H.year,
H.month,
H.date,
H.children,
H.charges,
H.`Hospital tier`,
H.`City tier`,
H.`State ID`,
H.AGE,
M.BMI,
M.HBA1C,
M.`Heart Issues`,
M.`Any Transplants`,
M.`Cancer history`,
M.NumberOfMajorSurgeries,
M.smoker 
FROM
(SELECT * from `medical examinations`) M
LEFT JOIN
(SELECT * FROM `hospitalisation details`) H
on M.`Customer ID` = H.`Customer ID`;

SELECT * FROM MEDICAL_REC;

/*2. Retrieve information about people who are diabetic and have heart problems with their average
age, the average number of dependent children, average BMI, and average hospitalization costs*/

SELECT ROUND(AVG(AGE)) AS AVG_AGE, 
COUNT(children) AS AVG_CHILD_COUNT, 
ROUND(AVG(BMI),2) AS AVG_BMI, 
ROUND(AVG(charges),2) AS AVG_CHARGES FROM MEDICAL_REC
WHERE `Customer ID` IN
(SELECT `Customer ID`
FROM 
`medical examinations`
WHERE HBA1C>5.7 AND `Heart Issues` = 'YES');

/* 3. Find the average hospitalization cost for each hospital tier and each city level */

SELECT `Hospital tier`, `City tier`, ROUND (AVG(CHARGES),2)
FROM MEDICAL_REC
WHERE (`Hospital tier` != '?' OR NULL) AND (`City tier` != '?' OR NULL)
GROUP BY `Hospital tier`, `City tier`
ORDER BY `Hospital tier` , `City tier`;

/* 4. Determine the number of people who have had major surgery with a history of cancer */
SELECT COUNT(`Customer ID`) AS NUM_OF_PPL 
FROM MEDICAL_REC
WHERE NumberOfMajorSurgeries >=1 AND `Cancer history` = 'YES';

/* 5. Determine the number of tier-1 hospitals in each state */

SELECT `State ID`, COUNT(`Hospital tier`) AS TOTAL_TIER1_HOSP
FROM MEDICAL_REC
WHERE `Hospital tier` = 'TIER - 1' AND (`State ID` != '?' OR NULL)
GROUP BY `State ID`
ORDER BY `State ID`;
