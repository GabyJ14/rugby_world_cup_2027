"""Step 1: audit the Kaggle results.csv before trusting it."""
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
df = pd.read_csv(ROOT / "data" / "raw" / "results.csv", parse_dates=["date"])
aliases = pd.read_csv(ROOT / "data" / "reference" / "team_aliases.csv")

print(f"Rows: {len(df):,}")
print(f"Date range: {df.date.min().date()} → {df.date.max().date()}")

teams = pd.concat([df.home_team, df.away_team])
print("\nMatches per team:\n", teams.value_counts())

unknown = set(teams) - set(aliases.alias)
print("\nTeam names not in team_aliases.csv:", sorted(unknown) or "none")

dupes = df.duplicated(subset=["date", "home_team", "away_team"])
print(f"\nDuplicate matches: {dupes.sum()}")

recent = df[df.date.dt.year >= df.date.dt.year.max() - 9]
print("\nMatches per year (last 10 years):")
print(recent.groupby(recent.date.dt.year).size())

missing = df.isna().sum()
print("\nMissing values:\n", missing[missing > 0])
