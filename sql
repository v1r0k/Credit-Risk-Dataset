-- We load our cleaned file without abnormal values using Python
ALTER TABLE credit_risk_dataset_clean RENAME TO cred;
ALTER TABLE cred ALTER COLUMN loan_int_rate TYPE numeric(10,2) USING loan_int_rate::numeric;
SELECT * FROM cred;


--1 Какая доля дефолтов в датасете?
SELECT (SELECT COUNT(loan_status) FROM cred WHERE loan_status = 1) * 100.0 / 
(SELECT COUNT(loan_status) FROM cred) AS percent_of_default; -----------------------------------------------------------------------------

--2 Сколько дефолтов и не-дефолтов в абсолютных числах?
SELECT loan_status, COUNT(*) FROM cred GROUP BY loan_status; ----------------------------------------------------------------------------

--3 Насколько классы несбалансированы (соотношение bad/good)?
SELECT ROUND(AVG(loan_status)/(1-AVG(loan_status)), 2) AS balance FROM cred;

--4 Есть ли категории с долей дефолтов выше 50%?
SELECT loan_grade, AVG(loan_status) * 100.0 AS percent_of_default FROM cred
GROUP BY loan_grade HAVING AVG(loan_status) * 100.0 > 50; ----------------------------------------------------------------------------------

--5 Есть ли категории с долей дефолтов ниже 5%?
SELECT loan_grade, AVG(loan_status) * 100.0 AS percent_of_default FROM cred
GROUP BY loan_grade HAVING AVG(loan_status) * 100.0 < 5;

--6 Какая доля дефолтов среди заёмщиков с известной ставкой?
SELECT AVG(loan_status) * 100.0 AS percent_of_default, COUNT(*) FROM cred WHERE loan_int_rate IS NOT NULL;

--7 Какая доля дефолтов среди заёмщиков с неизвестной ставкой?
SELECT AVG(loan_status) * 100.0 AS percent_of_default, COUNT (*)FROM cred WHERE loan_int_rate IS NULL;

--8 Отличается ли баланс классов в разных грейдах?
SELECT loan_grade, AVG(loan_status) * 100.0 AS percent_of_default, COUNT (*) FROM cred
GROUP BY loan_grade ORDER BY percent_of_default DESC; ---------------------------------------------------------------------------------------

--9 Отличается ли баланс классов в разных типах владения?
SELECT person_home_ownership, AVG(loan_status) * 100.0 AS percent_of_default, COUNT (*) FROM cred
GROUP BY person_home_ownership ORDER BY percent_of_default DESC; ----------------------------------------------------------------------------
 
--10 Отличается ли баланс классов по целям кредита?
SELECT loan_intent, AVG(loan_status) * 100.0 AS percent_of_default, COUNT (*) FROM cred
GROUP BY loan_intent ORDER BY percent_of_default DESC;

--11 Есть ли сегмент, где дефолтов больше, чем не-дефолтов?
SELECT 'person_home_ownership' AS segment_table, person_home_ownership AS segment, AVG(loan_status) * 100.0 AS percent_of_default, COUNT (*) FROM cred
GROUP BY person_home_ownership HAVING AVG(loan_status) * 100.0 > 50 
UNION ALL
SELECT 'segment_loan_intent', loan_intent, AVG(loan_status) * 100.0 AS percent_of_default, COUNT (*) FROM cred
GROUP BY loan_intent HAVING AVG(loan_status) * 100.0 > 50 
UNION ALL
SELECT 'segme_cb_person_default_on_file', cb_person_default_on_file, AVG(loan_status) * 100.0 AS percent_of_default, COUNT (*) FROM cred
GROUP BY cb_person_default_on_file HAVING AVG(loan_status) * 100.0 > 50 ORDER BY percent_of_default DESC;

--12 Сколько уникальных комбинаций loan_intent × loan_grade?
SELECT COUNT(DISTINCT(loan_intent, loan_grade)) FROM cred;

--13 Сколько уникальных комбинаций home_ownership × loan_grade?
SELECT COUNT(DISTINCT(person_home_ownership, loan_grade)) FROM cred;

--14 Сколько уникальных комбинаций intent × ownership × grade?
SELECT COUNT(DISTINCT(loan_intent, person_home_ownership, loan_grade)) FROM cred;

--18 Какая доля строк имеет loan_status=1 и grade в D–G?
SELECT (SELECT COUNT(*) FROM cred WHERE loan_status = 1 AND loan_grade IN ('D', 'E', 'F', 'G')) * 100.0  / (SELECT COUNT(*) FROM cred) AS pct;

--19 Какая доля строк имеет loan_status=1 и grade в A–C?
SELECT (SELECT COUNT(*) FROM cred WHERE loan_status = 1 AND loan_grade IN ('A', 'B', 'C')) * 100.0  / (SELECT COUNT(*) FROM cred) AS pct;

--29 Как распределены грейды в портфеле?
SELECT loan_grade, COUNT (*), ROUND(COUNT(*) * 100.0/ SUM(COUNT(*)) OVER (), 2) AS prcnt FROM cred
GROUP BY loan_grade ORDER BY count DESC;

--30 Какой грейд самый частый?
SELECT loan_grade, COUNT (*) FROM cred GROUP BY loan_grade ORDER BY count DESC LIMIT 1;

--31 Какой грейд самый редкий?
SELECT loan_grade, COUNT (*) FROM cred GROUP BY loan_grade ORDER BY count LIMIT 1;

--40 Какая доля каждого грейда в общем числе дефолтов?
SELECT loan_grade, SUM(loan_status) AS sum_of_defaults, 
ROUND(SUM (loan_status) * 100.0 / (SELECT SUM(loan_status) FROM cred), 2) AS prcnt_from_all FROM cred GROUP BY loan_grade
ORDER BY prcnt_from_all DESC;

--41 Какая доля каждого грейда в общем числе не-дефолтов?
SELECT loan_grade, SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END) AS non_default_count,
ROUND(SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END) * 100.0 / (SELECT SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END) FROM cred), 2) AS prcnt_of_non_default
FROM cred GROUP BY loan_grade ORDER BY prcnt_of_non_default DESC;

--44 Какие цели кредита доминируют в каждом грейде?
SELECT * FROM (SELECT loan_grade, loan_intent, COUNT (*), DENSE_RANK () OVER (PARTITION BY loan_grade ORDER BY COUNT (*) DESC) 
FROM cred GROUP BY loan_grade, loan_intent) WHERE dense_rank = 1;

--45 Какие типы владения доминируют в каждом грейде?
SELECT * FROM (SELECT loan_grade, person_home_ownership, COUNT (*), DENSE_RANK () OVER (PARTITION BY loan_grade ORDER BY COUNT (*) DESC) 
FROM cred GROUP BY loan_grade, person_home_ownership) WHERE dense_rank = 1;

--46 Есть ли грейды, где доля прошлых дефолтов особенно высока?
SELECT * FROM cred;
SELECT loan_grade, AVG(CASE WHEN cb_person_default_on_file = 'Y' THEN 1 ELSE 0 END) * 100.0 AS prcnt_of_past_default 
FROM cred GROUP BY loan_grade ORDER BY prcnt_of_past_default DESC;

--47 Какой грейд даёт максимальный «вклад» в дефолты на единицу портфеля?
SELECT loan_grade, CAST(ROUND(SUM(loan_status) * 100.0/(SELECT COUNT (*) FROM cred), 2) AS numeric) AS prcnt_of_default_from_all,
AVG(loan_status) * 100.0 AS prcnt_of_default_in_group,
COUNT (*) FROM cred GROUP BY loan_grade ORDER BY prcnt_of_default_from_all DESC;

--48 Какой грейд самый «прибыльный» при текущей ставке и уровне риска?
SELECT loan_grade, COUNT(*) AS total_loans, ROUND(AVG(loan_int_rate)::numeric, 2) AS avg_rate, 
ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct, ROUND(AVG(loan_int_rate)::numeric * (1 - AVG(loan_status)), 2) AS expected_yield_pct
FROM cred GROUP BY loan_grade ORDER BY expected_yield_pct DESC;

--49 Покрывает ли средняя ставка грейда уровень его дефолтов?
WITH stats AS (SELECT loan_grade, AVG(loan_int_rate) AS avg_rate, AVG(loan_status) * 100 AS default_rate_pct FROM cred GROUP BY loan_grade)
SELECT loan_grade, ROUND(avg_rate, 2) AS avg_rate, ROUND(default_rate_pct, 2) AS default_rate_pct, 
ROUND(avg_rate - default_rate_pct, 2) AS margin,
CASE WHEN avg_rate > default_rate_pct THEN 'Покрывает' ELSE 'НЕ покрывает' END AS coverage FROM stats ORDER BY loan_grade;

--50 Есть ли грейды с отрицательным ожидаемым доходом?
WITH stats AS (SELECT loan_grade, AVG(loan_int_rate) AS avg_rate, AVG(loan_status) * 100 AS default_rate_pct 
FROM cred GROUP BY loan_grade)
SELECT loan_grade, ROUND(avg_rate, 2) AS avg_rate, ROUND(default_rate_pct, 2) AS default_rate_pct, 
ROUND(avg_rate * (1 - default_rate_pct / 100), 2) AS expected_yield, 
CASE WHEN avg_rate * (1 - default_rate_pct / 100) < 0 THEN 'Отрицательный' ELSE 'Положительный' END AS yield_status
FROM stats ORDER BY expected_yield ASC;

--51 Как меняется default rate внутри одного грейда при росте PTI?
WITH pti_stats AS (SELECT loan_grade, loan_status, 
NTILE(4) OVER (PARTITION BY loan_grade ORDER BY loan_percent_income) AS pti_group FROM cred) 
SELECT loan_grade, pti_group, ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct FROM pti_stats 
GROUP BY loan_grade, pti_group ORDER BY loan_grade, pti_group;

--52 Как меняется default rate внутри одного грейда при росте суммы?
WITH amnt_stats AS (SELECT loan_grade, loan_status, NTILE(4) OVER (PARTITION BY loan_grade ORDER BY loan_amnt) AS amnt_group FROM cred)
SELECT loan_grade, amnt_group, ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct 
FROM amnt_stats GROUP BY loan_grade, amnt_group ORDER BY loan_grade, amnt_group;

--53 Как меняется default rate внутри одного грейда при росте ставки?
WITH rate_stats AS (SELECT loan_grade, loan_status, 
NTILE(4) OVER (PARTITION BY loan_grade ORDER BY loan_int_rate) AS rate_group FROM cred) 
SELECT loan_grade, rate_group, ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct 
FROM rate_stats GROUP BY loan_grade, rate_group ORDER BY loan_grade, rate_group;

--54 Есть ли грейды, где высокий доход не снижает риск?
WITH income_stats AS (SELECT loan_grade, loan_status, 
NTILE(4) OVER (PARTITION BY loan_grade ORDER BY person_income) AS income_group FROM cred) 
SELECT loan_grade, income_group, ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct 
FROM income_stats GROUP BY loan_grade, income_group ORDER BY loan_grade, income_group;

--55 Есть ли грейды, где молодой возраст особенно рискован?
WITH age_stats AS (SELECT loan_grade, loan_status, NTILE(4) OVER (PARTITION BY loan_grade ORDER BY person_age) AS age_group FROM cred)
SELECT loan_grade, age_group, ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct 
FROM age_stats GROUP BY loan_grade, age_group ORDER BY loan_grade, age_group;

--56 Есть ли грейды, где длинная кредитная история не помогает?
WITH hist_stats AS (SELECT loan_grade, loan_status, NTILE(4) OVER (PARTITION BY loan_grade ORDER BY cb_person_cred_hist_length) AS hist_group FROM cred) 
SELECT loan_grade, hist_group, ROUND(AVG(loan_status) * 100, 2) AS default_rate_pct 
FROM hist_stats GROUP BY loan_grade, hist_group ORDER BY loan_grade, hist_group;
