#!/usr/bin/env python3
"""
run_py.py - run main.py of a Python experiment folder and write expected_output.md (honestly labelled).

  python tools/run_py.py Experiment_08_Database_Connectivity_ML/8A_Titanic            # real MongoDB / MySQL from the environment
  python tools/run_py.py --mock Experiment_08_Database_Connectivity_ML/8A_Titanic     # USE_MOCK_MONGO=1 (mongomock, no server)
Extra arguments after the folder are passed to main.py.
"""
import datetime
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main():
    args = [a for a in sys.argv[1:] if a != "--mock"]
    mock = "--mock" in sys.argv
    if not args:
        print(__doc__); return
    d = Path(args[0]); d = d if d.is_absolute() else ROOT / d
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    if mock:
        env["USE_MOCK_MONGO"] = "1"
    r = subprocess.run([sys.executable, "main.py"] + args[1:], cwd=d, env=env, capture_output=True, text=True, encoding="utf-8")
    out = r.stdout.strip()
    err = "\n".join(l for l in r.stderr.splitlines() if not l.startswith("[!]")).strip()
    banner = ("> **MongoDB part produced with the in-memory `mongomock` emulation (USE_MOCK_MONGO=1) - no MongoDB server was available.** "
              "MySQL parts, if any, ran against a real MySQL 8.0 server. Re-run without `--mock` on a machine with MongoDB for a real transcript. "
              if mock else "> Output of a run against the servers configured in the environment. ")
    md = (f"# Expected output - {d.parent.name} / {d.name}\n\n{banner}Date: {datetime.date.today()}. "
          f"Values such as timings or dates differ between runs.\n\n```text\n{out}\n```\n")
    if err or r.returncode:
        md += f"\n**stderr / exit code {r.returncode}:**\n\n```text\n{err}\n```\n"
    (d / "expected_output.md").write_text(md, encoding="utf-8")
    print(f"{d.name}: exit {r.returncode}, {len(out.splitlines())} lines -> expected_output.md")
    if r.returncode:
        print(err[-1500:]); sys.exit(1)


if __name__ == "__main__":
    main()
