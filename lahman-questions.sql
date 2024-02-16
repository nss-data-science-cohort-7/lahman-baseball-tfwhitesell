-- 1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last 
-- names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. 
-- Which Vanderbilt player earned the most money in the majors?
WITH college_play AS (
	SELECT playerid
	FROM collegeplaying
	WHERE schoolid = 'vandy'
	GROUP BY 1
)

SELECT namefirst,
	namelast,
	SUM(salary::numeric::money) AS total_salary
FROM people AS p
INNER JOIN salaries AS s
	ON p.playerid = s.playerid
WHERE p.playerid IN (
	SELECT playerid FROM college_play)
 GROUP BY 1, 2
ORDER BY 3 DESC;
-- David Price is the highest-earning player in the dataset who played at Vanderbilt.

-- 2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", 
-- those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number 
-- of putouts made by each of these three groups in 2016.
SELECT CASE WHEN pos = 'OF'
			THEN 'Outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B')
			THEN 'Infield'
		ELSE 'Battery'
		END AS position_type,
	SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY 1;

-- 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the 
-- same for home runs per game. Do you see any trends?
-- easiest way
SELECT yearid / 10 * 10 AS decade,
	ROUND((SUM(so) * 1.0) / SUM(ghome), 2) AS avg_so, -- g doubles the number of games since there are 2 teams
	ROUND((SUM(hr) * 1.0) / SUM(ghome), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY 1
ORDER BY 1;

-- using GENERATE_SERIES
WITH decade AS (
	SELECT GENERATE_SERIES(1920, 2016, 10) AS start_year,
		GENERATE_SERIES(1929, 2019, 10) AS end_year
)

SELECT start_year AS decade,
ROUND((SUM(so) * 1.0) / SUM(ghome), 2) AS avg_so, -- g doubles the number of games since there are 2 teams
	ROUND((SUM(hr) * 1.0) / SUM(ghome), 2) AS avg_hr
FROM teams
LEFT JOIN decade
	ON yearid BETWEEN start_year AND end_year
WHERE yearid >= 1920
GROUP BY 1
ORDER BY 1;
-- Strikeouts tripled over the time period covered, while homeruns have increased by about 2.5 times.
-- The 2000s decade was noticeably higher than the surrounding decades and the 1990s also increased significantly over the decade prior.
-- Does this correspond with the most egregious use of steroids?

-- 4. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base 
-- attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only 
-- players who attempted _at least_ 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen 
-- base percentage.
SELECT CONCAT(namefirst, ' ', namelast) AS player_name,
	SUM(sb) AS num_stolen,
	SUM(sb + cs) AS total_attempted,
	ROUND((SUM(sb) * 100.0) / SUM(sb + cs), 2) AS percent_success
FROM batting AS b
INNER JOIN people AS p
	ON b.playerid = p.playerid
WHERE yearid = 2016
GROUP BY 1
HAVING SUM(sb + cs) >= 20
ORDER BY 4 DESC;
-- Chris Owings had the most success stealing bases in 2016 with a 91.3% success rate.

-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number 
-- wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world 
-- series champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was 
-- it the case that a team with the most wins also won the world series? What percentage of the time?
SELECT name,
	w AS wins,
	l AS losses,
	wswin AS ws_winner
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
ORDER BY 2 DESC;
-- The Seattle Mariners had the largest number of wins in the given time period without winning the World Series.

SELECT name,
	w AS wins,
	l AS losses,
	wswin AS ws_winner,
	yearid
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'
	AND yearid != 1981
ORDER BY 2;
-- The Los Angeles Dodgers won 63 games in 1981 and also won the World Series.
-- There was a player's strike in 1981 which reduced the total number of games played that year.
-- The St Louis Cardinals won 83 games in 2006 and also won the World Series.

-- most wins per year
WITH most_wins AS (
	SELECT yearid,
		MAX(w) AS wins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
		AND yearid != 1994 -- no WS in 1994
	GROUP BY 1
),

-- World Series winners by year
ws_winners AS (
	SELECT yearid,
		name,
		w AS wins,
		wswin AS ws_winner
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
		AND wswin = 'Y'
)

SELECT -- w.yearid,
-- 	w.name,
-- 	w.wins,
	COUNT(CASE WHEN w.wins = m.wins THEN 1 END) AS double_winners,
	ROUND(AVG(CASE WHEN w.wins = m.wins THEN 1.0
		 	ELSE 0 END) * 100, 2) AS percent_double_winners
FROM ws_winners AS w
INNER JOIN most_wins AS m
	ON w.yearid = m.yearid;
-- The team with the most wins in a given year also won the World Series 12 times between 1970 and 2016, which was 26.09% of the time.
-- There was no World Series played in 1994 due to a strike.

-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give 
-- their full name and the teams that they were managing when they won the award.
WITH nl_winners AS (
	SELECT a.yearid,
		a.lgid,
		a.playerid,
		t.name AS team_name
	FROM awardsmanagers AS a
	INNER JOIN managers AS m
		ON a.playerid = m.playerid
			AND a.yearid = m.yearid
	INNER JOIN teams AS t
		ON m.teamid = t.teamid
			AND m.yearid = t.yearid
	WHERE awardid LIKE 'TSN%'
		AND a.lgid = 'NL'
),

al_winners AS (
	SELECT a.yearid,
		a.lgid,
		a.playerid,
		t.name AS team_name
	FROM awardsmanagers AS a
	INNER JOIN managers AS m
		ON a.playerid = m.playerid
			AND a.yearid = m.yearid
	INNER JOIN teams AS t
		ON m.teamid = t.teamid
			AND m.yearid = t.yearid
	WHERE awardid LIKE 'TSN%'
		AND a.lgid = 'AL'
)

SELECT CONCAT(namefirst, ' ', namelast) AS manager_name,
	n.yearid AS nl_win,
	n.team_name,
	a.yearid AS al_win,
	a.team_name
FROM nl_winners AS n
INNER JOIN al_winners AS a
	ON n.playerid = a.playerid
INNER JOIN people AS p
	ON n.playerid = p.playerid;
-- This gets the answer but I'd like the format to be better.

-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games 
-- (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats 
-- for each player.
-- players can have more than one record in the pitching table (one for each team)
-- but salary looks to be yearly total across all teams
SELECT CONCAT(namefirst, ' ', namelast) AS player_name,
	p.playerid,
	SUM(so) AS strikeouts,
	MAX(salary)::numeric::money AS salary,
	CAST(ROUND(MAX(salary)::numeric / SUM(so)::numeric, 2) AS MONEY) AS dollars_per_strikeout
FROM pitching AS p
INNER JOIN salaries AS s
	ON p.playerid = s.playerid
		AND p.yearid = s.yearid
INNER JOIN people AS p2
	ON p.playerid = p2.playerid
WHERE p.yearid = 2016
GROUP BY 1, 2
HAVING SUM(gs) >= 10
ORDER BY 5 DESC;

-- 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were 
-- inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being 
-- inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.
SELECT playerid,
	CASE WHEN inducted = 'Y' THEN yearid END AS year_inducted
FROM halloffame
GROUP BY 1, 2
ORDER BY 1

SELECT b.playerid,
	SUM(h) AS career_hits
FROM batting AS b
GROUP BY 1
HAVING SUM(h) >= 3000
ORDER BY 2

SELECT *
FROM halloffame
ORDER BY 1
LIMIT 10

-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league 
-- for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs 
-- they hit in 2016.

-- After finishing the above questions, here are some open-ended questions to consider.

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do 
-- this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.

--     a. Does there appear to be any correlation between attendance at home games and number of wins?  
--     b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making 
-- 	the playoffs means either being a division winner or a wild card winner.


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. 
-- Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers 
-- are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it 
-- into the hall of fame?