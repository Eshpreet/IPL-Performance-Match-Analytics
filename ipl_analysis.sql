-- IPL Performance & Match Analytics | MySQL

-- 1. Dataset coverage and relationship integrity
SELECT COUNT(*) AS match_rows, COUNT(DISTINCT match_id) AS unique_matches
FROM matches_cleaned;

SELECT COUNT(*) AS delivery_rows, COUNT(DISTINCT match_id) AS matches_with_deliveries
FROM deliveries_cleaned;

SELECT COUNT(DISTINCT d.match_id) AS delivery_match_ids_without_match_record
FROM deliveries_cleaned d
LEFT JOIN matches_cleaned m USING (match_id)
WHERE m.match_id IS NULL;

-- 2. Overall tournament summary
SELECT COUNT(DISTINCT match_id) AS total_matches,
       COUNT(DISTINCT season) AS seasons,
       COUNT(*) FILTER (WHERE winner IS NOT NULL) AS matches_with_winner,
       COUNT(*) FILTER (WHERE outcome = 'tie') AS tied_matches,
       COUNT(*) FILTER (WHERE outcome = 'no result') AS no_result_matches
FROM matches_cleaned;

-- 3. Team appearances and wins (historical names are kept as recorded)
WITH appearances AS (
    SELECT match_id, team1 AS team FROM matches_cleaned
    UNION ALL
    SELECT match_id, team2 AS team FROM matches_cleaned
),
played AS (
    SELECT team, COUNT(DISTINCT match_id) AS matches_played
    FROM appearances GROUP BY team
),
wins AS (
    SELECT winner AS team, COUNT(DISTINCT match_id) AS wins
    FROM matches_cleaned WHERE winner IS NOT NULL GROUP BY winner
)
SELECT p.team, p.matches_played, COALESCE(w.wins,0) AS wins,
       ROUND(100.0 * COALESCE(w.wins,0) / NULLIF(p.matches_played,0),2) AS win_pct
FROM played p LEFT JOIN wins w USING (team)
ORDER BY wins DESC, win_pct DESC;

-- 4. Top run scorers; wides are excluded from balls faced
WITH batting AS (
    SELECT batsman,
           SUM(batsman_runs) AS runs,
           COUNT(*) FILTER (WHERE COALESCE(is_wide_flag,0) = 0) AS balls_faced,
           COUNT(DISTINCT match_id) AS matches
    FROM deliveries_cleaned
    GROUP BY batsman
)
SELECT batsman, runs, balls_faced, matches,
       ROUND(100.0 * runs / NULLIF(balls_faced,0),2) AS strike_rate
FROM batting
ORDER BY runs DESC
LIMIT 20;

-- 5. Top bowler-credited wicket takers
SELECT bowler, SUM(bowler_wicket) AS wickets,
       SUM(bowler_runs_conceded) AS runs_conceded,
       SUM(is_legal_ball) AS legal_balls,
       ROUND(SUM(bowler_runs_conceded) * 6.0 / NULLIF(SUM(is_legal_ball),0),2) AS economy
FROM deliveries_cleaned
GROUP BY bowler
ORDER BY wickets DESC, economy ASC
LIMIT 20;

-- 6. Innings totals (exclude super-over innings 3+)
SELECT match_id, inning, batting_team, bowling_team,
       SUM(total_runs) AS innings_runs,
       SUM(is_wicket_event) AS wickets,
       SUM(is_legal_ball) AS legal_balls,
       SUM(is_boundary_four) AS fours,
       SUM(is_boundary_six) AS sixes
FROM deliveries_cleaned
WHERE inning IN (1,2)
GROUP BY match_id, inning, batting_team, bowling_team
ORDER BY match_id, inning;

-- 7. Scoring by phase: Powerplay 0-5, Middle 6-14, Death 15+
SELECT over_phase, SUM(total_runs) AS runs,
       SUM(is_legal_ball) AS legal_balls,
       ROUND(SUM(total_runs) * 6.0 / NULLIF(SUM(is_legal_ball),0),2) AS run_rate,
       SUM(is_boundary_four) AS fours,
       SUM(is_boundary_six) AS sixes,
       SUM(is_wicket_event) AS wickets
FROM deliveries_cleaned
WHERE inning IN (1,2)
GROUP BY over_phase
ORDER BY CASE over_phase WHEN 'Powerplay' THEN 1 WHEN 'Middle' THEN 2 ELSE 3 END;

-- 8. Toss winner also won match (decided matches only)
SELECT COUNT(*) AS decided_matches,
       COUNT(*) FILTER (WHERE winner = toss_winner) AS toss_winner_match_wins,
       ROUND(100.0 * COUNT(*) FILTER (WHERE winner = toss_winner) / NULLIF(COUNT(*),0),2) AS pct
FROM matches_cleaned
WHERE winner IS NOT NULL AND toss_winner IS NOT NULL;

-- 9. Toss decision comparison
SELECT toss_decision, COUNT(*) AS matches,
       COUNT(*) FILTER (WHERE winner = toss_winner) AS toss_winner_match_wins,
       ROUND(100.0 * COUNT(*) FILTER (WHERE winner = toss_winner) / NULLIF(COUNT(*),0),2) AS win_pct
FROM matches_cleaned
WHERE winner IS NOT NULL AND toss_winner IS NOT NULL
GROUP BY toss_decision
ORDER BY matches DESC;

-- 10. Venue match volume
SELECT venue, city, COUNT(DISTINCT match_id) AS matches
FROM matches_cleaned
GROUP BY venue, city
ORDER BY matches DESC
LIMIT 20;

-- 11. Season-level results
SELECT season, COUNT(DISTINCT match_id) AS matches,
       COUNT(*) FILTER (WHERE winner IS NOT NULL) AS decided_matches,
       COUNT(*) FILTER (WHERE outcome = 'tie') AS tied_matches,
       COUNT(*) FILTER (WHERE outcome = 'no result') AS no_result_matches
FROM matches_cleaned
GROUP BY season
ORDER BY MIN(date);

-- 12. Player boundary profile
SELECT batsman,
       SUM(is_boundary_four) AS fours,
       SUM(is_boundary_six) AS sixes,
       SUM(batsman_runs) AS batting_runs,
       ROUND(100.0 * SUM(is_boundary_four * 4 + is_boundary_six * 6) /
             NULLIF(SUM(batsman_runs),0),2) AS pct_runs_from_boundaries
FROM deliveries_cleaned
GROUP BY batsman
HAVING SUM(batsman_runs) >= 1000
ORDER BY batting_runs DESC;

-- 13. Most productive player by season
WITH player_season AS (
    SELECT m.season, d.batsman, SUM(d.batsman_runs) AS runs,
           RANK() OVER (PARTITION BY m.season ORDER BY SUM(d.batsman_runs) DESC) AS season_rank
    FROM deliveries_cleaned d
    JOIN matches_cleaned m USING (match_id)
    GROUP BY m.season, d.batsman
)
SELECT season, batsman, runs
FROM player_season
WHERE season_rank = 1
ORDER BY season;

-- 14. Delivery date reconciliation (source dates should align at match level)
SELECT COUNT(*) AS rows_with_date_mismatch
FROM deliveries_cleaned d
JOIN matches_cleaned m USING (match_id)
WHERE d.date <> m.date;

-- 15. Wicket type distribution
SELECT dismissal_kind, COUNT(*) AS dismissals
FROM deliveries_cleaned
WHERE dismissal_kind IS NOT NULL
GROUP BY dismissal_kind
ORDER BY dismissals DESC;
