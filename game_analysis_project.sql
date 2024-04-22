USE game_analysis;

# Task1: Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.
SELECT player_details.p_id,
	level_details.dev_id,
    player_details.player_name,
    level_details.difficulty
FROM player_details
INNER JOIN level_details
		ON player_details.p_id = level_details.p_id
WHERE level = 0
ORDER BY player_name;


# Task2: Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed.
SELECT player_details.l1_code, AVG(level_details.kill_count) AS avg_kill_count
FROM level_details
INNER JOIN player_details
	ON player_details.p_id = level_details.p_id
WHERE lives_earned = 2
	  AND stages_crossed >= 3
GROUP BY l1_code
ORDER BY avg_kill_count DESC;


# Task3: Find the total number of stages crossed at each difficulty level for Level 2 
# with players using `zm_series` devices. Arrange the result in decreasing order of the total number of stages crossed.

SELECT level_details.difficulty,
	   SUM(level_details.stages_crossed) AS total_stages_crossed
FROM level_details
INNER JOIN player_details
		ON player_details.p_id = level_details.p_id
WHERE level = 2
	AND dev_id LIKE 'zm%'
GROUP BY difficulty
ORDER BY total_stages_crossed DESC;


# Task4: Extract `P_ID` and the total number of unique dates for those players who have played games on multiple days.

SELECT level_details.p_id,
	   COUNT(DISTINCT level_details.start_datetime) as total_unique_dates
FROM level_details
GROUP BY p_id
HAVING total_unique_dates > 1 
ORDER BY total_unique_dates DESC;


# Task5: Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the average kill count for Medium difficulty.

WITH medium_avg AS (
SELECT AVG(kill_count) AS avg_medium_kill_count
FROM level_details
WHERE difficulty = 'Medium' )
SELECT p_id, level, SUM(kill_count) as total_kill_count
FROM level_details
WHERE kill_count > (SELECT avg_medium_kill_count FROM medium_avg)
GROUP BY p_id, level
ORDER BY total_kill_count DESC;


# Task6: Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 0. Arrange in ascending order of level.

SELECT level, l1_code, l2_code, SUM(lives_earned) AS total_lives_earned
FROM level_details
INNER JOIN player_details
		ON player_details.p_id = level_details.p_id
WHERE level <> 0
GROUP BY level, l1_code, l2_code
ORDER BY level;


# Task7: Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well.

WITH TopScores AS (
    SELECT dev_id, score, difficulty,
           ROW_NUMBER() OVER (PARTITION BY dev_id ORDER BY score DESC) AS row_rank
    FROM level_details
)
SELECT dev_id, score, difficulty, row_rank
FROM TopScores
WHERE row_rank <= 3
ORDER BY score DESC, row_rank ASC
LIMIT 3;


# Task8: Find the `first_login` datetime for each device ID.

SELECT dev_id, MIN(start_datetime) AS frist_login
FROM level_details
GROUP BY dev_id
ORDER BY dev_id, frist_login;


# Task9: Find the top 5 scores based on each difficulty level and rank them in increasing order using `Rank`. Display `Dev_ID` as well.

WITH TopScores AS (
    SELECT dev_id, score, difficulty,
           RANK() OVER (PARTITION BY difficulty ORDER BY score DESC) AS row_rank
    FROM level_details
)
SELECT dev_id, score, difficulty, row_rank
FROM TopScores
WHERE row_rank <= 5
ORDER BY row_rank DESC
LIMIT 5;


# Task10: Find the device ID that is first logged in (based on `start_datetime`) for each player (`P_ID`).
# Output should contain player ID, device ID, and first login datetime.

SELECT p_id, dev_id, MIN(start_datetime) AS first_login
FROM level_details
GROUP BY p_id, dev_id
ORDER BY  first_login;


# Task11: For each player and date, determine how many `kill_counts` were played by the player so far.
# a) Using window functions
# b) Without window functions 

# a) Using window functions
WITH CumulativeKills AS (
    SELECT
        p_id,
        CAST(start_datetime AS DATE) AS start_date,
        kill_count,
        SUM(kill_count) OVER (PARTITION BY p_id ORDER BY CAST(start_datetime AS DATE)) AS total_kill_count
    FROM
        level_details
)
SELECT
    p_id,
    start_date,
    MAX(total_kill_count) AS total_kill_count
FROM
    CumulativeKills
GROUP BY
    p_id, start_date
ORDER BY
    start_date ASC, total_kill_count DESC;



# b) Without window functions
SELECT
	p_id,
	CAST(start_datetime AS DATE) AS start_date,
    SUM(kill_count) AS total_kill_count
FROM level_details
GROUP BY p_id, start_date
ORDER BY start_date ASC, total_kill_count DESC;


# Task12: Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, excluding the most recent `start_datetime`.

WITH CumulativeStages AS (
    SELECT 
        p_id,
        start_datetime,
        SUM(stages_crossed) OVER (PARTITION BY p_id ORDER BY start_datetime ASC 
									ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS cumulative_stages_crossed
    FROM level_details
)
SELECT *
FROM CumulativeStages
WHERE cumulative_stages_crossed IS NOT NULL
ORDER BY cumulative_stages_crossed DESC;


# Task13: Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

SELECT p_id, dev_id, SUM(score) AS total_score
FROM level_details
GROUP BY p_id, dev_id
ORDER BY total_score DESC
LIMIT 3;


# Task14: Find players who scored more than 50% of the average score, scored by the sum of scores for each `P_ID`.

SELECT p_id, SUM(score) AS total_score
FROM level_details
GROUP BY p_id 
HAVING total_score > 0.5 * AVG(score)
ORDER BY total_score DESC;

# Task15: Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID` 
# and rank them in increasing order using `Row_Number`. Display the difficulty as well.

DELIMITER $$
CREATE PROCEDURE FindTopHeadshotsByDevIdNew(IN n INT)
BEGIN
    WITH TopHeadshots AS (
        SELECT p_id, dev_id, headshots_count, difficulty,
               ROW_NUMBER() OVER (PARTITION BY dev_id ORDER BY headshots_count DESC) AS ranking
        FROM level_details
    )
    SELECT p_id, dev_id, headshots_count, difficulty
    FROM TopHeadshots
    WHERE ranking <= n
    ORDER BY dev_id, ranking;
END $$
DELIMITER ;

# calling the stored prosedure
CALL FindTopHeadshotsByDevIdNew(5);
