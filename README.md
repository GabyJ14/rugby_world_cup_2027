# Rugby World Cup 2027: Stats & Predictions

Player and team statistics for the men's Rugby World Cup 2027 (Australia, 1 Oct – 13 Nov 2027),
and a model that predicts match winners and scores.

## Project status
- [x] Repo setup
- [ ] Data collection (results, players, rankings)
- [ ] Data cleaning & validation
- [ ] Team & player stats
- [ ] Prediction model (Elo → score model → tournament simulation)
- [ ] Website

## Repo layout
| Folder | What's in it | Committed? |
|---|---|---|
| `data/raw/` | Files downloaded by hand (e.g. Kaggle) | No |
| `data/external/` | Other people's repos/datasets, fetched by scripts | No |
| `data/reference/` | Hand-made lookup tables (team aliases) | Yes |
| `data/processed/` | Small, cleaned outputs | Yes |
| `src/rugby/` | Reusable Python code | Yes |
| `scripts/` | Runnable pipeline steps | Yes |
| `notebooks/` | Exploration | Yes |

## Getting started
```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python scripts/fetch_external.py      # clones the external data repos
python scripts/audit_results.py       # checks the Kaggle results.csv
```

## Data sources
See [data/SOURCES.md](data/SOURCES.md).
