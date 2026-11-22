# Combine Kaggle results with transientlunatic internationals into one clean table.
# Run from the project root (opening the .Rproj does this for you).
library(tidyverse)
library(jsonlite)

aliases <- read_csv("data/reference/team_aliases.csv", show_col_types = FALSE)

# ---- 1. Kaggle ---------------------------------------------------------------
kaggle <- read_csv("data/raw/results.csv", show_col_types = FALSE) |>
  mutate(date = as.Date(date), source = "kaggle")

# ---- 2. transientlunatic internationals --------------------------------------
json_dir <- "data/external/transientlunatic-rugby-data/json"
files <- list.files(
  json_dir, full.names = TRUE,
  pattern = "^(rugby-world-cup|six-nations|mid-year-internationals|end-of-year-internationals)"
)

read_matches <- function(path) {
  comp <- str_remove(basename(path), "(-\\d{4})+\\.json$")
  map(fromJSON(path, simplifyVector = FALSE), \(m) tibble(
    date        = as.Date(substr(m$date, 1, 10)),
    home_team   = m$home$team  %||% NA_character_,
    away_team   = m$away$team  %||% NA_character_,
    home_score  = m$home$score %||% NA_integer_,
    away_score  = m$away$score %||% NA_integer_,
    stadium     = m$stadium    %||% NA_character_,
    competition = comp
  )) |> list_rbind()
}

tl <- map(files, read_matches) |> list_rbind() |>
  mutate(world_cup = competition == "rugby-world-cup", source = "transientlunatic")

# ---- 3. Report problems before dropping anything -----------------------------
cat("transientlunatic rows:", nrow(tl), "\n")
cat("  no score (void/cancelled):", sum(is.na(tl$home_score)), "\n")

unmatched <- tl |>
  filter(!is.na(home_score)) |>
  select(home_team, away_team) |>
  pivot_longer(everything(), values_to = "team") |>
  filter(!team %in% aliases$alias) |>
  count(team, sort = TRUE)
cat("\nTeam names not in team_aliases.csv (blank = scraping error):\n")
print(unmatched, n = Inf)

# ---- 4. Standardise team names and combine ------------------------------------
lookup <- select(aliases, alias, team_id, team = canonical_name)

standardise <- function(df) {
  df |>
    inner_join(lookup, by = c("home_team" = "alias")) |>
    rename(home_id = team_id, home = team) |>
    inner_join(lookup, by = c("away_team" = "alias")) |>
    rename(away_id = team_id, away = team) |>
    filter(!is.na(home_score), !is.na(away_score)) |>
    mutate(home_team = home, away_team = away,
           match_key = paste(date, pmin(home_id, away_id), pmax(home_id, away_id))) |>
    select(-home, -away)
}

all_matches <- bind_rows(standardise(kaggle), standardise(tl))

# Same match in both sources: flag score disagreements, keep the Kaggle row
conflicts <- all_matches |>
  group_by(match_key) |>
  filter(n() > 1, n_distinct(home_score + away_score) > 1) |>
  ungroup()
cat("\nMatches where the sources disagree on the score:", n_distinct(conflicts$match_key), "\n")

results_clean <- all_matches |>
  arrange(match_key, source != "kaggle") |>
  distinct(match_key, .keep_all = TRUE) |>
  arrange(date)

write_csv(results_clean, "data/processed/results_clean.csv")
write_csv(conflicts, "data/processed/score_conflicts.csv")
cat("\nSaved", nrow(results_clean), "matches from",
    as.character(min(results_clean$date)), "to", as.character(max(results_clean$date)), "\n")
print(count(results_clean, source))
