#!/usr/bin/env python3
"""Settings › Tabs › the sidebar's two settings (Prefs.swift, Side.swift,
Fold.swift): compact is what an unconfigured browser gets, roomy is drawn at
once and remembered between launches, a value the build doesn't know is
compact again — and the slide speed is the usual pace until asked, is
remembered the same way, and a speed that isn't one is the usual pace again.

Build first (`./build.sh`), then `python3 Tests/sidebar_density.py`. It uses
the split suite's harness: started hidden, no window made or shown,
everything removed afterwards. What can only be seen — the extra room in a
roomy row, how fast the column now slides — is checked by hand, against the
two column pictures this leaves in build/ (density-compact.png,
density-roomy.png).
"""
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import split_view as sv  # noqa: E402

# Its own world, apart from the split suite's in this checkout (see use()).
sv.use("sidebar-density")

t = sv.T()
DENSITY = "sidebar.density"
SLIDE = "sidebar.slideSpeed"
ROOT = Path(__file__).resolve().parents[1]
COMPACT = ROOT / "build" / "density-compact.png"
ROOMY = ROOT / "build" / "density-roomy.png"

def density(): return sv.cmd({"do": "probe"})["sideDensity"]
def ask(what): sv.cmd({"do": "ui", "density": what})
def store(what): subprocess.run(["defaults", "write", sv.SUITE, DENSITY, "-string", what], check=True)
def stored():
    return subprocess.run(["defaults", "read", sv.SUITE, DENSITY], capture_output=True, text=True).stdout.strip()
def speed(): return sv.cmd({"do": "probe"})["sideSlideSpeed"]
def ask_speed(what): sv.cmd({"do": "ui", "slideSpeed": what})
def store_speed(what, kind):
    subprocess.run(["defaults", "write", sv.SUITE, SLIDE, kind, what], check=True)
def stored_speed():
    return subprocess.run(["defaults", "read", sv.SUITE, SLIDE], capture_output=True, text=True).stdout.strip()
def column(path): return sv.cmd({"do": "column", "path": str(path), "height": 720})
def relaunch():
    sv.sp("save"); sv.quit(); sv.launch(); time.sleep(0.5)

try:
    sv.setup(sidebar=True); sv.launch()

    t.ok("nothing stored: Compact, the look everyone has", density() == "compact", density())
    t.ok("nothing stored: the slide is at the usual pace", speed() == 1.0, speed())

    # A few tabs to draw the column with.
    for name in ["alpha", "beta", "gamma"]:
        sv.page(name)
    time.sleep(0.5)

    drawn = column(COMPACT)
    t.ok("the column pictures itself", "saved" in drawn, drawn)

    # Asked for: the sidebar knows at once, without a relaunch.
    ask("roomy")
    t.ok("Roomy asked for: known at once", density() == "roomy", density())
    column(ROOMY)
    t.ok("Roomy draws a different column to Compact",
         COMPACT.exists() and ROOMY.exists() and COMPACT.read_bytes() != ROOMY.read_bytes(),
         (COMPACT.exists(), ROOMY.exists()))

    # The same roomy column in the other appearance: drawn there too.
    light = ROOT / "build" / "density-roomy-light.png"
    sv.cmd({"do": "ui", "look": "light"})
    time.sleep(0.5)
    column(light)
    t.ok("roomy draws in light mode too",
         light.exists() and light.read_bytes() != ROOMY.read_bytes(), light.exists())
    sv.cmd({"do": "ui", "look": "system"})
    time.sleep(0.5)

    # Remembered: the app wrote it out, and a new launch reads it back.
    # The slide speed set alongside it rides the same relaunch.
    ask_speed(0.6)
    t.ok("a slower slide asked for: known at once", speed() == 0.6, speed())
    relaunch()
    t.ok("the choice was written out", stored() == "roomy", stored())
    t.ok("and a new launch reads it back", density() == "roomy", density())
    t.ok("the slower slide was written out too", stored_speed().startswith("0.6"), stored_speed())
    t.ok("and a new launch slides at it", speed() == 0.6, speed())

    # Back to Compact the same way.
    ask("compact")
    t.ok("Compact asked for: known at once", density() == "compact", density())

    # A value this build doesn't know falls back to Compact rather than
    # drawing something odd; a speed that isn't one falls back to the pace
    # everyone gets.
    store("enormous"); store_speed("sideways", "-string")
    sv.quit(); sv.launch(); time.sleep(0.5)
    t.ok("a value this build doesn't know is Compact again", density() == "compact", density())
    t.ok("a speed that isn't one is the usual pace again", speed() == 1.0, speed())
finally:
    t.done(); sv.finish()
sys.exit(1 if t.failed else 0)
