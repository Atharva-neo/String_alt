#!/usr/bin/env python3
"""
fd_tools.py - small functional-dependency toolbox used by Experiment 3.

Everything is exact set arithmetic (no heuristics):
  closure(attrs, fds)                     attribute closure X+
  candidate_keys(attributes, fds)         all minimal keys
  is_superkey(x, attributes, fds)
  bcnf_violations(attributes, fds)        FDs whose determinant is not a superkey (restricted to `attributes`)
  third_nf_violations(attributes, fds)    FDs violating 3NF (determinant not superkey AND dependent not prime)
  second_nf_violations(attributes, fds)   partial dependencies
  lossless_join(attributes, decomposition, fds)   tableau (chase) test
  dependency_preserved(attributes, decomposition, fds)  returns (bool, lost_fds)
  project_fds(sub_attributes, fds)        FDs that hold on a sub-relation (via closures)
FDs are a list of (lhs, rhs) with lhs/rhs given as strings "A,B" or iterables.
"""
from itertools import combinations


def S(x):
    if isinstance(x, str):
        return frozenset(a.strip() for a in x.split(",") if a.strip())
    return frozenset(x)


def norm(fds):
    return [(S(l), S(r)) for l, r in fds]


def fmt(x):
    return "{" + ", ".join(sorted(x)) + "}"


def closure(attrs, fds):
    result = set(S(attrs))
    fds = norm(fds)
    changed = True
    while changed:
        changed = False
        for l, r in fds:
            if l <= result and not r <= result:
                result |= r
                changed = True
    return frozenset(result)


def is_superkey(x, attributes, fds):
    return closure(x, fds) >= S(attributes)


def candidate_keys(attributes, fds):
    attributes = S(attributes)
    keys = []
    for size in range(1, len(attributes) + 1):
        for combo in combinations(sorted(attributes), size):
            c = frozenset(combo)
            if any(k <= c for k in keys):
                continue
            if closure(c, fds) >= attributes:
                keys.append(c)
    return keys


def prime_attributes(attributes, fds):
    return frozenset().union(*candidate_keys(attributes, fds)) if attributes else frozenset()


def project_fds(sub, fds):
    """All non-trivial FDs X -> A (A single attribute) that hold on the sub-relation."""
    sub = S(sub)
    out = []
    for size in range(1, len(sub) + 1):
        for combo in combinations(sorted(sub), size):
            x = frozenset(combo)
            rhs = (closure(x, fds) & sub) - x
            for l, r in out:               # drop what a smaller determinant already gives (keeps FDs minimal)
                if l < x:
                    rhs -= r
            if rhs:
                out.append((x, rhs))
    return out


def bcnf_violations(attributes, fds):
    attributes = S(attributes)
    bad = []
    for l, r in project_fds(attributes, fds):
        if not closure(l, fds) >= attributes:
            bad.append((l, r))
    return bad


def third_nf_violations(attributes, fds):
    attributes = S(attributes)
    prime = prime_attributes(attributes, project_fds(attributes, fds))
    return [(l, r) for l, r in bcnf_violations(attributes, fds) if not r <= prime]


def second_nf_violations(attributes, fds):
    """Partial dependencies: a proper subset of some candidate key determines a non-prime attribute."""
    attributes = S(attributes)
    proj = project_fds(attributes, fds)
    keys = candidate_keys(attributes, proj)
    prime = frozenset().union(*keys)
    bad = []
    for l, r in proj:
        if r <= prime:
            continue
        if any(l < k for k in keys):
            bad.append((l, r))
    return bad


def lossless_join(attributes, decomposition, fds):
    """Chase / tableau test. Returns True if the decomposition has a lossless join."""
    attributes = sorted(S(attributes))
    parts = [S(p) for p in decomposition]
    fds = norm(fds)
    table = [{a: ("a_" + a if a in p else f"b_{i}_{a}") for a in attributes} for i, p in enumerate(parts)]
    changed = True
    while changed:
        changed = False
        for l, r in fds:
            groups = {}
            for row in table:
                groups.setdefault(tuple(row[a] for a in sorted(l)), []).append(row)
            for rows in groups.values():
                if len(rows) < 2:
                    continue
                for a in r:
                    vals = {row[a] for row in rows}
                    if len(vals) > 1:
                        target = next((v for v in vals if v.startswith("a_")), sorted(vals)[0])
                        for old in vals - {target}:
                            for other in table:
                                if other[a] == old:
                                    other[a] = target
                        changed = True
    return any(all(row[a] == "a_" + a for a in attributes) for row in table)


def dependency_preserved(attributes, decomposition, fds):
    """Classic algorithm: for each FD X->Y iterate Z = X; Z = Z u (closure(Z n Ri) n Ri) until stable."""
    parts = [S(p) for p in decomposition]
    lost = []
    for l, r in norm(fds):
        z = set(l)
        changed = True
        while changed:
            changed = False
            for p in parts:
                add = closure(z & p, fds) & p
                if not add <= z:
                    z |= add
                    changed = True
        if not r <= z:
            lost.append((l, r))
    return (not lost, lost)


# ----------------------------------------------------------------------------------
def report(title, attributes, fds, closures_of=(), decomposition=None, analyse=True):
    """Pretty printer used by the fd_analysis.py scripts."""
    print(f"=== {title} ===")
    print("Attributes :", fmt(S(attributes)))
    print("FDs        :", "; ".join(f"{fmt(l)} -> {fmt(r)}" for l, r in norm(fds)))
    for c in closures_of:
        print(f"Closure {fmt(S(c))}+ = {fmt(closure(c, fds))}")
    if analyse:
        keys = candidate_keys(attributes, fds)
        print("Candidate keys :", ", ".join(fmt(k) for k in keys))
        print("Prime attributes :", fmt(prime_attributes(attributes, fds)))
        show = lambda v: "; ".join(f"{fmt(l)}->{fmt(r)}" for l, r in v) or "none"
        print("Partial dependencies (2NF violations) :", show(second_nf_violations(attributes, fds)))
        print("3NF violations :", show(third_nf_violations(attributes, fds)))
        print("BCNF violations :", show(bcnf_violations(attributes, fds)))
    if decomposition:
        print("Decomposition :", " | ".join(fmt(S(d)) for d in decomposition))
        print("Lossless join :", lossless_join(attributes, decomposition, fds))
        ok, lost = dependency_preserved(attributes, decomposition, fds)
        print("Dependency preserving :", ok, "" if ok else "lost: " + "; ".join(f"{fmt(l)}->{fmt(r)}" for l, r in lost))
        for d in decomposition:
            print(f"  relation {fmt(S(d))}: keys {[fmt(k) for k in candidate_keys(d, project_fds(d, fds))]}, "
                  f"BCNF violations {[f'{fmt(l)}->{fmt(r)}' for l, r in bcnf_violations(d, fds)] or 'none'}")
    print()
