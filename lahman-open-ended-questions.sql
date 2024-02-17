-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do 
-- this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
-- salary by team per year
WITH dollars AS (
	SELECT yearid,
		teamid,
		SUM(salary::numeric::money) AS team_salary
	FROM salaries
	WHERE yearid >= 2000
	GROUP BY 1, 2
),

-- wins by team per year
wins AS (
	SELECT yearid,
		teamid,
		SUM(w) AS year_wins
	FROM teams
	WHERE yearid >= 2000
	GROUP BY 1, 2
	ORDER BY 3 DESC
),

-- put together
all_together AS (
	SELECT d.yearid,
		d.teamid,
		team_salary,
		year_wins,
		team_salary / year_wins AS dollars_per_win,
		RANK() OVER(PARTITION BY d.yearid ORDER BY team_salary DESC) AS salary_rank,
		RANK() OVER(PARTITION BY d.yearid ORDER BY year_wins DESC) AS wins_rank
	FROM dollars AS d
	INNER JOIN wins AS w
		ON d.teamid = w.teamid
			AND d.yearid = w.yearid
)

SELECT DISTINCT yearid,
	ROUND(CORR(team_salary::numeric, year_wins) OVER(PARTITION BY yearid)::numeric, 2) AS money_wins_corr
FROM all_together
ORDER BY 1;
--A couple of years have a weak moderate correlation between team salary and wins, but most years the correlation between the two variables is weak.

-- 12. In this question, you will explore the connection between number of wins and attendance.

--     a. Does there appear to be any correlation between attendance at home games and number of wins?  
--     b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making 
-- 	the playoffs means either being a division winner or a wild card winner.


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. 
-- Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers 
-- are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it 
-- into the hall of fame?