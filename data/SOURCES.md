# Data sources & attribution

| Source | What I use it for | Licence | How it's obtained |
|---|---|---|---|
| Kaggle tier-one international results (from Wikipedia) | Historical test results, 10 tier-one nations | Check the Kaggle dataset page | Manual download → `data/raw/results.csv` |
| [andrewboyley/rugby-data](https://github.com/andrewboyley/rugby-data) | International matches, players, lineups (World Rugby RIMS + ESPN) | MIT | `scripts/fetch_external.py`, then built locally |
| [transientlunatic/Rugby-Data](https://github.com/transientlunatic/Rugby-Data) | Club competitions, internationals to 2020 | No licence listed, not redistributed | `scripts/fetch_external.py` |

Raw and external data are not committed to this repo. Run the scripts to reproduce them.
