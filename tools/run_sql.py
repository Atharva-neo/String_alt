#!/usr/bin/env python3
"""
run_sql.py - execute a SQL experiment variation against a real MySQL 8 server
and regenerate its 05_expected_output.md, 06_explanation.md and README.md.

Usage
-----
  python tools/run_sql.py Experiment_01_SQL_Basics/1A_Library
  python tools/run_sql.py --all                # every variation that has 03_implementation.sql

Connection (environment variables, see .env.example):
  MYSQL_BIN (default "mysql"), MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PWD

Conventions inside the .sql files
---------------------------------
  -- @DB name                      (01_schema.sql)  database used for all later scripts
  /* @ER ... */                    (01_schema.sql)  Mermaid ER diagram, copied to 06_explanation.md
  /* @CONCEPTS ... */              (03_implementation.sql) markdown concept notes
  -- ### TASK <n>: <title>         starts a task chunk (each chunk runs in its own mysql session)
  -- ### ADV <n>: <title>          same, for 04_advanced_queries.sql
  -- @as <user> <password>         following "-- | " lines run in a separate session as that user
  -- | <sql>                       statement executed as the user named by the last "-- @as"
Comment lines directly under a "-- ###" header are the explanation of the task.
"""
import os
import re
import subprocess
import sys
import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MYSQL = os.environ.get("MYSQL_BIN", "mysql")
HOST = os.environ.get("MYSQL_HOST", "127.0.0.1")
PORT = os.environ.get("MYSQL_PORT", "3306")
USER = os.environ.get("MYSQL_USER", "root")

HEADER = re.compile(r"^-- ### (\S+?) (\S+?): (.*)$")


def run_mysql(sql, db=None, user=None, pwd=None):
    """Run SQL text in a fresh mysql CLI session; return merged stdout+stderr."""
    env = dict(os.environ)
    if pwd is not None:
        env["MYSQL_PWD"] = pwd
    elif user is None:
        env.setdefault("MYSQL_PWD", os.environ.get("MYSQL_PWD", ""))
    cmd = [MYSQL, "-h", HOST, "-P", PORT, "-u", user or USER, "--table", "--force",
           "--unbuffered", "-vvv", "--default-character-set=utf8mb4"]
    if db:
        cmd.append(db)
    p = subprocess.run(cmd, input=sql.encode("utf-8"), stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, env=env)
    return clean(p.stdout.decode("utf-8", "replace"))


def clean(text):
    out = []
    for line in text.replace("\r\n", "\n").split("\n"):
        if line.startswith("mysql: [Warning]") or line == "Bye":
            continue
        out.append(line.rstrip())
    text = "\n".join(out)
    text = re.sub(r" \(\d+(\.\d+)? sec\)", "", text)          # drop volatile timings
    text = re.sub(r"\n-{10,}\n", "\n", text)                    # drop -vvv separators
    text = re.sub(r"^-{10,}\n", "", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def parse_chunks(path):
    """Split a script into chunks at '-- ### LABEL N: title' markers."""
    chunks, cur = [], None
    for line in path.read_text(encoding="utf-8").split("\n"):
        m = HEADER.match(line)
        if m:
            cur = {"kind": m.group(1), "n": m.group(2), "title": m.group(3).strip(), "lines": []}
            chunks.append(cur)
        elif cur is not None:
            cur["lines"].append(line)
    for c in chunks:
        why, body, seen_sql = [], [], False
        for ln in c["lines"]:
            if (not seen_sql and ln.startswith("--") and not ln.startswith("-- @") and not ln.startswith("-- |")
                    and not re.match(r"^-- S\d>", ln)):
                why.append(ln[2:].strip())
            elif not seen_sql and ln.strip() == "":
                continue
            else:
                seen_sql = True
                body.append(ln)
        c["why"] = " ".join(w for w in why if w)
        c["body"] = "\n".join(body).strip("\n")
    return chunks


def segments(body):
    """Split chunk body into [(user, pwd, sql)] segments preserving order."""
    segs, root, user_seg, cur_user = [], [], [], None
    def flush_root():
        if any(l.strip() for l in root):
            segs.append((None, None, "\n".join(root)))
        root.clear()
    def flush_user():
        if user_seg:
            segs.append((cur_user[0], cur_user[1], "\n".join(user_seg)))
        user_seg.clear()
    for ln in body.split("\n"):
        m = re.match(r"^-- @as (\S+) (\S+)", ln)
        if m:
            flush_root(); flush_user(); cur_user = (m.group(1), m.group(2)); continue
        if ln.startswith("-- | ") or ln == "-- |":
            user_seg.append(ln[5:] if ln.startswith("-- | ") else "")
            continue
        flush_user()
        root.append(ln)
    flush_user(); flush_root()
    return segs


def run_chunk(c, db):
    parts = []
    for user, pwd, sql in segments(c["body"]):
        out = run_mysql(sql, db=db, user=user, pwd=pwd)
        if user:
            out = f"[session: user '{user}']\n{out}"
        parts.append(out)
    return "\n\n".join(p for p in parts if p) or "(statement(s) executed with no output)"


def extract_block(text, tag):
    m = re.search(r"/\*\s*@" + tag + r"\b(.*?)\*/", text, re.S)
    return m.group(1).strip("\n") if m else ""


def build(vdir):
    vdir = (ROOT / vdir).resolve() if not Path(vdir).is_absolute() else Path(vdir)
    sch = (vdir / "01_schema.sql").read_text(encoding="utf-8")
    db = re.search(r"-- @DB (\S+)", sch).group(1)
    stamp = datetime.date.today().isoformat()
    version = run_mysql("SELECT VERSION();").split("\n")[-2].strip("| ").strip() if False else \
        [l for l in run_mysql("SELECT VERSION() AS v;").split("\n") if re.search(r"\d+\.\d+\.\d+", l)][0].strip("| ").strip()
    print(f"== {vdir.name}  (db={db}, MySQL {version})")

    noexec = "-- @NOEXEC" in sch      # concurrency experiments: transcript comes from run_demo.py only
    if not noexec:
        setup_out = run_mysql(sch) + "\n" + run_mysql((vdir / "02_sample_data.sql").read_text(encoding="utf-8"), db=db)
        if "ERROR" in setup_out:
            print("!! setup scripts failed:\n", setup_out); sys.exit(1)

    impl = vdir / "03_implementation.sql"
    sections = []
    for fname, label in (("03_implementation.sql", "Core tasks (from the PDF)"),
                         ("04_advanced_queries.sql", "Advanced / examiner-style queries")):
        f = vdir / fname
        if not f.exists():
            continue
        sections.append((label, fname, parse_chunks(f)))
    results = {}
    for label, fname, chunks in sections:
        for c in chunks:
            results[(fname, c["n"])] = "" if noexec else run_chunk(c, db)

    # ---- 05_expected_output.md -------------------------------------------------
    md = [f"# Expected output - {vdir.parent.name} / {vdir.name}\n",
          f"> **ACTUAL OUTPUT.** Every block below was produced by running the scripts, in order "
          f"(`01_schema.sql` -> `02_sample_data.sql` -> `03_implementation.sql` -> `04_advanced_queries.sql`), "
          f"on **MySQL {version}** on **{stamp}** via `tools/run_sql.py`. Nothing here is hand-typed.  \n"
          f"> Date-dependent results (`CURRENT_DATE`, `NOW()`) will differ when you run them on another day.  \n"
          f"> Each task runs in its own client session; lines starting with `ERROR` are *intended* negative tests.\n"]
    for label, fname, chunks in ([] if noexec else sections):
        md.append(f"\n## {label}\n")
        for c in chunks:
            md.append(f"### {c['kind'].title()} {c['n']} - {c['title']}\n")
            md.append("```sql\n" + c["body"] + "\n```\n")
            md.append("**Output**\n\n```text\n" + results[(fname, c["n"])] + "\n```\n")
            if c["why"]:
                md.append(f"**Why this output is correct:** {c['why']}\n")
    fd = vdir / "fd_analysis.py"
    if fd.exists():                       # Experiment 3: attribute closures, keys, normal-form checks
        out = subprocess.run([sys.executable, str(fd)], capture_output=True, text=True, encoding="utf-8").stdout
        md.append("\n## Functional-dependency analysis (Python, `fd_analysis.py`)\n")
        md.append("```text\n" + out.strip() + "\n```\n")
    demo = vdir / "run_demo.py"
    if demo.exists():                     # Experiments 4/5: real multi-session transcript
        r = subprocess.run([sys.executable, str(demo), "--emit"], capture_output=True, text=True, encoding="utf-8", cwd=str(vdir))
        out = r.stdout + (("\n[stderr]\n" + r.stderr) if r.returncode else "")
        md.append("\n## Multi-session demonstration (`run_demo.py`, real connections)\n")
        md.append("> Each `S1>`/`S2>` line is a statement sent by a separate MySQL connection; the lines below it are the server's answer.\n")
        md.append(out.strip().replace("\n### Task", "\n#### Task") + "\n")
    (vdir / "05_expected_output.md").write_text("\n".join(md), encoding="utf-8")

    # ---- 06_explanation.md -----------------------------------------------------
    er = extract_block(sch, "ER")
    concepts = extract_block(impl.read_text(encoding="utf-8"), "CONCEPTS")
    ex = [f"# Explanation - {vdir.name.replace('_', ' ')}\n"]
    if er:
        ex.append("## ER / structure diagram\n\n```mermaid\n" + er + "\n```\n")
    if concepts:
        ex.append("## Concepts used\n\n" + concepts + "\n")
    ex.append("## Task-by-task logic\n")
    for label, fname, chunks in sections:
        ex.append(f"\n### {label}\n")
        for c in chunks:
            ex.append(f"**{c['kind'].title()} {c['n']} - {c['title']}**  \n{c['why'] or ''}\n")
    (vdir / "06_explanation.md").write_text("\n".join(ex), encoding="utf-8")

    # ---- README.md -------------------------------------------------------------
    extra = ""
    if (vdir / "00_derivation.md").exists():
        extra += "| `00_derivation.md` | step-by-step normalisation derivation with dependency diagrams |\n"
    if (vdir / "fd_analysis.py").exists():
        extra += "| `fd_analysis.py` | attribute closures, candidate keys, normal-form and lossless-join checks (`python fd_analysis.py`) |\n"
    if (vdir / "run_demo.py").exists():
        extra += ("| `run_demo.py` | replays the multi-session tasks with real connections (`python run_demo.py [--emit]`) |\n"
                  "| `session1.sql`, `session2.sql` | the same steps per terminal for a manual two-terminal run |\n")
    if (vdir / "DURABILITY.md").exists():
        extra += "| `DURABILITY.md`, `durability_demo.py` | commit -> crash/restart -> data still there (Task 11) |\n"
    if noexec:
        extra += ("\n**Two-terminal experiment.** `03_implementation.sql` is a script for two terminals (lines `-- S1>` / `-- S2>`); "
                  "`05_expected_output.md` is the transcript of `run_demo.py` (needs `pip install mysql-connector-python`).\n"
                  "The demo uses real locks and waits: it needs a MySQL server where the user may create databases (and, in 5B Task 10, `SET GLOBAL`).\n")
    rd = f"""# {vdir.parent.name} / {vdir.name}

Database name: `{db}` (created by `01_schema.sql`; safe to re-run, it drops and recreates it).

## Run order

```bash
mysql -u root -p < 01_schema.sql
mysql -u root -p {db} < 02_sample_data.sql
mysql -u root -p {db} < 03_implementation.sql      # all numbered tasks of the PDF
mysql -u root -p {db} < 04_advanced_queries.sql    # extra examiner-style queries
```

Or let the helper run everything and rebuild the output file:

```bash
python tools/run_sql.py {vdir.parent.name}/{vdir.name}
```

| File | Purpose |
|------|---------|
| `01_schema.sql` | database + tables (+ ER diagram in a comment) |
| `02_sample_data.sql` | the exact rows given in the PDF |
| `03_implementation.sql` | every numbered task, with comments |
| `04_advanced_queries.sql` | additional examiner-style queries |
| `05_expected_output.md` | **real** output captured from MySQL {version} |
| `06_explanation.md` | ER diagram, concepts, task-by-task logic |
| `07_viva_questions.md` | viva Q&A |
{extra}
Notes: lines starting `-- |` in `03_implementation.sql` are statements that must be typed in a
*second terminal as another MySQL user*; they are comments so that a plain `mysql < file` run stays safe.
"""
    (vdir / "README.md").write_text(rd, encoding="utf-8")
    bad = [k for k, v in results.items() if "ERROR" in v]
    print(f"   {len(results)} chunks run; {len(bad)} contain ERROR lines (expected for negative tests only)")


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__); return
    if args[0] == "--all":
        targets = sorted(p.parent for p in ROOT.glob("Experiment_0[1-6]*/*/03_implementation.sql"))
    else:
        targets = args
    for t in targets:
        build(t)


if __name__ == "__main__":
    main()
