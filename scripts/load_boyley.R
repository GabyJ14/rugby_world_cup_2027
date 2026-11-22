# Flatten andrewboyley/rugby-data's dataset.json into tidy tables:
#   boyley_games.csv   one row per match (teams, scores, venue, competition)
#   appearances.csv    one row per player per match (who played, starter or bench)
#   players.csv        one row per player with appearance totals
# Run from the project root after building the dataset (see README).
library(tidyverse)
library(jsonlite)

ds <- fromJSON("data/external/boyley-rugby-data/data/dataset.json",
               simplifyVector = FALSE)
cat("Dataset generated at:", ds$generatedAt, "\n")

aliases <- read_csv("data/reference/team_aliases.csv", show_col_types = FALSE)

# ---- Lookup tables from the registries ---------------------------------------
teams <- imap(ds$teams, \(t, id) tibble(
  boyley_team_id = id, boyley_team_name = t$name %||% NA_character_
)) |> list_rbind() |>
  left_join(distinct(aliases, alias, team_id, canonical_name),
            by = c("boyley_team_name" = "alias"))

venues <- imap(ds$venues, \(v, id) tibble(
  venue_id = id, stadium = v$name %||% NA_character_,
  city = v$city %||% NA_character_, country = v$country %||% NA_character_
)) |> list_rbind()

leagues <- imap(ds$leagues, \(l, id) tibble(
  league_id = id, competition = l$name %||% NA_character_
)) |> list_rbind()

players <- imap(ds$players, \(name, id) tibble(player_id = id, player_name = name)) |>
  list_rbind()

cat("\nBoyley team names not in team_aliases.csv:\n")
print(filter(teams, is.na(team_id)) |> select(boyley_team_id, boyley_team_name), n = Inf)

# ---- One row per team per game ------------------------------------------------
sides <- map(ds$games, \(g) map(g$competitors, \(c) tibble(
  event_id       = g$eventId,
  date           = as.Date(substr(g$date %||% NA_character_, 1, 10)),
  venue_id       = g$venueId  %||% NA_character_,
  league_id      = g$leagueId %||% NA_character_,
  boyley_team_id = as.character(c$teamId),
  home           = c$home,
  score          = c$score %||% NA_integer_,
  roster         = list(c$roster)
)) |> list_rbind()) |> list_rbind() |>
  left_join(teams, by = "boyley_team_id")

# ---- Keep only Tests: both sides must be national teams in team_aliases.csv ----
# Tour matches against club/franchise sides (e.g. Stormers, Bulls) are not caps.
non_tests <- sides |> filter(is.na(team_id)) |> distinct(event_id, date, boyley_team_name)
cat("\nDropping", nrow(non_tests), "non-Test matches:\n")
print(non_tests, n = Inf)
sides <- anti_join(sides, non_tests, by = "event_id")

# ---- Games table (same shape as results_clean.csv) ----------------------------
games <- sides |>
  select(event_id, date, venue_id, league_id, home, team = canonical_name,
         team_id, score, boyley_team_name) |>
  pivot_wider(id_cols = c(event_id, date, venue_id, league_id),
              names_from = home, values_from = c(team, team_id, score, boyley_team_name)) |>
  transmute(event_id, date,
            home_team = team_TRUE, away_team = team_FALSE,
            home_score = score_TRUE, away_score = score_FALSE,
            home_id = team_id_TRUE, away_id = team_id_FALSE,
            venue_id, league_id) |>
  left_join(venues, by = "venue_id") |>
  left_join(leagues, by = "league_id")

# ---- Appearances table ---------------------------------------------------------
appearances <- sides |>
  select(event_id, date, team = canonical_name, team_id, boyley_team_name, roster) |>
  unnest_longer(roster) |>
  mutate(player_id = map_chr(roster, \(r) as.character(r$playerId)),
         jersey    = map_int(roster, \(r) as.integer(r$jersey %||% NA_integer_)),
         starter   = jersey <= 15) |>
  select(-roster) |>
  left_join(players, by = "player_id")

player_summary <- appearances |>
  group_by(player_id, player_name) |>
  summarise(team = names(which.max(table(coalesce(team, boyley_team_name)))),
            appearances = n(), starts = sum(starter, na.rm = TRUE),
            first_match = min(date), last_match = max(date), .groups = "drop") |>
  arrange(desc(appearances))

# ---- Save ---------------------------------------------------------------------
write_csv(games, "data/processed/boyley_games.csv")
write_csv(appearances, "data/processed/appearances.csv")
write_csv(player_summary, "data/processed/players.csv")

cat("\nGames:", nrow(games), "| Appearances:", nrow(appearances),
    "| Players:", nrow(player_summary), "\n")
cat("Date range:", as.character(min(games$date, na.rm = TRUE)), "to",
    as.character(max(games$date, na.rm = TRUE)), "\n")
print(head(player_summary, 10))

