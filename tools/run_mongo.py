#!/usr/bin/env python3
"""
run_mongo.py - run a MongoDB experiment variation and (re)generate its expected_output.md and README.md.

  python tools/run_mongo.py Experiment_07_MongoDB/7A_Blog            # uses the in-memory test shim (no server needed)
  python tools/run_mongo.py --real Experiment_07_MongoDB/7A_Blog     # uses a real `mongosh` (MONGODB_URI, default mongodb://localhost:27017)
  python tools/run_mongo.py --all

The scripts to run, in order, are listed in <variation>/run_order.txt (one file name per line).
Without --real the scripts are executed by tools/mongosh_shim.js (mingo based emulation) - clearly marked in the output file.
"""
import datetime
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BANNER_SHIM = ("> **How this output was produced.** No MongoDB server was available, so the scripts were executed by `tools/mongosh_shim.js`, "
               "an in-memory emulation of the mongosh API built on the `mingo` library (query/aggregation/update operators are evaluated by mingo; "
               "`explain()` plans are *simulated*). The logic and results are therefore verified, but this is **not** a transcript of a real MongoDB 7 server - "
               "re-run with `python tools/run_mongo.py --real <folder>` (or the mongosh commands in README.md) to produce a real transcript. "
               "ObjectIds are deterministic placeholders. Run date: {date}.")
BANNER_REAL = ("> **ACTUAL OUTPUT of a real `mongosh`** run against {uri} on {date}. Server-generated values (ObjectIds, timestamps, execution times) differ between runs.")


def run(vdir, real):
    vdir = Path(vdir)
    if not vdir.is_absolute():
        vdir = ROOT / vdir
    order = [l.strip() for l in (vdir / "run_order.txt").read_text(encoding="utf-8").splitlines() if l.strip() and not l.startswith("#")]
    print(f"== {vdir.parent.name}/{vdir.name}: {' -> '.join(order)}")
    if real:
        uri = os.environ.get("MONGODB_URI", "mongodb://localhost:27017")
        sections = []
        for f in order:
            r = subprocess.run(["mongosh", uri, "--quiet", "--file", str(vdir / f)], capture_output=True, text=True, encoding="utf-8")
            sections.append((f, r.stdout + (("\n[stderr]\n" + r.stderr) if r.returncode else "")))
        banner = BANNER_REAL.format(uri=uri, date=datetime.date.today())
    else:
        r = subprocess.run(["node", str(ROOT / "tools" / "mongosh_shim.js")] + [str(vdir / f) for f in order],
                           capture_output=True, text=True, encoding="utf-8", cwd=str(ROOT))
        if r.returncode:
            print(r.stdout[-1500:], r.stderr[-2500:])
            sys.exit(f"!! {vdir.name}: a script failed")
        sections, cur, buf = [], None, []
        for line in r.stdout.splitlines():
            if line.startswith("##FILE "):
                if cur:
                    sections.append((cur, "\n".join(buf)))
                cur, buf = line[7:], []
            else:
                buf.append(line)
        if cur:
            sections.append((cur, "\n".join(buf)))
        banner = BANNER_SHIM.format(date=datetime.date.today())
    md = [f"# Expected output - {vdir.parent.name} / {vdir.name}\n", banner + "\n"]
    for f, out in sections:
        md.append(f"## `{f}`\n\n```text\n{out.strip()}\n```\n")
    (vdir / "expected_output.md").write_text("\n".join(md), encoding="utf-8")
    runlines = "\n".join(f"mongosh --quiet --file {f}" for f in order)
    ps_lines = "\n".join(f"mongosh --quiet --file {f}" for f in order)
    extra = ""
    rd = f"""# {vdir.parent.name} / {vdir.name}

Requires MongoDB 7 and `mongosh` (or Compass' embedded shell). Every script starts with `db = db.getSiblingDB(...)`, so each file can be run on its own
(in the order below because later files use the data created by earlier ones). All scripts are re-runnable: they drop / reload their own collections.

```bash
# from this folder, against mongodb://localhost:27017
{runlines}
```

Or against another server: `mongosh "mongodb://user:pass@host:27017" --quiet --file schema.js`.

| File | Purpose |
|------|---------|
| `schema.js` | database / collections with `$jsonSchema` validation |
| `insert_data.js` | the documents given in the PDF |
| `crud.js` | update / delete tasks (`$set`, `$inc`, `$push`, `$pull`, `$addToSet`, ...) |
| `queries.js` | find / projection / operators / sort / limit tasks |
| `aggregation.js` | pipeline tasks |
| `indexes.js` | single, compound and text indexes + `explain()` |
| `expected_output.md` | transcript of the scripts (see the note at its top about how it was produced) |
| `explanation.md` | document structure diagram + explanation of every task |
| `viva_questions.md` | viva Q&A |
{extra}
Test without a server: `python ../../tools/run_mongo.py {vdir.parent.name}/{vdir.name}` (needs `npm install` once in the repository root).
"""
    (vdir / "README.md").write_text(rd, encoding="utf-8")


def main():
    args = [a for a in sys.argv[1:] if a != "--real"]
    real = "--real" in sys.argv
    if not args:
        print(__doc__); return
    if args[0] == "--all":
        targets = sorted(p.parent for p in ROOT.glob("Experiment_0[79]*/*/run_order.txt"))
    else:
        targets = args
    for t in targets:
        run(t, real)


if __name__ == "__main__":
    main()
