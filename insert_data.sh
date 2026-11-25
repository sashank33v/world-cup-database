#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
set -e

VALUES=""

while IFS=, read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
    if [[ "$YEAR" == "year" ]]; then
        continue
    fi

    WINNER=${WINNER//\'/\'\'}
    OPPONENT=${OPPONENT//\'/\'\'}
    ROUND=${ROUND//\'/\'\'}
    OPPONENT_GOALS=${OPPONENT_GOALS%$'\r'}

    VALUES+="($YEAR, '$ROUND', '$WINNER', '$OPPONENT', $WINNER_GOALS, $OPPONENT_GOALS),"

done < games.csv

VALUES=${VALUES%,}

$PSQL "
BEGIN;

TRUNCATE TABLE games, teams RESTART IDENTITY;

CREATE TEMP TABLE game_data (
    year INT,
    round VARCHAR(100),
    winner VARCHAR(100),
    opponent VARCHAR(100),
    winner_goals INT,
    opponent_goals INT
) ON COMMIT DROP;

INSERT INTO game_data VALUES $VALUES;

INSERT INTO teams(name)
SELECT winner FROM game_data
UNION
SELECT opponent FROM game_data;

INSERT INTO games(
    year,
    round,
    winner_id,
    opponent_id,
    winner_goals,
    opponent_goals
)
SELECT
    g.year,
    g.round,
    w.team_id,
    o.team_id,
    g.winner_goals,
    g.opponent_goals
FROM game_data g
JOIN teams w ON g.winner = w.name
JOIN teams o ON g.opponent = o.name;

COMMIT;
"