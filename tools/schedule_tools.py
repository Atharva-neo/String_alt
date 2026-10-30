#!/usr/bin/env python3
"""
schedule_tools.py - conflict-serializability test (precedence graph) and wait-for-graph cycle detection.

A schedule is a list of (transaction, operation, item) with operation 'R' or 'W', e.g.
    [("T1","R","X"), ("T2","R","X"), ("T1","W","X"), ("T2","W","X")]
Two operations conflict when they belong to different transactions, touch the same item and at least one is a write.
"""


def precedence_graph(schedule):
    edges = set()
    for i, (t1, o1, x1) in enumerate(schedule):
        for t2, o2, x2 in schedule[i + 1:]:
            if t1 != t2 and x1 == x2 and "W" in (o1, o2):
                edges.add((t1, t2))
    return sorted(edges)


def find_cycle(edges):
    graph = {}
    for a, b in edges:
        graph.setdefault(a, []).append(b)
        graph.setdefault(b, [])
    state, stack = {}, []

    def dfs(u):
        state[u] = 1
        stack.append(u)
        for v in graph[u]:
            if state.get(v, 0) == 1:
                return stack[stack.index(v):] + [v]
            if state.get(v, 0) == 0:
                c = dfs(v)
                if c:
                    return c
        stack.pop()
        state[u] = 2
        return None

    for n in list(graph):
        if state.get(n, 0) == 0:
            c = dfs(n)
            if c:
                return c
    return None


def serial_order(edges, nodes):
    """Topological order of the precedence graph (an equivalent serial schedule) or None if cyclic."""
    indeg = {n: 0 for n in nodes}
    for _, b in edges:
        indeg[b] += 1
    order, ready = [], sorted(n for n in nodes if indeg[n] == 0)
    while ready:
        n = ready.pop(0)
        order.append(n)
        for a, b in edges:
            if a == n:
                indeg[b] -= 1
                if indeg[b] == 0:
                    ready.append(b)
    return order if len(order) == len(nodes) else None


def analyse(title, schedule):
    nodes = sorted({t for t, _, _ in schedule})
    edges = precedence_graph(schedule)
    cyc = find_cycle(edges)
    lines = [f"Schedule: {title}", "  " + " ".join(f"{o}{t[1:]}({x})" for t, o, x in schedule),
             "  precedence edges: " + (", ".join(f"{a} -> {b}" for a, b in edges) or "none")]
    if cyc:
        lines.append("  cycle found: " + " -> ".join(cyc) + "  => NOT conflict serializable")
    else:
        lines.append(f"  no cycle => conflict serializable, equivalent serial order: {' , '.join(serial_order(edges, nodes))}")
    return "\n".join(lines)


def wait_for_graph(waits):
    """waits = [("T1","T2"), ...] meaning T1 waits for T2. Returns text with the cycle (deadlock) if any."""
    cyc = find_cycle(waits)
    txt = "wait-for edges: " + ", ".join(f"{a} -> {b}" for a, b in waits)
    return txt + ("\n  cycle: " + " -> ".join(cyc) + "  => DEADLOCK" if cyc else "\n  no cycle => no deadlock")
