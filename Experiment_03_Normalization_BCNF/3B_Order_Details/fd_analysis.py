"""3B - closures, keys, FD classification (full / partial / transitive), lossless join and dependency preservation."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from fd_tools import report, candidate_keys, prime_attributes, closure, fmt, S, norm

ATTRS = "OrderID,OrderDate,CustID,CustName,CustCity,ProductID,ProductName,Qty,UnitPrice"
FDS = [("OrderID", "OrderDate,CustID"),
       ("CustID", "CustName,CustCity"),
       ("ProductID", "ProductName,UnitPrice"),
       ("OrderID,ProductID", "Qty")]

report("3B: Order_Details", ATTRS, FDS, closures_of=["OrderID,ProductID", "OrderID", "ProductID", "CustID"])

print("--- Task 4: classification of every FD ---")
keys = candidate_keys(ATTRS, FDS)
prime = prime_attributes(ATTRS, FDS)
for l, r in norm(FDS):
    if closure(l, FDS) >= S(ATTRS):
        kind = "full (determinant is the key)"
    elif any(l < k for k in keys):
        kind = "PARTIAL (determinant is a proper part of the key)"
    else:
        kind = "TRANSITIVE (determinant is a non-key attribute)"
    print(f"  {fmt(l)} -> {fmt(r)} : {kind}")
print()

report("3B: 2NF  (Order_Header | Product | Order_Item)", ATTRS, FDS, analyse=False,
       decomposition=["OrderID,OrderDate,CustID,CustName,CustCity", "ProductID,ProductName,UnitPrice", "OrderID,ProductID,Qty"])
report("3B: 3NF = BCNF  (Customer | Orders | Product | Order_Item)", ATTRS, FDS, analyse=False,
       decomposition=["CustID,CustName,CustCity", "OrderID,OrderDate,CustID", "ProductID,ProductName,UnitPrice", "OrderID,ProductID,Qty"])
