# IPL Performance & Match Analytics (2008–2025)

An end-to-end data analytics portfolio project using **Python, SQL, and Power BI**. It explores IPL team performance, player batting and bowling, match outcomes, toss trends, venues, and scoring phases using the supplied match-level and ball-by-ball datasets.

## Project snapshot

| Item | Result |
|---|---:|
| Match records | 1,169 |
| Ball-by-ball records after exact-duplicate removal | 278,202 |
| Seasons | 18 |
| Historical team/franchise labels | 19 |
| Date range | 2008-04-18 to 2025-06-03 |
| Exact duplicate delivery rows removed | 3 |

## Business questions

1. Which recorded team names have the most wins and strongest win percentages?
2. Who are the leading run scorers and what are their strike rates?
3. Which bowlers have the most bowler-credited wickets and what are their economy rates?
4. How do run rates and wickets vary across Powerplay, Middle and Death overs?
5. How often does the toss-winning team also win the match?
6. Which seasons and venues have the most matches?
7. Which players lead the run-scoring chart within each season?

## Data preparation

- Standardized field names to snake_case and parsed date columns.
- Removed **3 exact duplicate delivery rows**; retained all other delivery records.
- Checked match ID referential integrity: all delivery match IDs map to the matches table, and all match IDs have delivery records.
- Created total runs, legal-ball flags, boundary indicators, wicket-event flags, bowler-credited wickets, bowler runs conceded and innings phase.
- Wides and no-balls are excluded from legal balls. Wides are excluded from batter balls faced; no-balls count as balls faced.
- Bowler-credited wicket totals exclude run out, retired hurt, obstructing the field and retired out.
- Standard innings analysis uses innings 1 and 2; super-over innings are excluded where stated.

## Key results from this supplied dataset

- Most wins by recorded team label: **Mumbai Indians** (151).
- Highest aggregate batter runs: **V Kohli** (8,671).
- Most bowler-credited wickets: **YS Chahal** (221).
- Toss winner also won **51.57%** of matches with a recorded winner.
- Run rates: Powerplay **7.97**, Middle **7.87**, Death **10.02** runs per over.

## Important caveats

- Historical team names are kept as recorded. Rebrands (for example, Delhi Daredevils/Delhi Capitals and Kings XI Punjab/Punjab Kings) are not automatically merged. Build and document a franchise mapping if you want franchise-era comparisons.
- The match file has 23 matches without a recorded winner: 15 ties and 8 no-results.
- Apply a minimum balls-faced threshold when comparing batter strike rates and a minimum overs threshold when comparing bowling economy.
- Toss analysis is observational; it does not show that toss decisions cause match outcomes.
- Wicket attribution follows the exclusions above and may differ from third-party leaderboard conventions.
- Cite the original dataset provider, dataset URL and license from the page you downloaded. Do not claim the source data as original work.

## Tools
Python, Pandas, NumPy, Matplotlib, Seaborn, PostgreSQL, Power BI, GitHub.
