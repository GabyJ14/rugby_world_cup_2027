library(tidyverse)

df <- read_csv("data/raw/results.csv")
aliases <- read_csv("data/reference/team_aliases.csv")

cat("Rows:", nrow(df), "\n")
cat("Date range:", as.character(min(df$date)), "to", as.character(max(df$date)), "\n")

teams <- c(df$home_team, df$away_team)
print(sort(table(teams), decreasing = TRUE))

cat("Names not in aliases:", setdiff(unique(teams), aliases$alias), "\n")
cat("Duplicates:", sum(duplicated(df[c("date", "home_team", "away_team")])), "\n")

df |> count(year = year(date)) |> tail(10) |> print()
colSums(is.na(df))