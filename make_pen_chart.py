# -*- coding: utf-8 -*-
"""Fügt dem Pen-Dokument einen neuen Frame 'AA Intelligence Index — Top 20' hinzu.
Baut auf einer Kopie im Workspace und spielt sie danach ein (Original-Backup vorher)."""
import json, random, string, shutil, sys

SRC = "/Users/clausmedvesek/.pencil/documents/b37045f0-66cd-4571-8bad-5dcef41893d6/pencil-new.pen"
WS_COPY = "/Users/clausmedvesek/Developer/projects/food-pal/pen-doc/pencil-new.pen"
BACKUP = "/Users/clausmedvesek/Developer/projects/food-pal/pen-doc/pencil-new.pen.orig-backup"

DATA = [
    ("Claude Fable 5.1 (max with fallback)", 53.3737509623252, "Anthropic", "#CC785C"),
    ("GPT-6 Astra (max)", 52.814069395513, "OpenAI", "#1F1F1F"),
    ("Claude Opus 5 (max)", 50.7001865797629, "Anthropic", "#CC785C"),
    ("Claude Fable 5 (with fallback)", 49.6994452733378, "Anthropic", "#CC785C"),
    ("Muse Spark 1.3 (max)", 48.1690107719685, "Muse", "#0089F4"),
    ("GPT-5.6 Sol (max)", 47.0613568915036, "OpenAI", "#1F1F1F"),
    ("GLM-5.3 (max)", 44.855717385614, "Zhipu", "#1C7FF8"),
    ("Grok 4.6 (high)", 44.4050073012592, "xAI", "#736CD3"),
    ("Kimi K3 (max)", 43.7841729518782, "Moonshot AI", "#047AFE"),
    ("GPT-5.6 Terra (max)", 42.2514998239494, "OpenAI", "#1F1F1F"),
    ("GLM-5.3-Flash", 41.907366113455, "Zhipu", "#1C7FF8"),
    ("Gemini 3.8 Flash (high)", 41.1863571765904, "Google", "#34A853"),
    ("Qwen3.8 2.4T A95B", 40.0445723105325, "Alibaba", "#FF7018"),
    ("DeepSeek V4.1 Flash (max)", 39.545442472527, "DeepSeek", "#2243E6"),
    ("GPT-5.6 Luna (max)", 37.5048489690841, "OpenAI", "#1F1F1F"),
    ("DeepSeek V4 Pro 0813 (max)", 36.2828791278402, "DeepSeek", "#2243E6"),
    ("Qwen3.8 27B (xhigh)", 33.9015108057476, "Alibaba", "#FF7018"),
    ("K2 Horizon 375B A23B", 30.7949302696723, "Moonshot AI", "#047AFE"),
    ("MiniMax-M3", 29.6125932236316, "MiniMax", "#EB3568"),
    ("Inkling", 25.5423060999384, "Inkling", "#7F4BF3"),
]
PROVIDERS = [
    ("Anthropic", "#CC785C"), ("OpenAI", "#1F1F1F"), ("Muse", "#0089F4"),
    ("Zhipu", "#1C7FF8"), ("xAI", "#736CD3"), ("Moonshot AI", "#047AFE"),
    ("Google", "#34A853"), ("Alibaba", "#FF7018"), ("DeepSeek", "#2243E6"),
    ("MiniMax", "#EB3568"), ("Inkling", "#7F4BF3"),
]

doc = json.load(open(SRC))
existing_ids = set()
def collect_ids(node):
    if isinstance(node, dict):
        if "id" in node:
            existing_ids.add(node["id"])
        for v in node.values():
            collect_ids(v)
    elif isinstance(node, list):
        for v in node:
            collect_ids(v)
collect_ids(doc)

def uid():
    while True:
        i = "".join(random.choice(string.ascii_letters + string.digits) for _ in range(5))
        if i not in existing_ids:
            existing_ids.add(i)
            return i

def rect(x, y, w, h, fill, name, corner=None):
    d = {"type": "rectangle", "id": uid(), "x": round(x, 2), "y": round(y, 2),
         "name": name, "fill": fill, "width": round(w, 2), "height": round(h, 2)}
    if corner:
        d["cornerRadius"] = corner
    return d

def text(x, y, content, size, fill, name, weight="normal", w=None, h=None,
         align=None, valign=None):
    d = {"type": "text", "id": uid(), "x": round(x, 2), "y": round(y, 2),
         "name": name, "fill": fill, "content": content,
         "fontFamily": "Inter", "fontSize": size, "fontWeight": weight}
    if w is not None:
        d["width"] = round(w, 2)
        d["height"] = round(h, 2)
        d["textGrowth"] = "fixed-width-height"
        if align:
            d["textAlign"] = align
        if valign:
            d["textAlignVertical"] = valign
    return d

CHART_TOP, BAR_X, SCALE, BAR_H, PITCH = 240, 336, 13, 26, 40
CHART_BOTTOM = CHART_TOP + 19 * PITCH + BAR_H  # 1026
W, H = 1280, 1240

kids = []
# Header
kids.append(rect(56, 44, 246, 28, "#F1EAFD", "Updated Badge", corner=14))
kids.append(text(56, 44, "UPDATED · 14 SEP 2026", 12, "#7F4BF3", "Badge Label",
                 weight="600", w=246, h=28, align="center", valign="middle"))
kids.append(text(56, 90, "Artificial Analysis Intelligence Index", 30, "#161616",
                 "Title", weight="700"))
kids.append(text(56, 138, "Intelligence Index v4.3 incorporates 10 evaluations: AA-Briefcase, GDPval-AA v2, AutomationBench-AA,", 14, "#555555", "Subtitle 1"))
kids.append(text(56, 158, "Terminal-Bench v4.0, SciCode, Humanity's Last Exam, GDP.pdf, CritPt, AA-Omniscience, AA-LCR v1.1", 14, "#555555", "Subtitle 2"))
kids.append(text(56, 196, "Intelligence evaluations measured independently by Artificial Analysis · Higher is better", 12, "#7A7A7A", "Caption"))

# Gridlines + axis
for v in range(0, 61, 10):
    x = BAR_X + v * SCALE
    kids.append(rect(x, 228, 1, CHART_BOTTOM - 224,
                     "#C9C9C9" if v == 0 else "#ECECEC", f"Gridline {v}"))
    kids.append(text(x - 15, CHART_BOTTOM + 10, str(v), 11, "#9A9A9A",
                     f"Axis {v}", w=30, h=16, align="center"))

# Rows
for i, (label, val, provider, color) in enumerate(DATA):
    y = CHART_TOP + i * PITCH
    bw = val * SCALE
    kids.append(text(32, y + 4, label, 13, "#333333", f"Label — {label}",
                     w=264, h=18, align="right", valign="middle"))
    kids.append(rect(BAR_X, y, bw, BAR_H, color, f"Bar — {label}", corner=3))
    kids.append(text(BAR_X + bw + 8, y + 4, f"{val:.1f}", 13, "#161616",
                     f"Value — {label}", weight="600"))

# Legend
kids.append(text(56, 1060, "Bar color = model provider", 12, "#555555",
                 "Legend Title", weight="600"))
for i, (name, color) in enumerate(PROVIDERS):
    col, row = i % 6, i // 6
    x, y = 56 + col * 190, 1086 + row * 30
    kids.append(rect(x, y + 3, 10, 10, color, f"Legend Dot — {name}", corner=2))
    kids.append(text(x + 18, y, name, 12, "#444444", f"Legend — {name}"))

# Footer
kids.append(text(56, H - 40,
                 "Source: artificialanalysis.ai/models · Retrieved 14 Sep 2026 · Top 20 models by Intelligence Index v4.3 · "
                 "Provider colors approximated from brand palette — fully editable.",
                 11, "#9A9A9A", "Source Note"))

frame = {
    "type": "frame", "id": uid(), "x": 1376, "y": 478,
    "name": "AA Intelligence Index — Top 20 (vectorized)",
    "clip": True, "width": W, "height": H,
    "fill": "#FFFFFF", "cornerRadius": 8,
    "stroke": "#E5E5E5", "strokeWidth": 1,
    "layout": "none",
    "children": kids,
}

doc["children"].append(frame)

with open(WS_COPY, "w", encoding="utf-8") as f:
    json.dump(doc, f, ensure_ascii=False, indent=2)

# Backup des Originals (einmalig)
try:
    shutil.copy2(SRC, BACKUP)
    print("Backup erstellt:", BACKUP)
except Exception as e:
    print("Backup fehlgeschlagen:", e)

# Validierung
chk = json.load(open(WS_COPY))
ids = []
def cid(n):
    if isinstance(n, dict):
        if "id" in n: ids.append(n["id"])
        for v in n.values(): cid(v)
    elif isinstance(n, list):
        for v in n: cid(v)
cid(chk)
assert len(ids) == len(set(ids)), "ID-Kollision!"
new_frame = chk["children"][-1]
print("Neuer Frame:", new_frame["name"], "| Elemente:", len(new_frame["children"]),
      "| Gesamt-Top-Level-Frames:", len(chk["children"]))
print("OK — Workspace-Kopie:", WS_COPY)
