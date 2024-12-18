-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT nameFirst, nameLast, birthYear 
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT nameFirst, nameLast, birthYear 
  FROM people 
  WHERE nameFirst like '% %'
  ORDER BY nameFirst ASC, nameLast ASC;
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthYear, AVG(height) as avgheight, COUNT(*) as count 
  FROM people
  GROUP BY birthYear
  ORDER BY birthYear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthYear, AVG(height) as avgheight, COUNT(*) as count 
  FROM people
  GROUP BY birthYear
  HAVING AVG(height) > 70
  ORDER BY birthYear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT nameFirst, nameLast, p.playerID, yearid
  FROM people AS p
  INNER JOIN halloffame as h ON p.playerID = h.playerID
  WHERE h.inducted = 'Y'
  ORDER BY h.yearid DESC, p.playerID ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  
  WITH CASCHPLAYER(playerid, schoolid) AS ( 
    SELECT playerid, schoolid
    FROM collegeplaying 
    WHERE schoolID in (
        SELECT schoolID FROM schools 
        WHERE schoolState = 'CA'
	  )
  )
  SELECT nameFirst, nameLast, c.playerID, schoolid, f.yearid
  FROM CASCHPLAYER as c 
  INNER JOIN q2i as f 
  ON c.playerID = f.playerID
  ORDER BY f.yearid DESC,  schoolid ASC, c.playerID ASC;


-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT a.playerID, nameFirst, nameLast, b.schoolid
  FROM q2i as a 
  LEFT JOIN  collegeplaying as b on a.playerID = b.playerid 
  ORDER BY a.playerID DESC, schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT  b.playerid,p.nameFirst, p.nameLast, b.yearid,  CAST((H +  H2B + 2 * H3B + 3 * HR) AS REAL) / AB  AS SLG
  FROM batting as b
  LEFT JOIN people as p ON b.playerid = p.playerid
  WHERE AB > 50
  ORDER BY SLG DESC, b.yearid ASC, b.playerid ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  WITH maxSlgPlayer (LSLG, playerid) AS (
    SELECT CAST((SUM(H) + SUM(H2B)+ 2 * SUM(H3B) + 3 * SUM(HR)) AS REAL) / SUM(AB) AS LSLG, playerid
    FROM batting
    GROUP BY playerid
    HAVING 	SUM(AB) > 50
    ORDER BY LSLG DESC
    LIMIT 10
  )

  SELECT m.playerid,namefirst,namelast,LSLG  
  FROM maxSlgPlayer as m
  LEFT JOIN people as p ON m.playerid = p.playerid
  ORDER BY LSLG DESC, m.playerid ASC;
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  WITH maxSlgPlayer (LSLG, playerid) AS (
    SELECT CAST((SUM(H) + SUM(H2B)+ 2 * SUM(H3B) + 3 * SUM(HR)) AS REAL) / SUM(AB) AS LSLG, playerid
    FROM batting
    GROUP BY playerid
    HAVING SUM(AB) > 50  
  )

  SELECT p.namefirst, p.nameLast, lslg
  FROM maxSlgPlayer as m
  LEFT JOIN people as p on m.playerid = p.playerid
  WHERE lslg > (SELECT lslg FROM maxSlgPlayer WHERE playerid = 'mayswi01')
  ORDER BY namefirst

;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearID, min(salary), max(salary), AVG(salary)
  FROM salaries
  GROUP BY yearID
  ORDER BY yearid 
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH binid_dis(binid, low, high) AS (
    SELECT binid, 
        (min +  CAST(((max - min) / 10) AS INT) * binid), 
        (min +  CAST(((max - min) / 10) AS INT) * (binid + 1))
      FROM binids, q4i
      WHERE yearID = 2016
  )

  SELECT binid, low, high, count(1) as total
    FROM binid_dis as t
    LEFT JOIN salaries as s ON (t.binid = 9 and s.salary >= t.low and s.salary <= t.high) or (t.binid < 9 and s.salary >= t.low and s.salary < t.high)
    WHERE yearid = 2016
    GROUP BY binid
  -- WITH binid_dis(binid, low, high) AS (
  --   SELECT binid, 
  --       (min +  CAST(((max - min) / 10) AS INT) * binid), 
  --       (min +  CAST(((max - min) / 10) AS INT) * (binid + 1))
  --     FROM binids, q4i
  --     WHERE yearID = 2016
  -- ), binid_total (binid, total) AS (
  --   SELECT binid, count(1) as total
  --   FROM binid_dis as t
  --   LEFT JOIN salaries as s ON (t.binid = 9 and s.salary >= t.low and s.salary <= t.high) or (t.binid < 9 and s.salary >= t.low and s.salary < t.high)
  --   WHERE yearid = 2016
  --   GROUP BY binid
  -- )

  -- SELECT t.binid, low, high, total 
  -- FROM binid_dis as t
  -- LEFT JOIN binid_total as b ON t.binid = b.binid 
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT a.yearid, a.min - b.min, a.max - b.max, a.avg - b.avg 
  FROM q4i as a
  inner JOIN q4i as b ON a.yearid = b.yearid + 1
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT s.playerID, nameFirst, nameLast, salary, yearID
  FROM salaries as s
  LEFT JOIN people as p ON s.playerID = p.playerID
  WHERE (yearID = 2000 or yearID = 2001) and  EXISTS (
    --  2000和2001年份的的球员工资等于q4i中的最大工资，且年份相同	
    SELECT max as salary
    FROM q4i
    WHERE yearID = s.yearID and max = s.salary
  ) 
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT a.teamID, max(salary) - min(salary)
  FROM allstarfull as a
  LEFT JOIN salaries as s ON a.playerID = s.playerID and a.yearID = s.yearID and a.teamID = s.teamID
  WHERE a.yearID = 2016
  GROUP BY a.teamID
;

