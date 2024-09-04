-- tables to work with
SELECT count(*) FROM public.member; --3,812,075
SELECT count(*) FROM public.contribution;--18,965,616
SELECT count(*) FROM public.claim;--18,339

SELECT * FROM public.member; --3,812,075
SELECT * FROM public.contribution;--18,965,616
SELECT * FROM public.claim;--18,339

-- removing rows where date of birth column has more than 5 digits for the year or is greater than the current date

DELETE FROM public.contribution
WHERE "memberId" IN (
    SELECT id
    FROM public.member
    WHERE EXTRACT(YEAR FROM "dateOfBirth") >= 10000
       OR "dateOfBirth" > CURRENT_DATE
); --50 rows affected

DELETE FROM public.bill_contributors
WHERE "member" IN (
    SELECT id
    FROM public.member
    WHERE EXTRACT(YEAR FROM "dateOfBirth") >= 10000
       OR "dateOfBirth" > CURRENT_DATE
);

-- I decided to update to null then delete because deleting was throwing many FK errors.
UPDATE public.member
SET "dateOfBirth" = NULL
public.member WHERE EXTRACT(YEAR FROM "dateOfBirth") >= 10000
   OR "dateOfBirth" > CURRENT_DATE;

DELETE FROM public.member
WHERE "dateOfBirth" = NULL;

-- Identifying missing values
SELECT COUNT(*) AS missing_values
FROM public.member
WHERE id IS NULL OR gender IS NULL or occupation IS NULL;

--deleting duplicates
DELETE FROM public.member a
USING public.member b
WHERE a.id > b.id
AND a."fullName" = b."fullName"
AND a."gender" = b."gender"
AND a."dateOfBirth" = b."dateOfBirth"
AND a."cellId" = b."cellId";

-- cleaning claim table
DELETE
FROM public.claim
WHERE type IS NULL
OR "referenceNumber" IS NULL
OR "paymentChannel" IS NULL;

UPDATE public.claim
SET "benefitPaymentAmount" = 0
WHERE "benefitPaymentAmount" IS NULL;


DELETE FROM public.claim
WHERE "memberId" IS NULL
   OR "memberId" NOT IN (SELECT id FROM public.member);
   
-- removing duplicates
DELETE FROM public.claim a
USING public.claim b
WHERE a.id > b.id
AND a."referenceNumber" = b."referenceNumber";

DELETE FROM public.contribution
WHERE "memberId" IS NULL
   OR "memberId" NOT IN (SELECT id FROM public.member);

-- contribution table
UPDATE public.contribution
SET amount = 0
WHERE amount IS NULL;

DELETE FROM public.contribution
WHERE "memberId" IS NULL
   OR "memberId" NOT IN (SELECT id FROM public.member);


--- queries


-- gender by district
SELECT 
    a.name AS district_name,
    m.gender,
    COUNT(*) AS count
FROM member m
JOIN area a ON m."districtId" = a.id
WHERE a.type = 'DISTRICT'
GROUP BY a.name, m.gender
ORDER BY a.name, m.gender;

-- district with most member
SELECT 
    a.name AS district_name,
    COUNT(m.id) AS member_count
FROM member m
JOIN area a ON m."districtId" = a.id
WHERE a.type = 'DISTRICT'
GROUP BY a.name
ORDER BY member_count DESC
LIMIT 1;

-- district with least member
SELECT 
    a.name AS district_name,
    COUNT(m.id) AS member_count
FROM member m
JOIN area a ON m."districtId" = a.id
WHERE a.type = 'DISTRICT'
GROUP BY a.name
ORDER BY member_count ASC
LIMIT 1;

-- Members distribution by age group
SELECT 
    CASE
        WHEN age < 18 THEN 'Under 18'
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65 and over'
    END AS age_group,
    COUNT(*) AS member_count
FROM (
    SELECT 
        EXTRACT(YEAR FROM AGE(NOW(), m."dateOfBirth"))::int AS age
    FROM member m
) AS subquery
GROUP BY age_group
ORDER BY member_count DESC;


-- age group with most members
SELECT 
    CASE
        WHEN age < 18 THEN 'Under 18'
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65 and over'
    END AS age_group,
    COUNT(*) AS member_count
FROM (
    SELECT 
        EXTRACT(YEAR FROM AGE(NOW(), m."dateOfBirth"))::int AS age
    FROM 
        member m
) AS subquery
GROUP BY age_group
ORDER BY member_count DESC
LIMIT 1;

-- age group with least members
SELECT 
    CASE
        WHEN age < 18 THEN 'Under 18'
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65 and over'
    END AS age_group,
    COUNT(*) AS member_count
FROM (
    SELECT 
        EXTRACT(YEAR FROM AGE(NOW(), m."dateOfBirth"))::int AS age
    FROM 
        member m
) AS subquery
GROUP BY 
    age_group
ORDER BY 
    member_count ASC
LIMIT 1;

-- contributions by district
SELECT 
    a.name AS district_name,
    SUM(c.Amount) AS total_contributions
FROM contribution c
JOIN member m ON c."memberId" = m.id
JOIN area a ON m."districtId" = a.id
WHERE a.type = 'DISTRICT'
GROUP BY a.name
ORDER BY total_contributions DESC;

-- district with most contributions
SELECT 
    a.name AS district_name,
    SUM(c.Amount) AS total_contributions
FROM contribution c
JOIN member m ON c."memberId" = m.id
JOIN area a ON m."districtId" = a.id
WHERE a.type = 'DISTRICT'
GROUP BY a.name
ORDER BY total_contributions DESC
LIMIT 1;

-- district with least contributions
SELECT 
    a.name AS district_name,
    SUM(c.Amount) AS total_contributions
FROM contribution c
JOIN member m ON c."memberId" = m.id
JOIN area a ON m."districtId" = a.id
WHERE a.type = 'DISTRICT'
GROUP BY a.name
ORDER BY total_contributions ASC
LIMIT 1;

-- claims by district
SELECT 
    a.name AS district_name,
    COUNT(c.id) AS total_claims,
    SUM(c."benefitPaymentAmount") AS total_claim_amount
FROM claim c
JOIN member m ON c."memberId" = m.id
JOIN area a ON m."districtId" = a.id
WHERE a.type = 'DISTRICT'
GROUP BY a.name
ORDER BY total_claim_amount DESC;

-- district with most claims
SELECT 
    a.name AS district_name,
    COUNT(c.id) AS total_claims
FROM claim c
JOIN member m ON c."memberId" = m.id
JOIN area a ON m."districtId" = a.id
WHERE a.type = 'DISTRICT'
GROUP BY a.name
ORDER BY total_claims DESC
LIMIT 1;

--district with least claims
SELECT 
    a.name AS district_name,
    COUNT(c.id) AS total_claims
FROM claim c
JOIN member m ON c."memberId" = m.id
JOIN area a ON m."districtId" = a.id
WHERE a.type = 'DISTRICT'
GROUP BY a.name
ORDER BY total_claims ASC
LIMIT 1;

-- adding districtname to the member table 
ALTER TABLE member
ALTER COLUMN districtName TYPE character varying(50);

UPDATE member m
SET districtName = a.name
FROM area a
WHERE m."districtId" = a.id
AND a.type = 'DISTRICT';

-- adding and calculating the age group column column
ALTER TABLE member
ALTER COLUMN ageGroup TYPE character varying(20);

UPDATE member
SET ageGroup = CASE
    WHEN EXTRACT(YEAR FROM AGE(NOW(), "dateOfBirth")) < 18 THEN 'Under 18'
    WHEN EXTRACT(YEAR FROM AGE(NOW(), "dateOfBirth")) BETWEEN 18 AND 24 THEN '18-24'
    WHEN EXTRACT(YEAR FROM AGE(NOW(), "dateOfBirth")) BETWEEN 25 AND 34 THEN '25-34'
    WHEN EXTRACT(YEAR FROM AGE(NOW(), "dateOfBirth")) BETWEEN 35 AND 44 THEN '35-44'
    WHEN EXTRACT(YEAR FROM AGE(NOW(), "dateOfBirth")) BETWEEN 45 AND 54 THEN '45-54'
    WHEN EXTRACT(YEAR FROM AGE(NOW(), "dateOfBirth")) BETWEEN 55 AND 64 THEN '55-64'
    ELSE '65 and over'
END;

