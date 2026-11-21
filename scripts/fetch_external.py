"""Clone or update external data repos into data/external/ (not committed)."""
import subprocess
from pathlib import Path

EXTERNAL = Path(__file__).resolve().parents[1] / "data" / "external"
REPOS = {
    "boyley-rugby-data": "https://github.com/andrewboyley/rugby-data.git",
    "transientlunatic-rugby-data": "https://github.com/transientlunatic/Rugby-Data.git",
}

for name, url in REPOS.items():
    target = EXTERNAL / name
    if target.exists():
        print(f"Updating {name}")
        subprocess.run(["git", "-C", str(target), "pull", "--ff-only"], check=True)
    else:
        print(f"Cloning {name}")
        subprocess.run(["git", "clone", "--depth", "1", url, str(target)], check=True)
